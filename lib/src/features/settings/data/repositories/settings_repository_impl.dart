import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/stage.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final NetworkClient _client;

  SettingsRepositoryImpl(this._client);

  @override
  Future<NetworkResult<List<Stage>>> getStages() {
    return _client.get(
      path: '/api/stages',
      decoder: (data) => (data as List).map((e) => Stage.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  @override
  Future<NetworkResult<Stage>> saveStage(Stage stage) {
    return _client.post(
      path: '/api/stages',
      data: stage.toJson(),
      decoder: (data) => Stage.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<NetworkResult<void>> deleteStage(String key) {
    return _client.delete(path: '/api/stages/$key');
  }

  @override
  Future<NetworkResult<void>> reorderStages(List<String> keys) {
    return _client.post(path: '/api/stages/reorder', data: {'keys': keys});
  }

  @override
  Future<NetworkResult<List<User>>> getUsers() {
    return _client.get(
      path: '/api/users',
      decoder: (data) => (data as List).map((e) => User.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  @override
  Future<NetworkResult<User>> saveUser(User user) {
    return _client.post(
      path: '/api/users',
      data: user.toJson(),
      decoder: (data) => User.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<NetworkResult<Map<String, List<dynamic>>>> getTemplates() {
    return _client.get(
      path: '/api/templates',
      decoder: (data) => Map<String, List<dynamic>>.from(data as Map),
    );
  }
}
