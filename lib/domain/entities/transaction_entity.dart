// lib/domain/entities/transaction_entity.dart
enum TransactionType { income, expense }
enum AccountType { cash, bank }
enum TransactionTag { none, primer, sekunder, tersier }

class TransactionEntity {
  final int? id;
  final TransactionType type;
  final double amount;
  final String description;
  final AccountType account;
  final DateTime dateTime;
  final TransactionTag tag;

  TransactionEntity({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.account,
    required this.dateTime,
    this.tag = TransactionTag.none,
  });

  TransactionEntity copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? description,
    AccountType? account,
    DateTime? dateTime,
    TransactionTag? tag,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      account: account ?? this.account,
      dateTime: dateTime ?? this.dateTime,
      tag: tag ?? this.tag,
    );
  }
}
