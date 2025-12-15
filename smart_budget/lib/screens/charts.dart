// lib/screens/charts.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_state.dart';
import '../models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

// Mutlaka import edilmeli
import '../features/transaction/transaction_state.dart';

// Tüm aylık finansal verileri tutacak yeni sınıf
class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> expenseByCategory;

  MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseByCategory,
  });
}

// ChartsPage içeriği
class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  // ---------------------------------------------------------------------
  // 1. Hesaplama Metodu
  // ---------------------------------------------------------------------
  MonthlySummary _calculateMonthlyTotals(List<TransactionModel> transactions) {
    final now = DateTime.now();
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final expenseMap = <String, double>{};

    for (var tx in transactions) {
      if (tx.date.year == now.year && tx.date.month == now.month) {
        if (tx.isIncome) {
          totalIncome += tx.amount;
        } else {
          totalExpense += tx.amount;
          expenseMap[tx.category] = (expenseMap[tx.category] ?? 0) + tx.amount;
        }
      }
    }

    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      expenseByCategory: expenseMap,
    );
  }

  // ---------------------------------------------------------------------
  // 2. Dinamik Bütçe Görünümü (Budget Progress)
  // ---------------------------------------------------------------------
  Widget _buildBudgetProgress(MonthlySummary summary) {
    final targetBudget = summary.totalIncome > 0 ? summary.totalIncome : 1.0;
    final currentSpending = summary.totalExpense;
    double progress = currentSpending / targetBudget;

    Color progressColor = progress > 1.0 ? Colors.red : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Budget Tracking (Based on Income)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Spent: ${currentSpending.toStringAsFixed(2)} TL / Income: ${summary.totalIncome.toStringAsFixed(2)} TL',
              style: TextStyle(fontSize: 14, color: progressColor),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              color: progressColor,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            if (progress > 1.0)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'WARNING: Spending exceeded your income!',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 3. Pasta Grafik (Expense Distribution)
  // ---------------------------------------------------------------------
  Widget _buildPieChart(Map<String, double> expenseByCategory) {
    if (expenseByCategory.isEmpty) {
      return const Center(child: Text('No expenses recorded this month.'));
    }

    final totalExpense =
        expenseByCategory.values.fold(0.0, (sum, item) => sum + item);
    int index = 0;

    List<PieChartSectionData> sections = expenseByCategory.entries.map((entry) {
      final percentage = (entry.value / totalExpense) * 100;
      final category = entry.key;

      const colors = [
        Colors.indigo,
        Colors.blue,
        Colors.teal,
        Colors.orange,
        Colors.pink,
        Colors.purple,
      ];

      return PieChartSectionData(
        color: colors[index++ % colors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        badgeWidget: Text(category, style: const TextStyle(fontSize: 10)),
        badgePositionPercentageOffset: 1.1,
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expense Distribution by Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    borderData: FlBorderData(show: false),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 4. Kategori Listesi (Category List)
  // ---------------------------------------------------------------------
  Widget _buildCategoryList(Map<String, double> expenseByCategory) {
    if (expenseByCategory.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Category Spending Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...expenseByCategory.entries.map((entry) {
            return ListTile(
              title: Text(entry.key),
              trailing: Text('${entry.value.toStringAsFixed(2)} TL',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.label_important_outline,
                  color: Colors.indigo),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 5. Build Metodu
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoaded) {
          final summary = _calculateMonthlyTotals(state.transactions);

          if (summary.totalIncome == 0 && summary.totalExpense == 0) {
            return const Center(
                child: Text('No transactions recorded this month.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBudgetProgress(summary),
                const SizedBox(height: 16),
                _buildPieChart(summary.expenseByCategory),
                const SizedBox(height: 16),
                _buildCategoryList(summary.expenseByCategory),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}