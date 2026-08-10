import '../../../../core/network/network_typedefs.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class GetContactsUseCase {
  final ContactsRepository _repository;
  GetContactsUseCase(this._repository);

  Future<NetworkResult<List<Contact>>> call({String? query, String? stageKey}) {
    return _repository.getContacts(query: query, stageKey: stageKey);
  }
}
