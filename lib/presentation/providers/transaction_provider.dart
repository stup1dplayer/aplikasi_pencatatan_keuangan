// lib/presentation/providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionRepository repository;

  List<TransactionEntity> _transactions = [];
  List<TransactionEntity> get transactions => _transactions;

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get netIncome => totalIncome - totalExpense;

  TransactionProvider(this.repository) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final results = await repository.getAllTransactions();
    // Sort descending by date
    results.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    _transactions = results;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    await repository.saveTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await repository.deleteTransaction(id);
    await loadTransactions();
  }

  Map<String, List<TransactionEntity>> get groupedTransactions {
    // Group transactions by date string (e.g. 'yyyy-MM-dd')
    Map<String, List<TransactionEntity>> grouped = {};
    for (var tx in _transactions) {
      String dateStr = _formatDate(tx.dateTime);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(tx);
    }
    return grouped;
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final txDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (txDate == today) {
      return 'Hari ini';
    } else if (txDate == yesterday) {
      return 'Kemarin';
    } else {
      return '${txDate.day.toString().padLeft(2, '0')}-${txDate.month.toString().padLeft(2, '0')}-${txDate.year}';
    }
  }
}
