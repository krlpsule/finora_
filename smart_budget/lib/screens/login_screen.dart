// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/auth_bloc.dart';
import '../features/auth/auth_event.dart';
import '../features/auth/auth_state.dart';
import 'main_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true; 

  void _submitAuthForm(AuthBloc authBloc) {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid credentials (min 6 chars).')),
      );
      return;
    }

    // Close the keyboard manually (Helps prevent focus-related errors on navigation)
    FocusScope.of(context).unfocus();

    _isLogin 
      ? authBloc.add(LoginRequested(email, password))
      : authBloc.add(SignUpRequested(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async { // 🚨 Added 'async' keyword here
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } 
          else if (state is Authenticated) {
            // 🚨 FIX 1: Unfocus keyboard/text fields immediately
            // This prevents the 'disposed EngineFlutterView' error on Flutter Web
            // when navigating away while a text field is still focused.
            FocusScope.of(context).unfocus();

            // 🚨 FIX 2: Add a slight delay
            // Allows the engine to process the unfocus event before destroying the view.
            await Future.delayed(const Duration(milliseconds: 100));

            // 🚨 FIX 3: Check if the widget is still mounted
            // Prevents using 'context' if the user left the screen during the delay.
            if (!context.mounted) return;

            // Navigate to MainScreen and remove previous screens from the stack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false, 
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(_isLogin ? 'Welcome Back' : 'Create an account',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              _buildTextField(_emailController, 'Email', TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildTextField(_passwordController, 'Password', TextInputType.visiblePassword, obscure: true),
              
              const SizedBox(height: 40),
              
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) return const Center(child: CircularProgressIndicator());
                  return ElevatedButton(
                    onPressed: () => _submitAuthForm(authBloc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1B2A),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(_isLogin ? 'Login' : 'Sign Up', 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  );
                },
              ),
              const SizedBox(height: 25),
              
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: RichText(
                    text: TextSpan(
                      text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                      children: [
                        TextSpan(
                          text: _isLogin ? 'Sign Up' : 'Login',
                          style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0D1B2A), width: 1.5),
        ),
      ),
    );
  }
}