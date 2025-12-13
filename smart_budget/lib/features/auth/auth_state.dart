// lib/features/auth/auth_state.dart

import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

// Startup/Loading status
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

// The user successfully logged in.
class Authenticated extends AuthState {
  final String userId;
  const Authenticated(this.userId);
  
  @override
  List<Object> get props => [userId];
}

// The user is not logged in.
class Unauthenticated extends AuthState {}

// An error occurred during authentication.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  
  @override
  List<Object> get props => [message];
}