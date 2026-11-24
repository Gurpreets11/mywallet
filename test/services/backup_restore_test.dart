import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/core/services/backup/auto_backup_service.dart';
import 'package:mywallet/core/services/backup/backup_model.dart';
import 'package:mywallet/core/services/backup/backup_service.dart';
import 'package:mywallet/core/services/backup/data_reset_service.dart';
import 'package:mywallet/core/services/backup/restore_service.dart';
import 'package:mywallet/core/services/settings/app_preferences.dart';
import 'package:mywallet/data/services/master_seed_service.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/repositories/expense_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  late Directory docs;

  setUpAll(() {
    docs = Directory.systemTemp.createTempSync('mywallet_docs_');
    // BackupService asks path_provider for the documents folder.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => docs.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    try {
      docs.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    final dir = Directory('${docs.path}/auto_backups');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<Database> db() => AppDatabase.database;

  Future<int> addExpense(double amount, {String notes = 'n'}) async {
    final cat = await CategoryRepository().addCategory(
      0,
      'Zz Bk ${DateTime.now().microsecondsSinceEpoch}',
    );
    return ExpenseRepository().insertExpense(
      ExpenseModel(
        amount: amount,
        categoryId: cat,
        categoryName: 'Test',
        date: DateTime.now().toIso8601String(),
        paymentMode: 'Cash',
        notes: notes,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> putMeta(String key, String value) async {
    final d = await db();
    await d.insert('app_metadata', {
      'meta_key': key,
      'meta_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMeta(String key) async {
    final d = await db();
    final rows = await d.query(
      'app_metadata',
      where: 'meta_key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['meta_value'] as String;
  }

  Future<int> count(String table) async {
    final d = await db();
    return Sqflite.firstIntValue(
      await d.rawQuery('SELECT COUNT(*) FROM $table'),
    )!;
  }

  File writeBackup(Map<String, dynamic> content, [String name = 'b.json']) {
    final f = File('${docs.path}/$name');
    f.writeAsStringSync(jsonEncode(content));
    return f;
  }

  group('BackupMetaKeys / BackupModel', () {
    test('device-local keys include the PIN and biometric settings', () {
      expect(BackupMetaKeys.deviceLocal, containsAll([
        'last_backup_at',
        'last_restore_at',
        'last_auto_backup_at',
        'app_lock_enabled',
        'app_lock_salt',
        'app_lock_hash',
        'app_lock_biometric',
      ]));
    });

    test('BackupModel JSON round trip', () {
      final m = BackupModel(
        backupVersion: 1,
        databaseVersion: 18,
        appVersion: '1.1.0',
        createdAt: '2026-11-10',
        tables: {'expenses': []},
      );
      final back = BackupModel.fromJson(m.toJson());
      expect(back.databaseVersion, 18);
      expect(back.tables.keys, ['expenses']);
    });
  });

  group('BackupService', () {
    test('record counts list every table', () async {
      await addExpense(10);
      final counts = await BackupService(await db()).getRecordCounts();
      expect(counts['expenses'], 1);
      expect(counts.keys, containsAll(['categories', 'incomes', 'loans']));
    });

    test('backup file is valid JSON with meta and data sections', () async {
      await addExpense(42, notes: 'saved');
      final file = await BackupService(await db()).createBackupFileInAppStorage();
      expect(file.existsSync(), isTrue);
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(map['meta']['app'], 'MyWallet');
      expect(map['meta']['dbVersion'], 18);
      expect((map['data']['expenses'] as List).single['notes'], 'saved');
      expect(map['meta']['counts']['expenses'], 1);
    });

    test('PIN and device-only keys never go into a backup', () async {
      await putMeta('app_lock_hash', 'SECRET');
      await putMeta('app_lock_salt', 'SALT');
      await putMeta('app_lock_biometric', '1');
      await putMeta('pref_currency', 'USD'); // preferences DO travel
      final file = await BackupService(await db()).createBackupFileInAppStorage();
      final text = file.readAsStringSync();
      expect(text, isNot(contains('SECRET')));
      expect(text, isNot(contains('app_lock_biometric')));
      expect(text, contains('pref_currency'));
    });

    test('safety backups are named by reason and described back', () async {
      final svc = BackupService(await db());
      final f = await svc.createSafetyBackup(reason: 'reset');
      final info = BackupService.describeSafetyBackup(f);
      expect(info.reason, 'reset');
      expect(info.time, isNotNull);
      expect(
        BackupService.describeSafetyBackup(File('/x/odd_name.json')).reason,
        'restore',
      );
      expect(await svc.listSafetyBackups(), hasLength(1));
    });

    test('only the 5 newest safety backups are kept', () async {
      final dir = Directory('${docs.path}/auto_backups')..createSync(recursive: true);
      for (var i = 1; i <= 6; i++) {
        File('${dir.path}/mywallet_before_restore_2020010${i}_000000.json')
            .writeAsStringSync('{}');
      }
      final svc = BackupService(await db());
      await svc.createSafetyBackup();
      final left = await svc.listSafetyBackups();
      expect(left, hasLength(5));
      // the oldest two original files were pruned
      expect(left.any((f) => f.path.contains('20200101_')), isFalse);
      expect(left.any((f) => f.path.contains('20200102_')), isFalse);
    });

    test('only the 7 newest automatic backups are kept and the time is stored',
        () async {
      final dir = Directory('${docs.path}/auto_backups')..createSync(recursive: true);
      for (var i = 1; i <= 8; i++) {
        File('${dir.path}/mywallet_auto_2020010${i}_000000.json')
            .writeAsStringSync('{}');
      }
      final svc = BackupService(await db());
      expect(await svc.getLastAutoBackupAt(), isNull);
      await svc.createAutoBackup();
      expect(await svc.listAutoBackups(), hasLength(7));
      expect(await svc.getLastAutoBackupAt(), isNotNull);
    });

    test('the private backup list is labelled and newest first', () async {
      final dir = Directory('${docs.path}/auto_backups')..createSync(recursive: true);
      File('${dir.path}/mywallet_auto_20240102_000000.json').writeAsStringSync('{}');
      File('${dir.path}/mywallet_before_reset_20240103_000000.json').writeAsStringSync('{}');
      File('${dir.path}/mywallet_before_import_20240101_000000.json').writeAsStringSync('{}');
      final all = await BackupService(await db()).listAllPrivateBackups();
      expect(all.map((e) => e.label), [
        'Before reset',
        'Automatic backup',
        'Before import',
      ]);
    });

    test('getLastBackupAt is null until a backup is marked', () async {
      final svc = BackupService(await db());
      expect(await svc.getLastBackupAt(), isNull);
      await putMeta('last_backup_at', DateTime(2026, 1, 2).toIso8601String());
      expect(await svc.getLastBackupAt(), DateTime(2026, 1, 2));
    });
  });

  group('RestoreService.parse / inspect', () {
    test('unreadable and non-JSON files give a friendly error', () async {
      final svc = RestoreService(await db());
      await expectLater(
        svc.parseBackupFile('${docs.path}/missing.json'),
        throwsA(isA<BackupFormatException>()),
      );
      final bad = File('${docs.path}/bad.json')..writeAsStringSync('not json');
      await expectLater(
        svc.parseBackupFile(bad.path),
        throwsA(isA<BackupFormatException>()),
      );
      final list = File('${docs.path}/list.json')..writeAsStringSync('[1,2]');
      await expectLater(
        svc.parseBackupFile(list.path),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('inspect rejects other apps, newer versions and damaged tables', () async {
      final svc = RestoreService(await db());
      Matcher bad() => throwsA(isA<BackupFormatException>());

      await expectLater(svc.inspectBackup({}), bad());
      await expectLater(
        svc.inspectBackup({'meta': {'app': 'Other'}, 'data': {'expenses': []}}),
        bad(),
      );
      await expectLater(
        svc.inspectBackup({'meta': {'dbVersion': 999}, 'data': {'expenses': []}}),
        bad(),
      );
      await expectLater(
        svc.inspectBackup({'data': {'expenses': 'oops'}}),
        bad(),
      );
      await expectLater(
        svc.inspectBackup({'data': {'expenses': [1, 2]}}),
        bad(),
      );
      await expectLater(
        svc.inspectBackup({'data': {'no_such_table': []}}),
        bad(),
      );
    });

    test('inspect reports counts, version and total', () async {
      final svc = RestoreService(await db());
      final info = await svc.inspectBackup({
        'meta': {
          'app': 'MyWallet',
          'exportedAt': '2026-11-10T10:00:00.000',
          'dbVersion': 18,
        },
        'data': {
          'expenses': [{'id': 1}, {'id': 2}],
          'loans': [],
          'ignored_table': [{'id': 1}],
        },
      });
      expect(info.dbVersion, 18);
      expect(info.exportedAt, DateTime(2026, 11, 10, 10));
      expect(info.counts['expenses'], 2);
      expect(info.counts.containsKey('ignored_table'), isFalse);
      expect(info.totalRecords, 2);
    });
  });

  group('RestoreService.restore', () {
    test('replace mode brings back the backed-up data and drops the rest', () async {
      final keepId = await addExpense(111, notes: 'keep');
      final file = await BackupService(await db()).createBackupFileInAppStorage();
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      await ExpenseRepository().deleteExpense(keepId);
      await addExpense(999, notes: 'added later');
      expect(await count('expenses'), 1);

      final restored = await RestoreService(await db()).restoreFromBackupMap(map);
      expect(restored, greaterThan(0));

      final all = await ExpenseRepository().getAllExpenses();
      expect(all.map((e) => e.notes), ['keep']);
      expect(await getMeta('last_restore_at'), isNotNull);
    });

    test('merge mode keeps what is already there', () async {
      await addExpense(1, notes: 'in backup');
      final file = await BackupService(await db()).createBackupFileInAppStorage();
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      await addExpense(2, notes: 'only on device');
      await RestoreService(await db()).restoreFromBackupMap(
        map,
        mode: RestoreMode.merge,
      );
      final notes = (await ExpenseRepository().getAllExpenses())
          .map((e) => e.notes)
          .toSet();
      expect(notes, {'in backup', 'only on device'});
    });

    test('the PIN settings on this device survive a replace restore', () async {
      await addExpense(1);
      final file = await BackupService(await db()).createBackupFileInAppStorage();
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      await putMeta('app_lock_hash', 'LOCAL_HASH');
      await putMeta('app_lock_enabled', '1');
      await RestoreService(await db()).restoreFromBackupMap(map);
      expect(await getMeta('app_lock_hash'), 'LOCAL_HASH');
      expect(await getMeta('app_lock_enabled'), '1');
    });

    test('device-local keys inside a backup file are ignored', () async {
      final map = {
        'meta': {'app': 'MyWallet'},
        'data': {
          'app_metadata': [
            {'meta_key': 'app_lock_hash', 'meta_value': 'EVIL'},
            {'meta_key': 'pref_currency', 'meta_value': 'USD'},
          ],
        },
      };
      await RestoreService(await db()).restoreFromBackupMap(
        map,
        mode: RestoreMode.merge,
      );
      expect(await getMeta('app_lock_hash'), isNull);
      expect(await getMeta('pref_currency'), 'USD');
    });

    test('unknown columns in backup rows are dropped', () async {
      final cat = await CategoryRepository().addCategory(0, 'Zz Cols');
      final map = {
        'meta': {'app': 'MyWallet'},
        'data': {
          'expenses': [
            {
              'id': 500,
              'amount': 5.0,
              'category_id': cat,
              'category_name': 'Zz Cols',
              'date': '2026-11-10T00:00:00.000',
              'payment_mode': 'Cash',
              'created_at': '2026-11-10T00:00:00.000',
              'column_from_the_future': 'x',
            },
          ],
        },
      };
      await RestoreService(await db()).restoreFromBackupMap(
        map,
        mode: RestoreMode.merge,
      );
      expect((await ExpenseRepository().getExpenseById(500))!.amount, 5.0);
    });
  });

  group('DataResetService', () {
    test('wipes data, re-seeds categories and keeps settings + PIN', () async {
      await addExpense(10);
      await putMeta('pref_currency', 'USD');
      await putMeta('app_lock_hash', 'H');

      await DataResetService(await db()).resetAllData();

      expect(await count('expenses'), 0);
      expect(await count('transaction_types'), 4);
      expect(await count('categories'), greaterThanOrEqualTo(11));
      expect(await getMeta('pref_currency'), 'USD');
      expect(await getMeta('app_lock_hash'), 'H');
    });

    test('removeAppLock also clears the PIN and biometric keys', () async {
      await putMeta('app_lock_enabled', '1');
      await putMeta('app_lock_salt', 'S');
      await putMeta('app_lock_hash', 'H');
      await putMeta('app_lock_biometric', '1');
      await DataResetService(await db()).resetAllData(removeAppLock: true);
      for (final k in [
        'app_lock_enabled',
        'app_lock_salt',
        'app_lock_hash',
        'app_lock_biometric',
      ]) {
        expect(await getMeta(k), isNull, reason: k);
      }
    });
  });

  group('AutoBackupService.runIfDue', () {
    final prefs = AppPreferences.instance;

    Future<int> autoFiles() async =>
        (await BackupService(await db()).listAutoBackups()).length;

    test('does nothing when switched off', () async {
      await prefs.load();
      await prefs.setAutoBackup(AutoBackupFrequency.off);
      await addExpense(1);
      await AutoBackupService.runIfDue();
      expect(await autoFiles(), 0);
    });

    test('does nothing while the app has no user data', () async {
      await prefs.load();
      await prefs.setAutoBackup(AutoBackupFrequency.daily);
      await MasterSeedService.seedMasterData();
      await AutoBackupService.runIfDue();
      expect(await autoFiles(), 0);
    });

    test('backs up once, then waits for the next due date', () async {
      await prefs.load();
      await prefs.setAutoBackup(AutoBackupFrequency.daily);
      await addExpense(1);
      await AutoBackupService.runIfDue();
      expect(await autoFiles(), 1);
      await AutoBackupService.runIfDue(); // not due yet
      expect(await autoFiles(), 1);
    });

    test('runs again when the last backup is older than the frequency', () async {
      await prefs.load();
      await prefs.setAutoBackup(AutoBackupFrequency.daily);
      await addExpense(1);
      await putMeta(
        'last_auto_backup_at',
        DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      );
      await AutoBackupService.runIfDue();
      expect(await autoFiles(), 1);
    });
  });
}
