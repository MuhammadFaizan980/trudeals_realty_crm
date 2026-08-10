import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter/foundation.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated && runtimeType == other.runtimeType && user == other.user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'Authenticated(${user.name})';
}
class Unauthenticated extends AuthState {
  @override
  String toString() => 'Unauthenticated';
}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError && runtimeType == other.runtimeType && message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'AuthError($message)';
}

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthCubit(this._loginUseCase, this._getCurrentUserUseCase, this._logoutUseCase) : super(AuthInitial());

  Future<void> checkAuth() async {
    debugPrint('AuthCubit: checkAuth starting...');
    emit(AuthLoading());
    try {
      final result = await _getCurrentUserUseCase().timeout(const Duration(seconds: 5));
      result.fold(
        ifLeft: (error) {
          debugPrint('AuthCubit: checkAuth left: ${error.message}');
          emit(Unauthenticated());
        },
        ifRight: (user) {
          debugPrint('AuthCubit: checkAuth right: ${user.name}');
          emit(Authenticated(user));
        },
      );
    } catch (e) {
      debugPrint('AuthCubit: checkAuth exception: $e');
      emit(Unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    debugPrint('AuthCubit: login starting for $email...');
    emit(AuthLoading());
    try {
      final result = await _loginUseCase(email, password).timeout(const Duration(seconds: 10));
      result.fold(
        ifLeft: (error) {
          debugPrint('AuthCubit: login left: ${error.message}');
          emit(AuthError(error.message));
        },
        ifRight: (user) {
          debugPrint('AuthCubit: login right: ${user.name}');
          emit(Authenticated(user));
        },
      );
    } catch (e) {
      debugPrint('AuthCubit: login exception: $e');
      emit(AuthError('Connection timed out or failed: $e'));
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
    emit(Unauthenticated());
  }
}
