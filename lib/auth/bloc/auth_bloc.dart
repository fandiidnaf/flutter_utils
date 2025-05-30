import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/error/error.dart';
import '../models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_checkAuthStatusEvent);
    on<LoginEvent>(_loginEvent);
    on<RegisterEvent>(_registerEvent);
    on<UpdateAccountEvent>(_updateAccount);
    on<LogoutEvent>(_logout);
  }

  Future<void> _checkAuthStatusEvent(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // TODO
    /* real case:
    final user = await checkAuthStatusUseCase(NoParams());
    */

    // Contoh: Jika ada token valid, anggap authenticated
    // Jika tidak, anggap unauthenticated atau error jika ada masalah
    // Simulasi delay login
    await Future.delayed(const Duration(seconds: 2));

    // simulasi berhasil
    final user = Right<AppError, User>(
      User(id: 1, username: "username", email: "email", password: "password"),
    );

    // simulasi gagal
    /*
    final user = Left<AppError, User>(
      AppError(message: "Token Not Valid!", statusCode: 401),
    );
    */

    // TODO

    user.fold(
      (l) => emit(AuthError(message: l.message, statusCode: l.statusCode)),
      (r) => emit(Authenticated(user: r)),
    );
  }

  Future<void> _loginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // TODO
    // real case:
    /*
    final user = await loginUseCase(
      LoginParams(name: event.username, password: event.password),
    );
   */

    // Simulasi delay login
    await Future.delayed(const Duration(seconds: 2));

    // simulasi berhasil
    final user = Right<AppError, User>(
      User(id: 1, username: "username", email: "email", password: "password"),
    );

    // simulasi gagal
    /*
     final user = Left<AppError, User>(
       AppError(message: "Invalid username or password"),
     );
     */
    // TODO

    user.fold(
      (l) => emit(AuthError(message: l.message, statusCode: l.statusCode)),
      (r) => emit(Authenticated(user: r)),
    );
  }

  Future<void> _registerEvent(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // TODO
    /* real case:
    final user = await registerUseCase(
      RegisterParams(
        user: User(
          id: 0,
          email: event.email,
          username: event.username,
          password: event.password,
          profilePicturePath: event.profilePicturePath,
        ),
      ),
    );
  */

    // Simulasi delay login
    await Future.delayed(const Duration(seconds: 2));

    // simulasi berhasil
    final user = Right<AppError, User>(
      User(id: 1, username: "username", email: "email", password: "password"),
    );

    // simulasi gagal
    /*
     final user = Left<AppError, User>(
       AppError(message: "failed register"),
     );
     */
    // TODO

    user.fold(
      (l) => emit(AuthError(message: l.message, statusCode: -1)),
      (r) => emit(Authenticated(user: r)),
    );
  }

  Future<void> _updateAccount(
    UpdateAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // TODO
    /* real case:
    final User user1 = User(
      id: event.id,
      username: event.username,
      password: event.password,
      email: event.email,
      profilePicturePath: event.profilePicturePath,
    );
    final user = await updateAccountUseCase(UpdateAccountParams(user: user1));
    */

    // Simulasi delay login
    await Future.delayed(const Duration(seconds: 2));

    // simulasi berhasil
    final user = Right<AppError, User>(
      User(id: 1, username: "username", email: "email", password: "password"),
    );

    // simulasi gagal
    /*
     final user = Left<AppError, User>(
       AppError(message: "failed update account"),
     );
     */
    // TODO

    user.fold(
      (l) => emit(AuthError(message: l.message, statusCode: -1)),
      (r) => emit(Authenticated(user: r)),
    );
  }

  Future<void> _logout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // TODO

    /* real case:
   final result =  await logoutUseCase(NoParams());
    */

    // Simulasi delay login
    await Future.delayed(const Duration(seconds: 2));

    // simulasi berhasil
    final result = Right<AppError, void>(null);

    // simulasi gagal
    /*
     final user = Left<AppError, void>(
       AppError(message: "Failed logout"),
     );
     */
    // TODO

    result.fold(
      (l) => emit(AuthError(message: l.message, statusCode: -1)),
      (r) => emit(Unauthenticated()),
    );
  }
}
