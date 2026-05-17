// lib/data/repositories/transaction_repository_impl.dart
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/isar_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final IsarDataSource dataSource;

  TransactionRepositoryImpl(this.dataSource);

  @override
  Future<void> saveTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await dataSource.saveTransaction(model);
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await dataSource.deleteTransaction(id);
  }

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    final models = await dataSource.getAllTransactions();
    return models.map((model) => model.toEntity()).toList();
  }
}
