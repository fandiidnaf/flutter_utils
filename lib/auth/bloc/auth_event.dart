part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class CheckAuthStatusEvent extends AuthEvent {}

final class LoginEvent extends AuthEvent {
  final String username;
  final String password;

  const LoginEvent({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

final class RegisterEvent extends AuthEvent {
  final String username;
  final String password;
  final String email;
  final String? profilePicturePath;

  const RegisterEvent({
    required this.username,
    required this.password,
    required this.email,
    required this.profilePicturePath,
  });

  @override
  List<Object?> get props => [username, password, email, profilePicturePath];
}

class UpdateAccountEvent extends AuthEvent {
  final int id;
  final String username;
  final String password;
  final String email;
  final String? profilePicturePath;

  const UpdateAccountEvent({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.profilePicturePath,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    password,
    email,
    profilePicturePath,
  ];
}

class LogoutEvent extends AuthEvent {}
