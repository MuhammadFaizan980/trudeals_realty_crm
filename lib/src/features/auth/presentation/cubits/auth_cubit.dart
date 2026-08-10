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
      final result = await _getCurrentUserUseCase();
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
      final result = await _loginUseCase(email, password);
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

  /// Called when the network layer sees a 401 on a request that WAS
  /// carrying a token — the session expired or was revoked server-side.
  /// Unlike [logout], there's no point calling `/api/auth/logout` first
  /// (the token that would authorize it is already invalid), so this just
  /// drops straight to Unauthenticated so the root widget shows the login
  /// screen instead of every open screen failing independently.
  void forceLogout() {
    if (state is Authenticated) {
      emit(Unauthenticated());
    }
  }

  /// Switches to a different seat mid-session (the sidebar's seat picker).
  /// Unlike [login], a failure here does NOT emit [AuthError] — that would
  /// blow away the whole app via the root state machine. Instead the caller
  /// gets the error message back directly and the current session is left
  /// untouched on failure.
  Future<String?> switchUser(String email, String password) async {
    final result = await _loginUseCase(email, password);
    String? error;
    result.fold(
      ifLeft: (e) => error = e.message,
      ifRight: (user) => emit(Authenticated(user)),
    );
    return error;
  }
}
