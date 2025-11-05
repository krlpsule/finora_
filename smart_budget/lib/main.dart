import 'package:flutter/material.dart';
import 'pages/add_transaction_page.dart';
import 'pages/statistics_page.dart';
import 'pages/advice_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/main_navigation_page.dart';

void main() {
  runApp(const SmartBudgetApp());
}

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finora',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MainNavigationPage(), // 👈 değişti
    );
  }
}
