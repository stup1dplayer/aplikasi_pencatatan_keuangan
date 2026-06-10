// lib/data/models/transaction_model.dart
import 'package:isar/isar.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart'; // Isar generated file

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  @enumerated
  late TransactionType type;

  late double amount;

  late String description;

  @enumerated
  late AccountType account;

  late DateTime dateTime;

  // 1. TAMBAHKAN KOLOM TAGGING DI SINI
  @enumerated
  late TransactionTag tag;

  // Convert Model to Entity
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      type: type,
      amount: amount,
      description: description,
      account: account,
      dateTime: dateTime,
      tag: tag, // 2. TAMBAHKAN KE MAPPING ENTITAS
    );
  }

  // Create Model from Entity
  static TransactionModel fromEntity(TransactionEntity entity) {
    return TransactionModel()
      ..id = entity.id ?? Isar.autoIncrement
      ..type = entity.type
      ..amount = entity.amount
      ..description = entity.description
      ..account = entity.account
      ..dateTime = entity.dateTime
      ..tag = entity.tag;
  }
}