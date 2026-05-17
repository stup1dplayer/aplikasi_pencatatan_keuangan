import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_provider.dart';
import '../widgets/custom_drawer.dart';
import '../theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedMonth = DateTime.now();

  final List<String> _monthNames = [
    "Januari", "Februari", "Maret", "April", "Mei", "Juni",
    "Juli", "Agustus", "September", "Oktober", "November", "Desember"
  ];

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan'), centerTitle: true),
      drawer: const CustomDrawer(),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final allTransactions = provider.groupedTransactions.values.expand((list) => list).toList();
          final now = DateTime.now();

          double todayIncome = 0;
          double todayExpense = 0;

          double selectedMonthIncome = 0;
          double selectedMonthExpense = 0;

          // Variabel untuk Tagging Pie Chart
          double primerExpense = 0;
          double sekunderExpense = 0;
          double tersierExpense = 0;
          double uncategorizedExpense = 0;

          List<double> weeklyIncome = [0.0, 0.0, 0.0, 0.0];
          List<double> weeklyExpense = [0.0, 0.0, 0.0, 0.0];

          for (var tx in allTransactions) {
            bool isToday = tx.dateTime.year == now.year && tx.dateTime.month == now.month && tx.dateTime.day == now.day;
            bool isSelectedMonth = tx.dateTime.year == _selectedMonth.year && tx.dateTime.month == _selectedMonth.month;

            if (isToday) {
              if (tx.type == TransactionType.income) todayIncome += tx.amount;
              else todayExpense += tx.amount;
            }

            if (isSelectedMonth) {
              if (tx.type == TransactionType.income) {
                selectedMonthIncome += tx.amount;
              } else {
                selectedMonthExpense += tx.amount;

                // Distribusi Tagging Pengeluaran
                switch (tx.tag) {
                  case TransactionTag.primer: primerExpense += tx.amount; break;
                  case TransactionTag.sekunder: sekunderExpense += tx.amount; break;
                  case TransactionTag.tersier: tersierExpense += tx.amount; break;
                  default: uncategorizedExpense += tx.amount; break;
                }
              }

              int day = tx.dateTime.day;
              int weekIndex = (day - 1) ~/ 7;
              if (weekIndex > 3) weekIndex = 3;

              if (tx.type == TransactionType.income) {
                weeklyIncome[weekIndex] += tx.amount;
              } else {
                weeklyExpense[weekIndex] += tx.amount;
              }
            }
          }

          final todayNet = todayIncome - todayExpense;
          final selectedMonthNet = selectedMonthIncome - selectedMonthExpense;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Tetap Sama)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: todayNet >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const Text('Bersih Hari Ini', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(currencyFormat.format(todayNet), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Navigasi Bulan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: _previousMonth, color: AppColors.primary),
                      Text('${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 20), onPressed: (_selectedMonth.year == now.year && _selectedMonth.month == now.month) ? null : _nextMonth, color: AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Ringkasan Bulan Ini
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildReportCard(selectedMonthIncome, selectedMonthExpense, selectedMonthNet, currencyFormat),
                ),
                const SizedBox(height: 32),

                // --- 4. PIE CHART TAGGING PENGELUARAN (BARU) ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Distribusi Pengeluaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _buildPieChartSections(primerExpense, sekunderExpense, tersierExpense, uncategorizedExpense),
                          ),
                        ),
                      ),
                      // Legenda (Keterangan Warna)
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendIndicator(Colors.redAccent, 'Primer'),
                            const SizedBox(height: 8),
                            _buildLegendIndicator(Colors.orangeAccent, 'Sekunder'),
                            const SizedBox(height: 8),
                            _buildLegendIndicator(Colors.lightBlueAccent, 'Tersier'),
                            const SizedBox(height: 8),
                            _buildLegendIndicator(Colors.grey, 'Lainnya'),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 5. Bar Chart Mingguan (Tetap Sama)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Tren Mingguan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  padding: const EdgeInsets.only(right: 16, left: 8),
                  child: BarChart(_buildDynamicBarChart(weeklyIncome, weeklyExpense)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Fungsi Pie Chart ---
  List<PieChartSectionData> _buildPieChartSections(double primer, double sekunder, double tersier, double none) {
    final double total = primer + sekunder + tersier + none;

    // Tampilan kosong jika belum ada pengeluaran
    if (total == 0) {
      return [PieChartSectionData(value: 1, color: Colors.grey.shade300, title: 'Kosong', radius: 40, titleStyle: const TextStyle(fontSize: 12, color: Colors.black54))];
    }

    return [
      if (primer > 0) PieChartSectionData(color: Colors.redAccent, value: primer, title: '${((primer/total)*100).toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      if (sekunder > 0) PieChartSectionData(color: Colors.orangeAccent, value: sekunder, title: '${((sekunder/total)*100).toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      if (tersier > 0) PieChartSectionData(color: Colors.lightBlueAccent, value: tersier, title: '${((tersier/total)*100).toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      if (none > 0) PieChartSectionData(color: Colors.grey, value: none, title: '${((none/total)*100).toStringAsFixed(0)}%', radius: 45, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
    ];
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // --- Fungsi Bantuan Laporan Bulanan & Bar Chart (Kode sebelumnya tidak diubah) ---
  Widget _buildReportCard(double income, double expense, double net, NumberFormat format) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildMonthlyRow('Total Pemasukan', income, AppColors.incomeGreen, format),
            const Divider(height: 24),
            _buildMonthlyRow('Total Pengeluaran', expense, AppColors.expenseRed, format),
            const Divider(height: 24),
            _buildMonthlyRow('Sisa Saldo', net, net >= 0 ? AppColors.primary : AppColors.expenseRed, format, isBold: true, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRow(String title, double amount, Color color, NumberFormat format, {bool isBold = false, double size = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(format.format(amount), style: TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  BarChartData _buildDynamicBarChart(List<double> weeklyIncome, List<double> weeklyExpense) {
    double maxVal = 0;
    for (int i = 0; i < 4; i++) {
      if (weeklyIncome[i] > maxVal) maxVal = weeklyIncome[i];
      if (weeklyExpense[i] > maxVal) maxVal = weeklyExpense[i];
    }
    if (maxVal == 0) maxVal = 100000;

    return BarChartData(
      maxY: maxVal * 1.2,
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold);
              String text = '';
              switch (value.toInt()) {
                case 0: text = 'Mg 1'; break;
                case 1: text = 'Mg 2'; break;
                case 2: text = 'Mg 3'; break;
                case 3: text = 'Mg 4'; break;
              }
              return SideTitleWidget(meta: meta, child: Text(text, style: style));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        _buildBarGroup(0, weeklyIncome[0], weeklyExpense[0]),
        _buildBarGroup(1, weeklyIncome[1], weeklyExpense[1]),
        _buildBarGroup(2, weeklyIncome[2], weeklyExpense[2]),
        _buildBarGroup(3, weeklyIncome[3], weeklyExpense[3]),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double income, double expense) {
    return BarChartGroupData(
      x: x,
      barsSpace: 6,
      barRods: [
        BarChartRodData(toY: income, color: AppColors.incomeGreen, width: 16, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: expense, color: AppColors.expenseRed, width: 16, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }
}