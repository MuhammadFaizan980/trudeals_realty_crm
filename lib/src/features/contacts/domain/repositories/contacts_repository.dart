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
  Future<NetworkResult<Activity>> addActivity(String contactId, {required String type, required String text});
  Future<NetworkResult<List<Communication>>> getCommunications(String contactId);
  Future<NetworkResult<List<VendorOrder>>> getVendorOrders(String contactId);
  Future<NetworkResult<void>> deleteContact(String id);
  Future<NetworkResult<List<Contact>>> getTrash();
  Future<NetworkResult<void>> restoreContact(String id);

  Future<NetworkResult<Contact>> transferContact(String id, String toUserId, {String? note});
  Future<NetworkResult<Contact>> addTag(String id, String tag);
  Future<NetworkResult<Contact>> removeTag(String id, String tag);

  Future<NetworkResult<Contact>> scheduleCallback(
    String id, {
    required DateTime when,
    String? note,
    bool remind15 = true,
    bool remind10 = true,
  });
  Future<NetworkResult<void>> cancelCallback(String callbackId);

  Future<NetworkResult<Contact>> sendEmail(String id, {String? templateId, String? subject, String? body});
  Future<NetworkResult<Contact>> sendSms(String id, {String? templateId, String? body});
  Future<NetworkResult<Contact>> logReply(String id, {required String channel, required String body});

  /// [kind] is 'photos' or 'sign'.
  Future<NetworkResult<Contact>> placeOrder(String id, String kind, {String? company, DateTime? etaAt, String? notes});
  Future<NetworkResult<Contact>> cancelOrder(String id, String kind);
}
