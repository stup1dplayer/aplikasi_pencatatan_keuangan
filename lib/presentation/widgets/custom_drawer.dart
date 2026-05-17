import 'package:flutter/material.dart';
import '../pages/main_screen.dart';
import '../pages/report_screen.dart';
import '../pages/history_screen.dart';
import '../pages/settings_screen.dart';
import '../pages/wishlist_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final cleanAssetStr = currencyFormatter.format(provider.netIncome);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('afkar', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text('Aset Bersih: $cleanAssetStr'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Catat Baru'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart),
            title: const Text('Laporan Keuangan'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Semua Catatan'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_rounded),
            title: const Text('Impianku (Wishlist)'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
