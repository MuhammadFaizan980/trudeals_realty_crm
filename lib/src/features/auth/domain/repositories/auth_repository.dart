import '../../../../core/network/network_typedefs.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<NetworkResult<User>> login(String email, String password);
  Future<NetworkResult<User>> getCurrentUser();
  Future<void> logout();
}
