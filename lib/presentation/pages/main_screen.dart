import 'package:aplikasi_pencatatan_harian/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
        // --- LOGIKA CEK LIMIT HARIAN ---
        if (_selectedType == TransactionType.expense) {
          final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
          final limit = settingsProv.dailyLimit;

          if (limit > 0) {
            // Hitung total pengeluaran hari ini
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

            // Kalkulasi persentase dan tentukan pesan peringatan
            double percentage = todayExpense / limit;
            String warningMsg = '';
            Color warningColor = Colors.green;

            if (percentage >= 1.0) {
              warningMsg = '🚨 AWAS: Batas pengeluaran harianmu HABIS (Sisa 0%)!';
              warningColor = Colors.red;
            } else if (percentage >= 0.95) {
              warningMsg = '⚠️ PERINGATAN: Sisa batas pengeluaran tinggal 5%!';
              warningColor = Colors.deepOrange;
            } else if (percentage >= 0.90) {
              warningMsg = '⚠️ HATI-HATI: Sisa batas pengeluaran tinggal 10%.';
              warningColor = Colors.orange;
            } else if (percentage >= 0.75) {
              warningMsg = 'ℹ️ INFO: Sisa batas pengeluaran tinggal 25%.';
              warningColor = Colors.blue;
            }

            // Tampilkan Notifikasi Peringatan jika masuk zona limit
            if (warningMsg.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(warningMsg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: warningColor,
                  duration: const Duration(seconds: 4),
                ),
              );
            } else {
              // Notifikasi sukses biasa jika masih aman
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catatan berhasil disimpan')),
              );
            }
          } else {
            // Notifikasi sukses biasa jika fitur limit dimatikan
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catatan berhasil disimpan')),
            );
          }
        } else {
          // Notifikasi jika pemasukan
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pemasukan berhasil disimpan')),
          );
        }
        // --- SELESAI LOGIKA CEK LIMIT ---

        _amountController.clear();
        _descController.clear();
        setState(() {
          _selectedTag = TransactionTag.none;
          if (_selectedType == TransactionType.income) {
            _descController.text = 'ojol';
          }
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