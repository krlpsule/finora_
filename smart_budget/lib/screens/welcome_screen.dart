// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🖼️ UPDATE: Logo Image Added Here
            // You can adjust the path according to your own file name.
            Container(
              height: 150, // You can adjust the logo size here
              width: 150,
              decoration: BoxDecoration(
                  // Optional: Uncomment this if you want to add a shadow or border
                  // borderRadius: BorderRadius.circular(20),
                  ),
              child: Image.asset(
                'assets/finora_logo.jpeg', // 🚨 Must match the exact path in pubspec.yaml
                fit: BoxFit.contain, // Fits without distorting the aspect ratio
              ),
            ),

            const SizedBox(height: 20),

            // If the "Finora" text is already inside the image, you can delete this Text widget.
            // If the image is just an icon, this text can stay.
            const Text('Finora',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A))),

            const SizedBox(height: 40),

            const Text('Welcome to Finora',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

            const SizedBox(height: 15),

            const Text('An engaging and lucrative component for your finances.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)),

            const SizedBox(height: 80),

            // Get Started Button
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B2A),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Get Started',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
