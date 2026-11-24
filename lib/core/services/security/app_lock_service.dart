import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/app_database.dart';
import '../backup/backup_service.dart';
import '../settings/app_preferences.dart';
import 'sha256_lite.dart';

/// PIN-based app lock.
///
/// The PIN is never stored: only a random salt and an iterated SHA-256 hash
/// are kept in `app_metadata`. Those keys are device-local, so they are never
/// written into backup files and never overwritten by a restore.
class AppLockService extends ChangeNotifier {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  static const int pinLength = 4;

  /// How long the app may stay in the background before it locks again.
  /// (Long enough for system file pickers used by backup / restore / export.)
  /// Chosen in Settings > Security (default 30 seconds).
  static Duration get backgroundGracePeriod =>
      Duration(seconds: AppPreferences.instance.lockDelaySeconds);

  static const int _hashRounds = 2000;
  static const int _maxFreeAttempts = 5;
  static const String _table = 'app_metadata';

  bool _enabled = false;
  bool _locked = false;
  String? _salt;
  String? _hash;
  int _failedAttempts = 0;
  DateTime? _lockedOutUntil;
  bool _suspended = false;
  bool _biometric = false;

  bool get isEnabled => _enabled;
  bool get isLocked => _locked;
  bool get isSuspended => _suspended;

  /// Fingerprint / face unlock as a shortcut next to the PIN.
  bool get isBiometricEnabled => _enabled && _biometric;

  /// Remaining wait after too many wrong PINs (null = not locked out).
  Duration? get lockoutRemaining {
    final until = _lockedOutUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  bool _loaded = false;

  /// True once the saved lock state has been read from the database.
  bool get isLoaded => _loaded;

  Future<({bool enabled, String? salt, String? hash})> _readStored() async {
    final Database db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'meta_key IN (?, ?, ?)',
      whereArgs: [
        BackupMetaKeys.appLockEnabled,
        BackupMetaKeys.appLockSalt,
        BackupMetaKeys.appLockHash,
      ],
    );
    final values = {
      for (final r in rows)
        r['meta_key'].toString(): r['meta_value'].toString(),
    };
    final salt = values[BackupMetaKeys.appLockSalt];
    final hash = values[BackupMetaKeys.appLockHash];
    final enabled =
        values[BackupMetaKeys.appLockEnabled] == '1' &&
        salt != null &&
        hash != null;
    return (enabled: enabled, salt: salt, hash: hash);
  }

  /// Reads the saved lock state. Call once at start-up (and after a reset).
  Future<void> load() async {
    try {
      final stored = await _readStored();
      _salt = stored.salt;
      _hash = stored.hash;
      _enabled = stored.enabled;
      final db = await AppDatabase.database;
      final bio = await db.query(
        _table,
        where: 'meta_key = ?',
        whereArgs: [BackupMetaKeys.appLockBiometric],
        limit: 1,
      );
      _biometric = bio.isNotEmpty && bio.first['meta_value'] == '1';
      debugPrint('AppLock: loaded, enabled=$_enabled');
    } catch (e, st) {
      // Do not hide this: a failing read means the lock silently turns off.
      debugPrint('AppLock: LOAD FAILED -> lock is OFF. $e\n$st');
      _enabled = false;
    }
    _loaded = true;
    _locked = _enabled; // cold start: locked whenever the lock is on
    _failedAttempts = 0;
    _lockedOutUntil = null;
    notifyListeners();
  }

  /// Loads the lock state if nothing loaded it yet (safety net for the gate).
  Future<void> ensureLoaded() async {
    if (!_loaded) await load();
  }

  Future<void> _put(String key, String value) async {
    final Database db = await AppDatabase.database;
    await db.insert(_table, {
      'meta_key': key,
      'meta_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  String _randomSalt() {
    final rnd = Random.secure();
    return toHex(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  String _hashPin(String pin, String salt) {
    final saltBytes = utf8.encode(salt);
    var digest = sha256Bytes([...saltBytes, ...utf8.encode(pin)]);
    for (var i = 0; i < _hashRounds; i++) {
      digest = sha256Bytes([...digest, ...saltBytes]);
    }
    return toHex(digest);
  }

  /// Turns the lock on with a new PIN (also used to change the PIN).
  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    final hash = _hashPin(pin, salt);
    await _put(BackupMetaKeys.appLockSalt, salt);
    await _put(BackupMetaKeys.appLockHash, hash);
    await _put(BackupMetaKeys.appLockEnabled, '1');

    // Read it back: if the PIN did not reach the database, fail loudly now
    // instead of silently losing the lock at the next app start.
    final stored = await _readStored();
    if (!stored.enabled || stored.hash != hash) {
      throw StateError('The PIN could not be saved. Please try again.');
    }

    _loaded = true;
    _salt = salt;
    _hash = hash;
    _enabled = true;
    _locked = false; // the user has just proven access
    _failedAttempts = 0;
    _lockedOutUntil = null;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _put(BackupMetaKeys.appLockBiometric, value ? '1' : '0');
    _biometric = value;
    notifyListeners();
  }

  /// Unlocks without a PIN after the system biometric prompt succeeded.
  void unlockWithBiometric() {
    if (!isBiometricEnabled || !_locked) return;
    _locked = false;
    _failedAttempts = 0;
    _lockedOutUntil = null;
    notifyListeners();
  }

  /// Checks [pin] without changing the lock state. Counts wrong attempts and
  /// imposes a growing wait after 5 failures.
  bool checkPin(String pin) {
    if (lockoutRemaining != null) return false;
    final salt = _salt;
    final hash = _hash;
    if (salt == null || hash == null) return false;

    final candidate = _hashPin(pin, salt);
    var diff = candidate.length ^ hash.length;
    for (var i = 0; i < candidate.length && i < hash.length; i++) {
      diff |= candidate.codeUnitAt(i) ^ hash.codeUnitAt(i);
    }
    if (diff == 0) {
      _failedAttempts = 0;
      _lockedOutUntil = null;
      return true;
    }

    _failedAttempts++;
    if (_failedAttempts >= _maxFreeAttempts) {
      final steps = _failedAttempts - _maxFreeAttempts; // 0,1,2,...
      final seconds = min(30 * pow(2, steps).toInt(), 600);
      _lockedOutUntil = DateTime.now().add(Duration(seconds: seconds));
    }
    return false;
  }

  /// Unlocks the app if [pin] is correct.
  bool unlock(String pin) {
    if (!checkPin(pin)) return false;
    _locked = false;
    notifyListeners();
    return true;
  }

  /// Locks the screen now (no-op when the lock is off).
  void lockNow() {
    if (!_enabled || _locked) return;
    _locked = true;
    notifyListeners();
  }

  /// Removes the lock and the stored PIN data.
  Future<void> disable() async {
    final Database db = await AppDatabase.database;
    await db.delete(
      _table,
      where: 'meta_key IN (?, ?, ?, ?)',
      whereArgs: [
        BackupMetaKeys.appLockEnabled,
        BackupMetaKeys.appLockSalt,
        BackupMetaKeys.appLockHash,
        BackupMetaKeys.appLockBiometric,
      ],
    );
    _biometric = false;
    _enabled = false;
    _locked = false;
    _salt = null;
    _hash = null;
    _failedAttempts = 0;
    _lockedOutUntil = null;
    notifyListeners();
  }

  /// Runs [action] (e.g. a system file picker) without the app locking itself
  /// when the app goes to the background during it.
  Future<T> runWithoutLock<T>(Future<T> Function() action) async {
    _suspended = true;
    try {
      return await action();
    } finally {
      _suspended = false;
    }
  }
}
