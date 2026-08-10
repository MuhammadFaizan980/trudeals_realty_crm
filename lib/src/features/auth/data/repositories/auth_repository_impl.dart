import 'package:dart_either/dart_either.dart';

import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_exception.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/core/network/token_storage.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final NetworkClient _client;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl(this._client, this._tokenStorage);

  @override
  Future<NetworkResult<User>> login(String email, String password) async {
    final result = await _client.post<Map<String, dynamic>>(
      path: '/api/auth/login',
      data: {'email': email, 'password': password},
      decoder: (data) => Map<String, dynamic>.from(data as Map),
    );

    Map<String, dynamic>? body;
    NetworkException? error;
    result.fold(ifLeft: (e) => error = e, ifRight: (b) => body = b);
    if (error != null) return Left(error!);

    final token = body!['token'] as String;
    await _tokenStorage.write(token);
    return Right(User.fromJson(Map<String, dynamic>.from(body!['user'] as Map)));
  }

  @override
  Future<NetworkResult<User>> getCurrentUser() {
    return _client.get(
      path: '/api/auth/me',
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return User.fromJson(Map<String, dynamic>.from(json['user'] as Map));
      },
    );
  }

  @override
  Future<void> logout() async {
    await _client.post(path: '/api/auth/logout');
    await _tokenStorage.clear();
  }
}
