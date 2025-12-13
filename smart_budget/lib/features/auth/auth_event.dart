// lib/features/auth/auth_event.dart

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

// Check the session status when the application opens
class AppStarted extends AuthEvent {}

// Login request
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested(this.email, this.password);
  
  @override
  List<Object> get props => [email, password];
}

// Sign-up request
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const SignUpRequested(this.email, this.password);
  
  @override
  List<Object> get props => [email, password];
}

// Logout request
class LogoutRequested extends AuthEvent {}