import 'package:flutter/material.dart';
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
      home: const MainNavigationPage(), 
    );
  }
}
