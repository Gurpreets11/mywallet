import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/core/services/security/app_lock_service.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();
  final lock = AppLockService.instance;

  setUp(() async {
    await lock.disable();
  });

  test('starts with the lock off', () async {
    await lock.load();
    expect(lock.isEnabled, isFalse);
    expect(lock.isLocked, isFalse);
  });

  test('a PIN turns the lock on and only that PIN unlocks', () async {
    await lock.setPin('1234');
    expect(lock.isEnabled, isTrue);
    expect(lock.isLocked, isFalse); // just proved access

    lock.lockNow();
    expect(lock.isLocked, isTrue);
    expect(lock.unlock('0000'), isFalse);
    expect(lock.isLocked, isTrue);
    expect(lock.unlock('1234'), isTrue);
    expect(lock.isLocked, isFalse);
  });

  test('the PIN itself is never stored', () async {
    await lock.setPin('4821');
    final db = await AppDatabase.database;
    final rows = await db.query('app_metadata');
    for (final r in rows) {
      expect(r['meta_value'].toString(), isNot(contains('4821')));
    }
  });

  test('the lock state survives a reload (app restart)', () async {
    await lock.setPin('1357');
    await lock.load();
    expect(lock.isEnabled, isTrue);
    expect(lock.isLocked, isTrue); // cold start is locked
    expect(lock.unlock('1357'), isTrue);
  });

  test('five wrong PINs lock the user out, even for the right PIN', () async {
    await lock.setPin('2468');
    lock.lockNow();
    for (var i = 0; i < 5; i++) {
      expect(lock.unlock('9999'), isFalse);
    }
    expect(lock.lockoutRemaining, isNotNull);
    expect(lock.unlock('2468'), isFalse);
  });

  test('disable removes the lock', () async {
    await lock.setPin('1111');
    await lock.disable();
    expect(lock.isEnabled, isFalse);
    await lock.load();
    expect(lock.isEnabled, isFalse);
  });

  group('biometric shortcut', () {
    test('only works while the lock is on and enabled', () async {
      await lock.setPin('1212');
      expect(lock.isBiometricEnabled, isFalse);

      lock.lockNow();
      lock.unlockWithBiometric(); // not enabled -> stays locked
      expect(lock.isLocked, isTrue);

      await lock.setBiometricEnabled(true);
      expect(lock.isBiometricEnabled, isTrue);
      lock.unlockWithBiometric();
      expect(lock.isLocked, isFalse);
    });

    test('is remembered after a restart and removed with the lock', () async {
      await lock.setPin('3434');
      await lock.setBiometricEnabled(true);
      await lock.load();
      expect(lock.isBiometricEnabled, isTrue);

      await lock.disable();
      expect(lock.isBiometricEnabled, isFalse);
      await lock.load();
      expect(lock.isBiometricEnabled, isFalse);
    });
  });
}
