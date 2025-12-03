// lib/screens/charts.dart (Güncellenmiş BLoC Kullanımı)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // BLoC eklendi
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_state.dart';
import '../models/transaction_model.dart';
// import '../services/firestore_service.dart'; // Artık gerek yok

class ChartsPage extends StatelessWidget { // Sınıf adını ChartsPage olarak güncelleyelim (dosya adınız charts.dart idi)
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Charts')),
      // StreamBuilder yerine BlocBuilder kullanın
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          
          if (state is TransactionLoading || state is TransactionInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is TransactionError) {
            return Center(child: Text('Error loading data: ${state.message}'));
          }

          if (state is TransactionLoaded) {
            final data = state.transactions;
            
            // Veri manipülasyonu BLoC'tan gelen verilerle yapılır
            final categorySums = _sumByCategoryThisMonth(data);
            final monthlyExpenseTotal = categorySums.values.fold(0.0, (p, c) => p + c);
            
            // Eğer hiç veri yoksa gösterilecek mesaj
            if (categorySums.isEmpty) {
              return const Center(child: Text('No expense data this month.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. AYLIK PASTA GRAFİĞİ (PRD R5.5.1) ---
                  _buildChartCard(
                    title: 'Monthly Expense Distribution',
                    chartWidget: SizedBox(
                      height: 250,
                      child: _buildPieChart(categorySums, monthlyExpenseTotal),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 2. BÜTÇE İLERLEME GÖSTERGESİ (PRD R5.5.3) ---
                  _buildChartCard(
                    title: 'Budget Progress',
                    // Şimdilik 1000 TL bütçe varsayalım
                    chartWidget: _buildBudgetMeter(monthlyExpenseTotal, 1000.0), 
                  ),
                  const SizedBox(height: 24),
                  
                  // --- 3. ÇUBUK GRAFİK (PRD R5.5.2) ---
                  _buildChartCard(
                    title: 'Weekly Expense Trend (Coming Soon)',
                    chartWidget: const SizedBox(
                      height: 200,
                      child: Center(child: Text('Bar Chart visualization will be here.')),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Waiting for data...'));
        },
      ),
    );
  }
  
  // Widget'ları Card içine alan yardımcı metot
  Widget _buildChartCard({required String title, required Widget chartWidget}) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              chartWidget,
            ],
          ),
        ),
      );
  }

  // PRD R5.5.3: Bütçe Göstergesi
  Widget _buildBudgetMeter(double currentExpense, double monthlyBudget) {
    final percentage = (currentExpense / monthlyBudget).clamp(0.0, 1.0);
    final isOverBudget = currentExpense > monthlyBudget;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: percentage,
          minHeight: 10,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOverBudget ? Colors.red.shade700 : (percentage > 0.8 ? Colors.orange : Colors.indigo)
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Spent: ₺${currentExpense.toStringAsFixed(2)} / Budget: ₺${monthlyBudget.toStringAsFixed(2)}',
          style: TextStyle(color: isOverBudget ? Colors.red : Colors.grey.shade600),
        ),
        if (isOverBudget)
          const Text('Warning: You are over budget!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // PRD R5.5.1: Pasta Grafiği Metodu
  Map<String, double> _sumByCategoryThisMonth(List<TransactionModel> list) {
    final now = DateTime.now();
    final map = <String, double>{};
    for (var tx in list) {
      // Sadece bu ayın giderlerini hesapla
      if (tx.date.year == now.year && tx.date.month == now.month && !tx.isIncome) {
        map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
      }
    }
    return map;
  }
  
  // Pasta Grafiği Oluşturma Metodu
  Widget _buildPieChart(Map<String, double> data, double total) {
    // Renkleri rastgele atamak yerine sabit bir palet kullanmak daha iyidir.
    final List<Color> colorPalette = [
      Colors.indigo.shade400, Colors.green.shade400, Colors.orange.shade400,
      Colors.purple.shade400, Colors.teal.shade400, Colors.pink.shade400
    ];

    final entries = data.entries.toList();
    
    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((entry) {
          final idx = entry.key;
          final kv = entry.value;
          final value = kv.value;
          final percentage = (value / total) * 100;
          
          return PieChartSectionData(
            color: colorPalette[idx % colorPalette.length],
            value: value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 3,
        centerSpaceRadius: 50,
      ),
    );
  }
}