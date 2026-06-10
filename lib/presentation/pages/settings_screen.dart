import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_drawer.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart'; // Import Settings Provider baru

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: true,
      ),
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Pengaturan Tema
          SwitchListTile(
            title: const Text('Mode Gelap (Dark Mode)'),
            subtitle: const Text('Ubah tema aplikasi ke mode gelap'),
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme(value);
            },
            secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            activeColor: Colors.green,
          ),
          const Divider(),

          // 2. Pengaturan Limit Pengeluaran Harian
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
            title: const Text('Batas Pengeluaran Harian'),
            subtitle: Text(
                settingsProvider.dailyLimit > 0
                    ? 'Limit: ${currencyFormat.format(settingsProvider.dailyLimit)}'
                    : 'Belum diatur (Tanpa Limit)'
            ),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () => _showLimitDialog(context, settingsProvider),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.green),
            title: const Text('Nama Profil Navigasi'),
            subtitle: Text(settingsProvider.profileName),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () => _showNameDialog(context, settingsProvider),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versi Aplikasi'),
            subtitle: Text('1.0.0 (Offline Mode)'),
          )
        ],
      ),
    );
  }

  // Dialog untuk memasukkan nominal limit
  void _showLimitDialog(BuildContext context, SettingsProvider provider) {
    final controller = TextEditingController(
        text: provider.dailyLimit > 0 ? provider.dailyLimit.toInt().toString() : ''
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur Limit Harian'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal Maksimal (Rp)',
            hintText: 'Misal: 50000',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                // Set limit ke 0 berarti mematikan fitur limit
                provider.setDailyLimit(0);
                Navigator.pop(ctx);
              },
              child: const Text('Matikan Limit', style: TextStyle(color: Colors.red))
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(controller.text) ?? 0;
              provider.setDailyLimit(limit);
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
  void _showNameDialog(BuildContext context, SettingsProvider provider) {
    final controller = TextEditingController(text: provider.profileName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Profil'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama Pengguna',
            hintText: 'Masukkan nama Anda',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')
          ),
          ElevatedButton(
            onPressed: () {
              provider.setProfileName(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}