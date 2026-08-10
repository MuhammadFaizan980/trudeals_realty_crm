import '../../../../core/network/network_typedefs.dart';
import '../../../contacts/domain/entities/stage.dart';
import '../../../auth/domain/entities/user.dart';

abstract interface class SettingsRepository {
  Future<NetworkResult<List<Stage>>> getStages();
  Future<NetworkResult<Stage>> saveStage(Stage stage);
  Future<NetworkResult<void>> deleteStage(String key);
  Future<NetworkResult<void>> reorderStages(List<String> keys);
  
  Future<NetworkResult<List<User>>> getUsers();
  Future<NetworkResult<User>> saveUser(User user);
  
  Future<NetworkResult<Map<String, List<dynamic>>>> getTemplates();
}
