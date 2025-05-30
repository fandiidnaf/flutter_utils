part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class Authenticated extends AuthState {
  final User user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

final class AuthError extends AuthState {
  final String message;
  final int statusCode;

  const AuthError({required this.message, required this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}
