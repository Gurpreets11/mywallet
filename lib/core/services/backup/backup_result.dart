import 'dart:io';

class BackupResult {
  final bool success;
  final File? file;
  final String? message;
  final Exception? exception;

  const BackupResult({
    required this.success,
    this.file,
    this.message,
    this.exception,
  });
}
