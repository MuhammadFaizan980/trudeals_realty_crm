import '../../../../core/network/network_typedefs.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  GetCurrentUserUseCase(this._repository);

  Future<NetworkResult<User>> call() {
    return _repository.getCurrentUser();
  }
}
