class BackupModel {
  final int backupVersion;
  final int databaseVersion;
  final String appVersion;
  final String createdAt;
  final Map<String, dynamic> tables;

  BackupModel({
    required this.backupVersion,
    required this.databaseVersion,
    required this.appVersion,
    required this.createdAt,
    required this.tables,
  });

  Map<String, dynamic> toJson() {
    return {
      "backupVersion": backupVersion,
      "databaseVersion": databaseVersion,
      "appVersion": appVersion,
      "createdAt": createdAt,
      "tables": tables,
    };
  }

  factory BackupModel.fromJson(Map<String, dynamic> json) {
    return BackupModel(
      backupVersion: json["backupVersion"],
      databaseVersion: json["databaseVersion"],
      appVersion: json["appVersion"],
      createdAt: json["createdAt"],
      tables: Map<String, dynamic>.from(json["tables"]),
    );
  }
}
