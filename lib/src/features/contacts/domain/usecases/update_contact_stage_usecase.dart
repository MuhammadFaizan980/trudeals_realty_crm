import '../../../../core/network/network_typedefs.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class UpdateContactStageUseCase {
  final ContactsRepository _repository;
  UpdateContactStageUseCase(this._repository);

  Future<NetworkResult<Contact>> call(String contactId, String stageKey) {
    return _repository.updateStage(contactId, stageKey);
  }
}
