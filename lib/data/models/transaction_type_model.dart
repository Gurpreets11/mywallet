class TransactionTypeModel {
  final int? id;
  final String typeName;

  TransactionTypeModel({this.id, required this.typeName});

  Map<String, dynamic> toMap() {
    return {'id': id, 'type_name': typeName};
  }

  factory TransactionTypeModel.fromMap(Map<String, dynamic> map) {
    return TransactionTypeModel(id: map['id'], typeName: map['type_name']);
  }
}
