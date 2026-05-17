// lib/domain/repositories/transaction_repository.dart
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<void> saveTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(int id);
  Future<List<TransactionEntity>> getAllTransactions();
}
