import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/activity.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/communication.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/vendor_order.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/repositories/contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final NetworkClient _client;

  ContactsRepositoryImpl(this._client);

  @override
  Future<NetworkResult<List<Contact>>> getContacts({
    String? query,
    String? stageKey,
    String? assignedTo,
  }) {
    return _client.get(
      path: '/api/contacts',
      queryParameters: {
        'q': query,
        'stage': stageKey,
        'assigned': assignedTo,
      },
      decoder: (data) => (data as List).map((e) => Contact.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  @override
  Future<NetworkResult<Contact>> getContact(String id) {
    return _client.get(
      path: '/api/contacts/$id',
      decoder: (data) => Contact.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<NetworkResult<Contact>> createContact(Contact contact) {
    return _client.post(
      path: '/api/contacts',
      data: contact.toJson(),
      decoder: (data) => Contact.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<NetworkResult<Contact>> updateContact(String id, Map<String, dynamic> data) {
    return _client.patch(
      path: '/api/contacts/$id',
      data: data,
      decoder: (data) => Contact.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<NetworkResult<Contact>> updateStage(String id, String stageKey) {
    return _client.post(
      path: '/api/contacts/$id/stage',
      data: {'stage': stageKey},
      decoder: (data) => Contact.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<NetworkResult<Contact>> updatePriority(String id, Priority priority) {
    return _client.patch(
      path: '/api/contacts/$id',
      data: {'priority': priority.name},
      decoder: (data) => Contact.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<NetworkResult<List<Activity>>> getActivities(String contactId) {
    return _client.get(
      path: '/api/contacts/$contactId/activities',
      decoder: (data) => (data as List).map((e) => Activity.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  @override
  Future<NetworkResult<List<Communication>>> getCommunications(String contactId) {
    return _client.get(
      path: '/api/contacts/$contactId/comms',
      decoder: (data) => (data as List).map((e) => Communication.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  @override
  Future<NetworkResult<List<VendorOrder>>> getVendorOrders(String contactId) {
    return _client.get(
      path: '/api/contacts/$contactId/orders',
      decoder: (data) => (data as Map).values.map((e) => VendorOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  @override
  Future<NetworkResult<void>> deleteContact(String id) {
    return _client.delete(path: '/api/contacts/$id');
  }

  @override
  Future<NetworkResult<List<Contact>>> getTrash() {
    return _client.get(
      path: '/api/trash',
      decoder: (data) => (data as List).map((e) => Contact.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  @override
  Future<NetworkResult<void>> restoreContact(String id) {
    return _client.post(path: '/api/contacts/$id/restore');
  }
}
