import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/transaction_provider.dart';
import '../providers/wishlist_provider.dart';
import '../../domain/entities/transaction_entity.dart'; // Untuk membuat transaksi baru
import '../widgets/custom_drawer.dart';
import '../../domain/entities/wishlist_entity.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impianku (Wishlist)'),
        centerTitle: true,
      ),
      drawer: const CustomDrawer(),
      body: Consumer2<TransactionProvider, WishlistProvider>(
        builder: (context, txProvider, wlProvider, child) {
          // 1. Hitung total aset/saldo bersih yang dimiliki saat ini
          double totalAset = 0;
          final allTx = txProvider.groupedTransactions.values.expand((l) => l).toList();
          for (var tx in allTx) {
            if (tx.type == TransactionType.income) totalAset += tx.amount;
            else totalAset -= tx.amount;
          }

          final wishlists = wlProvider.wishlists;

          if (wishlists.isEmpty) {
            return const Center(child: Text('Belum ada wishlist. Tambahkan sekarang!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: wishlists.length,
            itemBuilder: (context, index) {
              final item = wishlists[index];

              // 2. Kalkulasi Progress Bar
              double progress = totalAset / item.price;
              if (progress > 1.0) progress = 1.0; // Mentok di 100%
              if (progress < 0.0) progress = 0.0; // Tidak boleh minus

              bool isAffordable = totalAset >= item.price;

              return GestureDetector(
                // Ketika kartu ditekan lama, munculkan dialog Edit/Hapus
                onLongPress: () => _showOptionsDialog(context, item),
                child: Card(
                  elevation: 2,
                  color: item.isAchieved ? Colors.green.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: item.isAchieved ? Colors.green : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              currencyFormat.format(item.price),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: item.isAchieved ? 1.0 : progress,
                                    backgroundColor: Colors.grey.shade200,
                                    color: item.isAchieved ? Colors.green : Colors.blue,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.isAchieved
                                        ? 'Barang Berhasil Dibeli!'
                                        : 'Terkumpul: ${currencyFormat.format(totalAset < 0 ? 0 : totalAset)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: item.isAchieved ? Colors.green : Colors.black54
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAffordable && !item.isAchieved)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: IconButton(
                                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  onPressed: () => _buyWishlist(context, item, wlProvider, txProvider),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // Tombol + di pojok kanan bawah
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showAddWishlistDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- FUNGSI UNTUK MEMBELI WISHLIST & MEMOTONG ASET ---
  void _buyWishlist(BuildContext context, WishlistEntity item, WishlistProvider wlProv, TransactionProvider txProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Beli Barang?'),
        content: Text('Uang di saldo utama akan dipotong sebesar Rp ${item.price.toInt()} untuk membeli ${item.name}. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);

              // 1. Ubah status wishlist jadi hijau (Achieved)
              await wlProv.markAsAchieved(item.id);

              // 2. Bikin transaksi pengeluaran otomatis agar aset berkurang
              final newExpense = TransactionEntity(
                type: TransactionType.expense,
                amount: item.price,
                description: 'Wishlist Terbeli: ${item.name}',
                account: AccountType.cash,
                dateTime: DateTime.now(),
              );

              await txProv.addTransaction(newExpense);
            },
            child: const Text('Ya, Beli!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, WishlistEntity item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Edit Wishlist'),
            onTap: () {
              Navigator.pop(ctx);
              _showAddWishlistDialog(context, existingItem: item); // Gunakan form yang sama untuk edit
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus Wishlist'),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, item);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WishlistEntity item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Wishlist?'),
        content: Text('Apakah kamu yakin ingin menghapus "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { // Perhatikan huruf 'P' besar
              Provider.of<WishlistProvider>(context, listen: false).deleteWishlist(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI UNTUK MUNCULIN FORM TAMBAH WISHLIST ---
  // Tambahkan parameter opsional 'existingItem'
  void _showAddWishlistDialog(BuildContext context, {WishlistEntity? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final priceController = TextEditingController(text: existingItem?.price.toInt().toString() ?? '');

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 24, left: 24, right: 24
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(existingItem == null ? 'Tambah Wishlist' : 'Edit Wishlist',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Barang'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Barang', prefixText: 'Rp '),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text;
                      final price = double.tryParse(priceController.text) ?? 0;
                      if (name.isNotEmpty && price > 0) {
                        final prov = Provider.of<WishlistProvider>(context, listen: false);

                        if (existingItem == null) {
                          prov.addWishlist(name, price);
                        } else {
                          prov.updateWishlist(existingItem.id, name, price);
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(existingItem == null ? 'Simpan' : 'Update'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
    );
  }
}