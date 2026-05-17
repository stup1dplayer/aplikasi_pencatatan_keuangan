import 'package:flutter/material.dart';
import 'package:isar/isar.dart'; // <-- INI BARIS YANG SEBELUMNYA KURANG

import '../../data/datasources/isar_datasource.dart';
import '../../domain/entities/wishlist_entity.dart';

class WishlistProvider with ChangeNotifier {
  final IsarDataSource _isarDataSource;
  List<WishlistEntity> _wishlists = [];

  WishlistProvider(this._isarDataSource) {
    loadWishlists();
  }

  List<WishlistEntity> get wishlists => _wishlists;

  Future<void> loadWishlists() async {
    final isar = await _isarDataSource.isar;
    _wishlists = await isar.wishlistEntitys.where().findAll();
    notifyListeners();
  }

  Future<void> addWishlist(String name, double price) async {
    final newWishlist = WishlistEntity()
      ..name = name
      ..price = price
      ..isAchieved = false;

    final isar = await _isarDataSource.isar;
    await isar.writeTxn(() async {
      await isar.wishlistEntitys.put(newWishlist);
    });

    await loadWishlists();
  }

  Future<void> markAsAchieved(int id) async {
    final isar = await _isarDataSource.isar;
    final wishlist = await isar.wishlistEntitys.get(id);

    if (wishlist != null) {
      wishlist.isAchieved = true;
      await isar.writeTxn(() async {
        await isar.wishlistEntitys.put(wishlist);
      });
      await loadWishlists();
    }
  }
  // Fungsi untuk mengupdate Nama dan Harga Wishlist
  Future<void> updateWishlist(int id, String newName, double newPrice) async {
    final isar = await _isarDataSource.isar;
    final wishlist = await isar.wishlistEntitys.get(id);

    if (wishlist != null) {
      wishlist.name = newName;
      wishlist.price = newPrice;

      await isar.writeTxn(() async {
        await isar.wishlistEntitys.put(wishlist);
      });
      await loadWishlists();
    }
  }
  // untuk delete
  Future<void> deleteWishlist(int id) async {
    final isar = await _isarDataSource.isar;
    await isar.writeTxn(() async {
      await isar.wishlistEntitys.delete(id);
    });
    await loadWishlists();
  }
}