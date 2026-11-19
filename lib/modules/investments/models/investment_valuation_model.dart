/// One recorded value of an investment on a date.
class InvestmentValuation {
  final int? id;
  final int investmentId;
  final double value;

  /// ISO-8601 date (yyyy-MM-dd or full timestamp).
  final String date;
  final String? notes;
  final String createdAt;

  const InvestmentValuation({
    this.id,
    required this.investmentId,
    required this.value,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  DateTime get day {
    final d = DateTime.tryParse(date) ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'investment_id': investmentId,
    'value': value,
    'date': date,
    'notes': notes,
    'created_at': createdAt,
  };

  factory InvestmentValuation.fromMap(Map<String, dynamic> map) {
    return InvestmentValuation(
      id: map['id'] as int?,
      investmentId: map['investment_id'] as int,
      value: (map['value'] as num).toDouble(),
      date: map['date'] as String,
      notes: map['notes'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }
}
