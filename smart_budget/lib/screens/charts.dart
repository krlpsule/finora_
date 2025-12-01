import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import 'dart:collection';

class ChartsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Charts')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: fs.streamTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          final categorySums = _sumByCategoryThisMonth(data);
          return Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Monthly distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Expanded(child: _buildPieChart(categorySums)),
                SizedBox(height: 12),
                // Placeholder for bar chart or budget meter
                Text('Weekly / Monthly bars (coming soon)'),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, double> _sumByCategoryThisMonth(List<TransactionModel> list) {
    final now = DateTime.now();
    final map = <String, double>{};
    for (var tx in list) {
      if (tx.date.year == now.year && tx.date.month == now.month && !tx.isIncome) {
        map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
      }
    }
    return map;
  }

  Widget _buildPieChart(Map<String, double> data) {
    if (data.isEmpty) return Center(child: Text('No expense data this month.'));
    final entries = data.entries.toList();
    final total = entries.fold(0.0, (p, e) => p + e.value);
    return PieChart(PieChartData(
      sections: entries.asMap().entries.map((entry) {
        final idx = entry.key;
        final kv = entry.value;
        final value = kv.value;
        final percentage = (value / total) * 100;
        return PieChartSectionData(
          value: value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 60 + (idx % 3) * 6,
        );
      }).toList(),
      sectionsSpace: 2,
      centerSpaceRadius: 30,
    ));
  }
}
