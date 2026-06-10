import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Import semua halaman yang dibutuhkan untuk navigasi
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../pages/wishlist_screen.dart';
import '../pages/history_screen.dart';   // <-- Pastikan import ini ada
import '../pages/report_screen.dart';    // <-- Pastikan import ini ada
import '../pages/settings_screen.dart';  // <-- Pastikan import ini ada
import '../../domain/entities/transaction_entity.dart'; // <-- TAMBAHKAN BARIS INI

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Consumer<TransactionProvider>(
              builder: (context, txProvider, child) {
                // Hitung Aset Bersih
                double totalAset = 0;
                final allTx = txProvider.groupedTransactions.values.expand((l) => l);
                for (var tx in allTx) {
                  if (tx.type == TransactionType.income) totalAset += tx.amount;
                  else totalAset -= tx.amount;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      child: Icon(Icons.person, size: 35, color: Colors.blue),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      settingsProvider.profileName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aset Bersih: ${currencyFormat.format(totalAset)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ),

          // 1. MENU BERANDA
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () {
              // Menghapus semua tumpukan halaman dan kembali ke MainScreen (Akar)
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),

          // 2. MENU WISHLIST
          ListTile(
            leading: const Icon(Icons.stars),
            title: const Text('Impianku (Wishlist)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistScreen()),
              );
            },
          ),

          // 3. MENU SEMUA CATATAN (HISTORY) - Diperbarui ke MaterialPageRoute
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Semua Catatan'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),

          // 4. MENU LAPORAN - Diperbarui ke MaterialPageRoute
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Laporan'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportScreen()),
              );
            },
          ),

          // 5. MENU PENGATURAN - Diperbarui ke MaterialPageRoute
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}