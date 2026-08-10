import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/settings/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final NetworkClient _client;

  AdminRepositoryImpl(this._client);

  @override
  Future<NetworkResult<Map<String, dynamic>>> exportData() {
    return _client.get(
      path: '/api/export',
      decoder: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  @override
  Future<NetworkResult<Map<String, dynamic>>> importData(Map<String, dynamic> data) {
    return _client.post(
      path: '/api/import',
      data: data,
      decoder: (data) => Map<String, dynamic>.from(data as Map),
    );
  }
}
