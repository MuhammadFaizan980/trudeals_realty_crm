import '../../../../core/network/network_typedefs.dart';
import '../entities/contact.dart';
import '../entities/activity.dart';
import '../entities/communication.dart';
import '../entities/vendor_order.dart';

abstract interface class ContactsRepository {
  Future<NetworkResult<List<Contact>>> getContacts({
    String? query,
    String? stageKey,
    String? assignedTo,
  });
  Future<NetworkResult<Contact>> getContact(String id);
  Future<NetworkResult<Contact>> createContact(Contact contact);
  Future<NetworkResult<Contact>> updateContact(String id, Map<String, dynamic> data);
  Future<NetworkResult<Contact>> updateStage(String id, String stageKey);
  Future<NetworkResult<Contact>> updatePriority(String id, Priority priority);
  Future<NetworkResult<List<Activity>>> getActivities(String contactId);
  Future<NetworkResult<List<Communication>>> getCommunications(String contactId);
  Future<NetworkResult<List<VendorOrder>>> getVendorOrders(String contactId);
  Future<NetworkResult<void>> deleteContact(String id);
  Future<NetworkResult<List<Contact>>> getTrash();
  Future<NetworkResult<void>> restoreContact(String id);
}
