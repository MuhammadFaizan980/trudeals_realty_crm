import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final NetworkClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<NetworkResult<User>> login(String email, String password) {
    return _client.post(
      path: '/api/auth/login',
      data: {'email': email, 'password': password},
      decoder: (data) => _parseUser(data),
    );
  }

  @override
  Future<NetworkResult<User>> getCurrentUser() {
    return _client.get(
      path: '/api/auth/me',
      decoder: (data) => _parseUser(data),
    );
  }

  @override
  Future<void> logout() async {
    await _client.post(path: '/api/auth/logout');
  }

  User _parseUser(dynamic data) {
    // Hive returns _Map<dynamic, dynamic> which fails to cast to Map<String, dynamic>
    final json = Map<String, dynamic>.from(data as Map);
    return User.fromJson(json);
  }
}
