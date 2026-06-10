import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_provider.dart';
import '../widgets/custom_drawer.dart';
import '../theme.dart';

enum FilterType { all, income, expense }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  FilterType _currentFilter = FilterType.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Catatan'),
        centerTitle: true,
        actions: [
          PopupMenuButton<FilterType>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Transaksi',
            onSelected: (FilterType result) {
              setState(() {
                _currentFilter = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<FilterType>>[
              const PopupMenuItem<FilterType>(
                value: FilterType.all,
                child: Text('Tampilkan Semua'),
              ),
              const PopupMenuItem<FilterType>(
                value: FilterType.income,
                child: Text('Hanya Pemasukan'),
              ),
              const PopupMenuItem<FilterType>(
                value: FilterType.expense,
                child: Text('Hanya Pengeluaran'),
              ),
            ],
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final grouped = provider.groupedTransactions;

          Map<String, List<TransactionEntity>> filteredGrouped = {};

          grouped.forEach((date, transactions) {
            final filteredTxs = transactions.where((tx) {
              if (_currentFilter == FilterType.income) {
                return tx.type == TransactionType.income;
              } else if (_currentFilter == FilterType.expense) {
                return tx.type == TransactionType.expense;
              }
              return true;
            }).toList();

            if (filteredTxs.isNotEmpty) {
              filteredGrouped[date] = filteredTxs;
            }
          });

          if (filteredGrouped.isEmpty) {
            return const Center(child: Text('Tidak ada catatan untuk filter ini.'));
          }

          final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          final timeFormat = DateFormat('HH:mm');

          return ListView.builder(
            itemCount: filteredGrouped.length,
            itemBuilder: (context, index) {
              String dateHeader = filteredGrouped.keys.elementAt(index);
              List<TransactionEntity> transactions = filteredGrouped[dateHeader]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[200],
                    child: Text(dateHeader, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, idx) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final tx = transactions[idx];
                      final isIncome = tx.type == TransactionType.income;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? AppColors.incomeGreen.withValues(alpha: 0.2) : AppColors.expenseRed.withValues(alpha: 0.2),
                          child: Icon(
                            isIncome ? Icons.account_balance_wallet : Icons.shopping_cart,
                            color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                          ),
                        ),
                        title: Text(tx.description.isNotEmpty ? tx.description : 'Tanpa Deskripsi'),
                        subtitle: Text('${timeFormat.format(tx.dateTime)} • ${tx.account == AccountType.cash ? 'Cash' : 'Bank'}'),
                        trailing: Text(
                          currencyFormat.format(tx.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                          ),
                        ),
                        onLongPress: () => _showOptionsDialog(context, tx, provider),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, TransactionEntity tx, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Edit Transaksi'),
            onTap: () {
              Navigator.pop(ctx);
              _showEditDialog(context, tx, provider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus Transaksi'),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, tx, provider);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TransactionEntity tx, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Catatan "${tx.description}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteTransaction(tx.id!);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI FORM EDIT DENGAN FITUR GANTI TANGGAL & JAM ---
  void _showEditDialog(BuildContext context, TransactionEntity tx, TransactionProvider provider) {
    final amountController = TextEditingController(text: tx.amount.toInt().toString());
    final descController = TextEditingController(text: tx.description);

    TransactionType selectedType = tx.type;
    AccountType selectedAccount = tx.account;
    TransactionTag selectedTag = tx.tag;

    // 1. Variabel State untuk menyimpan tanggal lama/baru
    DateTime selectedDateTime = tx.dateTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            final editDateFormat = DateFormat('dd MMM yyyy, HH:mm');

            // 2. Fungsi untuk memicu pemilih Tanggal dilanjut Jam
            Future<void> _pickDateTime() async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDateTime,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
              );

              if (pickedDate != null) {
                if (!context.mounted) return;
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                );

                if (pickedTime != null) {
                  // Gabungkan hasil pick tanggal dan pick jam
                  setModalState(() {
                    selectedDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 24, left: 24, right: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit Transaksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Input Nominal
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
                  ),
                  const SizedBox(height: 16),

                  // Input Deskripsi
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                  const SizedBox(height: 16),

                  // Pilihan Sumber Dana
                  DropdownButtonFormField<AccountType>(
                    value: selectedAccount,
                    decoration: const InputDecoration(labelText: 'Sumber Dana'),
                    items: AccountType.values.map((type) => DropdownMenuItem(
                        value: type, child: Text(type == AccountType.cash ? 'Cash' : 'Bank')
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedAccount = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pilihan Tagging (Hanya jika pengeluaran)
                  if (selectedType == TransactionType.expense) ...[
                    DropdownButtonFormField<TransactionTag>(
                      value: selectedTag,
                      decoration: const InputDecoration(labelText: 'Kategori (Opsional)'),
                      items: const [
                        DropdownMenuItem(value: TransactionTag.none, child: Text('Tanpa Tag')),
                        DropdownMenuItem(value: TransactionTag.primer, child: Text('Primer')),
                        DropdownMenuItem(value: TransactionTag.sekunder, child: Text('Sekunder')),
                        DropdownMenuItem(value: TransactionTag.tersier, child: Text('Tersier')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedTag = val);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. UI KOLOM TANGGAL YANG BISA DIKLIK (DIBUNGKUS INKWELL)
                  InkWell(
                    onTap: _pickDateTime,
                    child: IgnorePointer(
                      child: TextFormField(
                        // Menggunakan controller lokal instan untuk mengikuti perubahan data state
                        controller: TextEditingController(
                          text: editDateFormat.format(selectedDateTime),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tanggal & Jam',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Simpan Perubahan
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    onPressed: () async {
                      final newAmount = double.tryParse(amountController.text) ?? 0;
                      if (newAmount > 0) {
                        // 4. Masukkan 'selectedDateTime' ke dalam copyWith
                        final updatedEntity = tx.copyWith(
                          amount: newAmount,
                          description: descController.text,
                          account: selectedAccount,
                          tag: selectedType == TransactionType.expense ? selectedTag : TransactionTag.none,
                          dateTime: selectedDateTime,
                        );

                        await provider.addTransaction(updatedEntity);
                        if (context.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
      ),
    );
  }
}