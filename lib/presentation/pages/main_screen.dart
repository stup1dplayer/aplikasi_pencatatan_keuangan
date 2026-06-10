import 'package:aplikasi_pencatatan_harian/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/category_predictor.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_provider.dart';
import '../widgets/custom_drawer.dart';
import '../theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  AccountType _selectedAccount = AccountType.cash;

  // Variabel untuk menampung pilihan tag pengeluaran
  TransactionTag _selectedTag = TransactionTag.none;
  // Fungsi yang dipanggil setiap kali teks deskripsi berubah
  void _onDescriptionChanged(String text) {
    // Hanya menebak jika sedang mencatat pengeluaran
    if (_selectedType == TransactionType.expense) {
      final predictedTag = CategoryPredictor.predict(text);

      // Jika AI menemukan kecocokan, ubah state bubble-nya
      if (predictedTag != TransactionTag.none && _selectedTag != predictedTag) {
        setState(() {
          _selectedTag = predictedTag;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final amountTxt = _amountController.text.replaceAll('.', '').replaceAll(',', '');
      final amount = double.tryParse(amountTxt) ?? 0.0;

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominal harus lebih dari 0')),
        );
        return;
      }

      final entity = TransactionEntity(
        type: _selectedType,
        amount: amount,
        description: _descController.text,
        account: _selectedAccount,
        dateTime: DateTime.now(),
        tag: _selectedType == TransactionType.expense ? _selectedTag : TransactionTag.none,
      );

      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      await txProvider.addTransaction(entity);

      if (mounted) {
        // --- 1. LOGIKA CEK LIMIT HARIAN (Jika ada) ---
        String warningMsg = '';
        Color warningColor = Colors.green;
        bool hasWarning = false;

        if (_selectedType == TransactionType.expense) {
          final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
          final limit = settingsProv.dailyLimit;

          if (limit > 0) {
            double todayExpense = 0;
            final now = DateTime.now();
            final allTx = txProvider.groupedTransactions.values.expand((l) => l);

            for (var tx in allTx) {
              if (tx.type == TransactionType.expense &&
                  tx.dateTime.day == now.day &&
                  tx.dateTime.month == now.month &&
                  tx.dateTime.year == now.year) {
                todayExpense += tx.amount;
              }
            }

            double percentage = todayExpense / limit;
            if (percentage >= 1.0) {
              warningMsg = '🚨 AWAS: Batas pengeluaran harianmu HABIS (Sisa 0%)!';
              warningColor = Colors.red;
              hasWarning = true;
            } else if (percentage >= 0.95) {
              warningMsg = '⚠️ PERINGATAN: Sisa batas pengeluaran tinggal 5%!';
              warningColor = Colors.deepOrange;
              hasWarning = true;
            } else if (percentage >= 0.90) {
              warningMsg = '⚠️ HATI-HATI: Sisa batas pengeluaran tinggal 10%.';
              warningColor = Colors.orange;
              hasWarning = true;
            } else if (percentage >= 0.75) {
              warningMsg = 'ℹ️ INFO: Sisa batas pengeluaran tinggal 25%.';
              warningColor = Colors.blue;
              hasWarning = true;
            }
          }
        }

        // --- 2. POP UP BERHASIL DICATAT ---
        showDialog(
            context: context,
            barrierDismissible: false, // User wajib klik OK untuk menutup
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                      hasWarning ? Icons.warning_amber_rounded : Icons.check_circle,
                      color: hasWarning ? warningColor : Colors.green,
                      size: 28
                  ),
                  const SizedBox(width: 8),
                  const Text('Berhasil'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedType == TransactionType.expense
                      ? 'Catatan pengeluaran Anda berhasil disimpan!'
                      : 'Catatan pemasukan Anda berhasil disimpan!'),
                  if (hasWarning) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        warningMsg,
                        style: TextStyle(color: warningColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
        );

            // --- 3. RESET SEMUA KOLOM DAN STATE ---
            _amountController.clear();
        _descController.clear();
        setState(() {
          _selectedType = TransactionType.expense; // Reset kembali ke default Pengeluaran
          _selectedAccount = AccountType.cash;     // Reset ke Cash
          _selectedTag = TransactionTag.none;       // Reset bubble kategori
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Cepat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          )
        ],
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selection
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == TransactionType.income ? AppColors.incomeGreen : Colors.grey[300],
                        foregroundColor: _selectedType == TransactionType.income ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedType = TransactionType.income;
                          // Tag tidak diperlukan untuk pemasukan
                          _selectedTag = TransactionTag.none;
                          if (_descController.text.isEmpty) {
                            _descController.text = 'ojol';
                          }
                        });
                      },
                      child: const Text('PEMASUKAN'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == TransactionType.expense ? AppColors.expenseRed : Colors.grey[300],
                        foregroundColor: _selectedType == TransactionType.expense ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedType = TransactionType.expense;
                        });
                      },
                      child: const Text('PENGELUARAN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Nominal tidak boleh kosong';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onDescriptionChanged,
              ),
              const SizedBox(height: 16),

              // Account Source Dropdown
              DropdownButtonFormField<AccountType>(
                initialValue: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'Sumber Dana',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type == AccountType.cash ? 'Cash' : 'Bank'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAccount = val);
                },
              ),
              const SizedBox(height: 16),

              // --- BUBBLE TAGGING (Hanya muncul jika PENGELUARAN) ---
              if (_selectedType == TransactionType.expense) ...[
                const Text(
                  'Kategori Pengeluaran (Opsional):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTagBubble('Primer', TransactionTag.primer, Colors.redAccent),
                    const SizedBox(width: 8),
                    _buildTagBubble('Sekunder', TransactionTag.sekunder, Colors.orangeAccent),
                    const SizedBox(width: 8),
                    _buildTagBubble('Tersier', TransactionTag.tersier, Colors.lightBlueAccent),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Date Input (Readonly)
              TextFormField(
                enabled: false,
                initialValue: DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.incomeGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saveTransaction,
                child: const Text('SIMPAN CATATAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BANTUAN UNTUK BUBBLE TAGGING ---
  Widget _buildTagBubble(String label, TransactionTag tag, Color baseColor) {
    final isSelected = _selectedTag == tag;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Jika bubble yang sama diklik lagi, batalkan pilihan. Jika beda, pindah pilihan.
            _selectedTag = isSelected ? TransactionTag.none : tag;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? baseColor : baseColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? baseColor : Colors.transparent,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : baseColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}