import 'package:flutter/material.dart';

/// Kinds of account the user can create.
enum AccountType {
  cash('CASH', 'Cash', Icons.payments_outlined),
  bank('BANK', 'Bank', Icons.account_balance_outlined),
  upi('UPI', 'UPI / Wallet', Icons.qr_code_2_rounded),
  card('CARD', 'Credit card', Icons.credit_card_outlined),
  other('OTHER', 'Other', Icons.account_balance_wallet_outlined);

  const AccountType(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;

  static AccountType fromCode(String? code) {
    return AccountType.values.firstWhere(
      (t) => t.code == (code ?? '').toUpperCase(),
      orElse: () => AccountType.other,
    );
  }
}

class AccountModel {
  final int? id;
  final String name;
  final AccountType type;
  final double openingBalance;
  final bool isDefault;
  final String createdAt;

  const AccountModel({
    this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'account_type': type.code,
    'opening_balance': openingBalance,
    'is_default': isDefault ? 1 : 0,
    'created_at': createdAt,
  };

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
    id: map['id'] as int?,
    name: (map['name'] ?? '') as String,
    type: AccountType.fromCode(map['account_type'] as String?),
    openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
    isDefault: map['is_default'] == 1,
    createdAt: (map['created_at'] ?? '') as String,
  );
}

/// An account together with its calculated balance.
class AccountBalance {
  final AccountModel account;
  final double moneyIn;
  final double moneyOut;

  const AccountBalance({
    required this.account,
    required this.moneyIn,
    required this.moneyOut,
  });

  /// opening balance + everything that came in - everything that went out.
  double get balance => account.openingBalance + moneyIn - moneyOut;
}

class AccountTransferModel {
  final int? id;
  final int fromAccountId;
  final int toAccountId;
  final double amount;
  final String date;
  final String? notes;
  final String createdAt;

  const AccountTransferModel({
    this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'from_account_id': fromAccountId,
    'to_account_id': toAccountId,
    'amount': amount,
    'date': date,
    'notes': notes,
    'created_at': createdAt,
  };

  factory AccountTransferModel.fromMap(Map<String, dynamic> map) =>
      AccountTransferModel(
        id: map['id'] as int?,
        fromAccountId: map['from_account_id'] as int,
        toAccountId: map['to_account_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        date: (map['date'] ?? '') as String,
        notes: map['notes'] as String?,
        createdAt: (map['created_at'] ?? '') as String,
      );
}
