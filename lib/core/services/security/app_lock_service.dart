import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/app_database.dart';
import '../backup/backup_service.dart';
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
  static const Duration backgroundGracePeriod = Duration(seconds: 30);

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

  bool get isEnabled => _enabled;
  bool get isLocked => _locked;
  bool get isSuspended => _suspended;

  /// Remaining wait after too many wrong PINs (null = not locked out).
  Duration? get lockoutRemaining {
    final until = _lockedOutUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  /// Reads the saved lock state. Call once at start-up (and after a reset).
  Future<void> load() async {
    try {
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
        for (final r in rows) r['meta_key'] as String: r['meta_value'] as String,
      };
      _salt = values[BackupMetaKeys.appLockSalt];
      _hash = values[BackupMetaKeys.appLockHash];
      _enabled =
          values[BackupMetaKeys.appLockEnabled] == '1' &&
          _salt != null &&
          _hash != null;
    } catch (_) {
      _enabled = false;
    }
    _locked = _enabled; // cold start: locked whenever the lock is on
    _failedAttempts = 0;
    _lockedOutUntil = null;
    notifyListeners();
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
    _salt = salt;
    _hash = hash;
    _enabled = true;
    _locked = false; // the user has just proven access
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
      where: 'meta_key IN (?, ?, ?)',
      whereArgs: [
        BackupMetaKeys.appLockEnabled,
        BackupMetaKeys.appLockSalt,
        BackupMetaKeys.appLockHash,
      ],
    );
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
