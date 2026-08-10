import '../../../../core/network/network_typedefs.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class CreateContactUseCase {
  final ContactsRepository _repository;
  CreateContactUseCase(this._repository);

  Future<NetworkResult<Contact>> call(Contact contact) {
    return _repository.createContact(contact);
  }
}
