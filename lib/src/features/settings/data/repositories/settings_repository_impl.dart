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
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['stages'] as List).map((e) => Stage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
  }

  Stage _decodeStage(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    return Stage.fromJson(Map<String, dynamic>.from(json['stage'] as Map));
  }

  @override
  Future<NetworkResult<Stage>> saveStage(Stage stage) {
    if (stage.key.isEmpty) {
      return _client.post(path: '/api/stages', data: stage.toCreateJson(), decoder: _decodeStage);
    }
    return _client.patch(path: '/api/stages/${stage.key}', data: stage.toUpdateJson(), decoder: _decodeStage);
  }

  @override
  Future<NetworkResult<void>> deleteStage(String key) {
    return _client.delete(path: '/api/stages/$key');
  }

  @override
  Future<NetworkResult<void>> reorderStages(List<String> keys) {
    return _client.patch(path: '/api/stages/reorder', data: {'order': keys});
  }

  @override
  Future<NetworkResult<List<User>>> getUsers() {
    return _client.get(
      path: '/api/users',
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['users'] as List).map((e) => User.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
  }

  User _decodeUser(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    return User.fromJson(Map<String, dynamic>.from(json['user'] as Map));
  }

  @override
  Future<NetworkResult<User>> saveUser(User user) {
    if (user.id.isEmpty) {
      return _client.post(path: '/api/users', data: user.toJson(), decoder: _decodeUser);
    }
    return _client.patch(path: '/api/users/${user.id}', data: user.toJson(), decoder: _decodeUser);
  }

  @override
  Future<NetworkResult<Map<String, List<dynamic>>>> getTemplates() {
    return _client.get(
      path: '/api/templates',
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        final templates = (json['templates'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return {
          'email': templates.where((t) => t['channel'] == 'email').toList(),
          'sms': templates.where((t) => t['channel'] == 'sms').toList(),
        };
      },
    );
  }
}
