// lib/data/datasources/isar_datasource.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
// WAJIB: Import file entitas wishlist agar skemanya terbaca
import '../../domain/entities/wishlist_entity.dart';

class IsarDataSource {
  late Future<Isar> db;

  // Jembatan agar file provider lain (seperti WishlistProvider) bisa mengambil databasenya
  Future<Isar> get isar => db;

  IsarDataSource() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [
          TransactionModelSchema,
          WishlistEntitySchema, // <-- DAFTARKAN TABEL WISHLIST DI SINI
        ],
        directory: dir.path,
      );
    }
    return Future.value(Isar.getInstance());
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.transactionModels.put(transaction);
    });
  }

  Future<void> deleteTransaction(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.transactionModels.delete(id);
    });
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final isar = await db;
    return await isar.transactionModels.where().findAll();
  }
}