
import '../../../core/database/app_database.dart';
import '../models/recurring_transaction_model.dart';

class RecurringRepository {
  static const _table = 'recurring_transactions';
  static const _occurrences = 'recurring_occurrences';

  Future<List<RecurringTransactionModel>> getAll() async {
    final db = await AppDatabase.database;
    final rows = await db.query(_table, orderBy: "status ASC, next_due_date ASC");
    return rows.map(RecurringTransactionModel.fromMap).toList();
  }

  Future<int> insert(RecurringTransactionModel model) async {
    final db = await AppDatabase.database;
    final map = model.toMap()..remove('id');
    return db.insert(_table, map);
  }

  Future<int> update(RecurringTransactionModel model) async {
    final db = await AppDatabase.database;
    return db.update(
      _table,
      model.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> setStatus(int id, String status) async {
    final db = await AppDatabase.database;
    await db.update(_table, {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(_occurrences,
          where: 'recurring_transaction_id = ?', whereArgs: [id]);
      await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Creates due transactions once only. The unique occurrence key protects
  /// against duplicate generation after restarts or repeated screen visits.
  Future<int> generateDueTransactions({DateTime? now}) async {
    final db = await AppDatabase.database;
    //final today = _dateOnly(now ?? DateTime.now());
    /*final today = DateTime(
      (now ?? DateTime.now()).year,
      (now ?? DateTime.now()).month,
      (now ?? DateTime.now()).day,
    );*/
    final nowDate = now ?? DateTime.now();

    final today = DateTime(
      nowDate.year,
      nowDate.month,
      nowDate.day,
    );

    final todayString = _dateOnly(today);
    var generated = 0;

    await db.transaction((txn) async {
      final schedules = await txn.query(
        _table,
        where: "status = 'ACTIVE' AND next_due_date <= ?",
        whereArgs: [todayString],
      );

      for (final row in schedules) {
        final schedule = RecurringTransactionModel.fromMap(row);
        var due = DateTime.parse(schedule.nextDueDate);
        final end = schedule.endDate == null
            ? null
            : DateTime.parse(schedule.endDate!);

        while (
        !due.isAfter(today) &&
            (end == null || !due.isAfter(end))
        ) {
          final occurrenceDate = _dateOnly(due);
          final alreadyGenerated = await txn.query(
            _occurrences,
            columns: ['id'],
            where: 'recurring_transaction_id = ? AND occurrence_date = ?',
            whereArgs: [schedule.id, occurrenceDate],
            limit: 1,
          );

          if (alreadyGenerated.isEmpty) {
            final transactionId = schedule.transactionType == 'EXPENSE'
                ? await txn.insert('expenses', {
                    'amount': schedule.amount,
                    'category_id': schedule.categoryId,
                    'subcategory_id': null,
                    'category_name': schedule.categoryName,
                    'subcategory_name': null,
                    'date': occurrenceDate,
                    'payment_mode': schedule.paymentMode,
                    'notes': _generatedNote(schedule),
                    'created_at': DateTime.now().toIso8601String(),
                  })
                : await txn.insert('incomes', {
                    'amount': schedule.amount,
                    'category_id': schedule.categoryId,
                    'subcategory_id': null,
                    'date': occurrenceDate,
                    'payment_mode': schedule.paymentMode,
                    'notes': _generatedNote(schedule),
                    'is_recurring': 1,
                    'recurring_type': schedule.frequency,
                    'created_at': DateTime.now().toIso8601String(),
                  });

            await txn.insert(_occurrences, {
              'recurring_transaction_id': schedule.id,
              'occurrence_date': occurrenceDate,
              'transaction_type': schedule.transactionType,
              'generated_transaction_id': transactionId,
              'created_at': DateTime.now().toIso8601String(),
            });
            generated++;
          }

          due = _nextDate(due, schedule.frequency, schedule.intervalValue);
        }

        final newStatus = end != null && due.isAfter(end) ? 'COMPLETED' : 'ACTIVE';
        await txn.update(
          _table,
          {'next_due_date': _dateOnly(due), 'status': newStatus},
          where: 'id = ?',
          whereArgs: [schedule.id],
        );
      }
    });

    return generated;
  }

  Future<int> occurrenceCount(int scheduleId) async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_occurrences WHERE recurring_transaction_id = ?',
      [scheduleId],
    );
    return (result.first['total'] as num).toInt();
  }

  static String _generatedNote(RecurringTransactionModel model) {
    final note = (model.notes ?? '').trim();
    return note.isEmpty ? 'Recurring: ${model.title}' : 'Recurring: ${model.title} - $note';
  }

  static String _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String().substring(0, 10);

  static DateTime _nextDate(DateTime date, String frequency, int interval) {
    switch (frequency) {
      case 'DAILY':
        return date.add(Duration(days: interval));
      case 'WEEKLY':
        return date.add(Duration(days: 7 * interval));
      case 'YEARLY':
        return DateTime(date.year + interval, date.month,
            _safeDay(date.year + interval, date.month, date.day));
      case 'MONTHLY':
      default:
        final monthIndex = date.month - 1 + interval;
        final year = date.year + monthIndex ~/ 12;
        final month = monthIndex % 12 + 1;
        return DateTime(year, month, _safeDay(year, month, date.day));
    }
  }

  static int _safeDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day > lastDay ? lastDay : day;
  }
}
