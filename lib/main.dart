import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/settings_provider.dart';

// Data Layer
import 'data/datasources/isar_datasource.dart';
import 'data/repositories/transaction_repository_impl.dart';

// Providers
import 'presentation/providers/transaction_provider.dart';
import 'presentation/providers/theme_provider.dart'; // Import ThemeProvider
import 'presentation/providers/wishlist_provider.dart'; // Import WishlistProvider

// UI
import 'presentation/pages/main_screen.dart';

void main() async {
  // Wajib dipanggil jika ada proses async (seperti buka database) sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Database Isar
  final isarDataSource = IsarDataSource();
  await isarDataSource.openDB();
  final repository = TransactionRepositoryImpl(isarDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(repository),
        ),
        // Mendaftarkan ThemeProvider agar dikenali seluruh aplikasi
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider(isarDataSource),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan status tema secara real-time
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Catat Cepat',
      debugShowCheckedModeBanner: false,

      // --- PENGATURAN TEMA TERANG (Light Mode) ---
      theme: ThemeData(
        brightness: Brightness.light, // Menandakan ini tema terang
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        fontFamily: 'Inter', // Tidak merah lagi
      ),

      // --- PENGATURAN TEMA GELAP (Dark Mode) ---
      darkTheme: ThemeData(
        brightness: Brightness.dark, // Menandakan ini tema gelap
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        fontFamily: 'Inter', // Tidak merah lagi
      ),

      // KUNCI UTAMA: Otomatis berubah sesuai state dari ThemeProvider
      themeMode: themeProvider.themeMode,

      home: const MainScreen(),
    );
  }
}