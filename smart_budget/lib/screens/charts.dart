// lib/screens/charts.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Ensure intl is in pubspec.yaml
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_state.dart';
import '../models/transaction_model.dart';

// --- Helper Class for Monthly Data ---
class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> expenseByCategory;
  final Map<int, double> dailyExpenses; // For Bar Chart

  MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expenseByCategory,
    required this.dailyExpenses,
  });
}

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  // Current selected month for filtering
  DateTime _selectedDate = DateTime.now();

  // ---------------------------------------------------------------------
  // 1. Calculation Logic
  // ---------------------------------------------------------------------
  MonthlySummary _calculateMonthlyTotals(List<TransactionModel> transactions) {
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final expenseMap = <String, double>{};
    final dailyMap = <int, double>{};

    // Filter transactions based on selected Month and Year
    final filteredTransactions = transactions.where((tx) {
      return tx.date.year == _selectedDate.year &&
          tx.date.month == _selectedDate.month;
    }).toList();

    for (var tx in filteredTransactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        
        // Aggregate by Category
        expenseMap[tx.category] = (expenseMap[tx.category] ?? 0) + tx.amount;
        
        // Aggregate by Day (for Bar Chart)
        int day = tx.date.day;
        dailyMap[day] = (dailyMap[day] ?? 0) + tx.amount;
      }
    }

    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      expenseByCategory: expenseMap,
      dailyExpenses: dailyMap,
    );
  }

  // ---------------------------------------------------------------------
  // 2. Month Selector Widget
  // ---------------------------------------------------------------------
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate), // Requires 'intl' package
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 3. Summary Cards (Income, Expense, Balance)
  // ---------------------------------------------------------------------
  Widget _buildSummaryCards(MonthlySummary summary) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: "Income",
            amount: summary.totalIncome,
            color: Colors.green.shade700,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            title: "Expense",
            amount: summary.totalExpense,
            color: Colors.red.shade700,
            icon: Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            title: "Balance",
            amount: summary.balance,
            color: Colors.blue.shade700,
            icon: Icons.account_balance_wallet,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required double amount, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            "${amount.toStringAsFixed(0)} ₺", // Removed cents for cleaner look
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 4. Bar Chart (Daily Spending Trend)
  // ---------------------------------------------------------------------
  Widget _buildBarChart(Map<int, double> dailyData) {
    if (dailyData.isEmpty) return const SizedBox.shrink();

    // Prepare chart groups
    List<BarChartGroupData> barGroups = [];
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    // Show bars for every day, or just days with data? Let's show all days with data.
    // To make it look good, we sort the keys.
    var sortedKeys = dailyData.keys.toList()..sort();
    
    for (int i = 0; i < sortedKeys.length; i++) {
      int day = sortedKeys[i];
      double amount = dailyData[day]!;
      
      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Colors.indigoAccent,
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Daily Spending Trend", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.6,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (dailyData.values.isEmpty ? 100 : dailyData.values.reduce((a, b) => a > b ? a : b)) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${group.x}. Day\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toStringAsFixed(2)} ₺',
                              style: const TextStyle(color: Colors.yellowAccent),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                           // Show label only for specific intervals to avoid clutter
                           if (value.toInt() % 5 == 0 || value.toInt() == 1) {
                             return Padding(
                               padding: const EdgeInsets.only(top: 5),
                               child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                             );
                           }
                           return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 5. Donut Chart (Modern Pie Chart)
  // ---------------------------------------------------------------------
  Widget _buildDonutChart(Map<String, double> expenseByCategory) {
    if (expenseByCategory.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No expenses recorded for this month.', style: TextStyle(color: Colors.grey))),
      );
    }

    final totalExpense = expenseByCategory.values.fold(0.0, (sum, item) => sum + item);
    int index = 0;

    // Define a nice color palette
    final List<Color> palette = [
      Colors.blue, Colors.redAccent, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.pinkAccent
    ];

    List<PieChartSectionData> sections = expenseByCategory.entries.map((entry) {
      final percentage = (entry.value / totalExpense) * 100;
      final color = palette[index++ % palette.length];

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50, // Thinner radius for Donut effect
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: _buildBadge(entry.key, color),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Expense Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40, // Creates the hole
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Text(
        text.length > 10 ? "${text.substring(0, 8)}..." : text, // Truncate long names
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 6. Category List
  // ---------------------------------------------------------------------
  Widget _buildCategoryList(Map<String, double> expenseByCategory) {
    if (expenseByCategory.isEmpty) return const SizedBox.shrink();

    // Sort categories by amount (Highest first)
    var sortedEntries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text("Details by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...sortedEntries.map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: const Icon(Icons.category, color: Colors.indigo),
              ),
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Text(
                '${entry.value.toStringAsFixed(2)} ₺',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold added to ensure proper background color if needed
      backgroundColor: Colors.grey.shade50, 
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          if (state is TransactionLoaded) {
            final summary = _calculateMonthlyTotals(state.transactions);
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 10),
                  _buildSummaryCards(summary),
                  const SizedBox(height: 20),
                  
                  // Only show charts if there is data
                  if (summary.expenseByCategory.isNotEmpty || summary.totalIncome > 0) ...[
                     _buildBarChart(summary.dailyExpenses),
                     const SizedBox(height: 20),
                     _buildDonutChart(summary.expenseByCategory),
                     const SizedBox(height: 20),
                     _buildCategoryList(summary.expenseByCategory),
                  ] else ...[
                     const SizedBox(height: 50),
                     const Center(
                       child: Column(
                         children: [
                           Icon(Icons.bar_chart, size: 60, color: Colors.grey),
                           SizedBox(height: 10),
                           Text("No data for this month.", style: TextStyle(color: Colors.grey)),
                         ],
                       ),
                     )
                  ],
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            );
          }

          if (state is TransactionError) {
             return Center(child: Text(state.message));
          }

          return const Center(child: Text("Something went wrong."));
        },
      ),
    );
  }
}