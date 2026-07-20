import '../../database/database_constants.dart';

class BackupConstants {
  BackupConstants._();

  /// Backup File
  static const String backupFileName = 'my_wallet_backup.json';

  /// Backup Format Version
  static const int backupVersion = 1;

  /// JSON Keys
  static const String backupVersionKey = 'backupVersion';
  static const String databaseVersionKey = 'databaseVersion';
  static const String appVersionKey = 'appVersion';
  static const String createdAtKey = 'createdAt';
  static const String tablesKey = 'tables';

  /// Tables to include in Backup
  static const List<String> backupTables = [
    DatabaseConstants.tableTransactionTypes,
    DatabaseConstants.tableCategories,
    DatabaseConstants.tableSubcategories,
    DatabaseConstants.tableExpenses,
    DatabaseConstants.tableIncome,
    DatabaseConstants.tableInvestments,
    DatabaseConstants.tableLoans,
    DatabaseConstants.tableLoanPayments,
  ];
}
