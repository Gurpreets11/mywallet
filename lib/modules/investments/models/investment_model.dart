class InvestmentModel {
  final int? id;

  final String investmentType;

  final String investmentName;

  final String? investmentPlatform;

  final double investedAmount;

  final double currentValue;

  final double? quantity;

  final double? purchasePrice;

  final double? currentPrice;

  final String investmentDate;

  final String? maturityDate;

  final double? interestRate;

  final bool isSip;

  final double? sipAmount;

  final int? sipDate;

  final String? notes;

  final String createdAt;

  InvestmentModel({
    this.id,
    required this.investmentType,
    required this.investmentName,
    this.investmentPlatform,
    required this.investedAmount,
    required this.currentValue,
    this.quantity,
    this.purchasePrice,
    this.currentPrice,
    required this.investmentDate,
    this.maturityDate,
    this.interestRate,
    required this.isSip,
    this.sipAmount,
    this.sipDate,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'investment_type': investmentType,

      'investment_name': investmentName,

      'investment_platform': investmentPlatform,

      'invested_amount': investedAmount,

      'current_value': currentValue,

      'quantity': quantity,

      'purchase_price': purchasePrice,

      'current_price': currentPrice,

      'investment_date': investmentDate,

      'maturity_date': maturityDate,

      'interest_rate': interestRate,

      'is_sip': isSip ? 1 : 0,

      'sip_amount': sipAmount,

      'sip_date': sipDate,

      'notes': notes,

      'created_at': createdAt,
    };
  }

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'],

      investmentType: map['investment_type'],

      investmentName: map['investment_name'],

      investmentPlatform: map['investment_platform'],

      investedAmount: (map['invested_amount'] as num).toDouble(),

      currentValue: (map['current_value'] as num).toDouble(),

      quantity: (map['quantity'] as num?)?.toDouble(),

      purchasePrice: (map['purchase_price'] as num?)?.toDouble(),

      currentPrice: (map['current_price'] as num?)?.toDouble(),

      investmentDate: map['investment_date'],

      maturityDate: map['maturity_date'],

      interestRate: (map['interest_rate'] as num?)?.toDouble(),

      isSip: map['is_sip'] == 1,

      sipAmount: (map['sip_amount'] as num?)?.toDouble(),

      sipDate: map['sip_date'],

      notes: map['notes'],

      createdAt: map['created_at'],
    );
  }
}
