import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finora Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Finora!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/add'),
              child: const Text('Add Transaction'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/stats'),
              child: const Text('View Statistics'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/advice'),
              child: const Text('AI Advice Assistant'),
            ),
          ],
        ),
      ),
    );
  }
}
