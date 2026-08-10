import '../../../../core/network/network_typedefs.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<NetworkResult<User>> call(String email, String password) {
    return _repository.login(email, password);
  }
}
