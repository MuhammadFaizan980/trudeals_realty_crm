import 'package:dart_either/dart_either.dart';
import 'package:intl/intl.dart';

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

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  Contact _contact(dynamic data) => Contact.fromJson(Map<String, dynamic>.from((data as Map)['contact'] as Map));

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
        'pageSize': 500,
      },
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['contacts'] as List).map((e) => Contact.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
  }

  @override
  Future<NetworkResult<Contact>> getContact(String id) {
    return _client.get(path: '/api/contacts/$id', decoder: _contact);
  }

  @override
  Future<NetworkResult<Contact>> createContact(Contact contact) {
    final data = <String, dynamic>{
      'name': contact.name,
      'phone': contact.phone,
      'email': contact.email,
      'propertyAddress': contact.propertyAddress,
      'source': contact.source,
      'leadType': contact.leadType?.name,
      'plan': contact.plan,
      'stage': contact.stage,
      'dealValue': contact.dealValue,
      'priority': contact.priority.name,
      'assignedTo': contact.assignedTo,
      'followUp': contact.followUp != null ? _dateFmt.format(contact.followUp!) : null,
    }..removeWhere((key, value) => value == null);

    return _client.post(path: '/api/contacts', data: data, decoder: _contact);
  }

  @override
  Future<NetworkResult<Contact>> updateContact(String id, Map<String, dynamic> data) {
    return _client.patch(path: '/api/contacts/$id', data: data, decoder: _contact);
  }

  @override
  Future<NetworkResult<Contact>> updateStage(String id, String stageKey) {
    return _client.post(path: '/api/contacts/$id/stage', data: {'toKey': stageKey}, decoder: _contact);
  }

  @override
  Future<NetworkResult<Contact>> updatePriority(String id, Priority priority) {
    return _client.patch(path: '/api/contacts/$id', data: {'priority': priority.name}, decoder: _contact);
  }

  @override
  Future<NetworkResult<List<Activity>>> getActivities(String contactId) {
    return _client.get(
      path: '/api/contacts/$contactId/activities',
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['activities'] as List).map((e) => Activity.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
  }

  @override
  Future<NetworkResult<List<Communication>>> getCommunications(String contactId) {
    return _client.get(
      path: '/api/contacts/$contactId/comms',
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['comms'] as List).map((e) => Communication.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
  }

  @override
  Future<NetworkResult<List<VendorOrder>>> getVendorOrders(String contactId) async {
    // The real API has no dedicated orders endpoint — orders are embedded on
    // the contact document itself, so we fetch the full profile.
    final result = await getContact(contactId);
    return result.fold(
      ifLeft: (e) => Left(e),
      ifRight: (c) => Right(c.orders.values.toList()),
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
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['contacts'] as List).map((e) => Contact.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
  }

  @override
  Future<NetworkResult<void>> restoreContact(String id) {
    return _client.post(path: '/api/contacts/$id/restore');
  }

  @override
  Future<NetworkResult<Activity>> addActivity(String contactId, {required String type, required String text}) {
    return _client.post(
      path: '/api/contacts/$contactId/activities',
      data: {'type': type, 'text': text},
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return Activity.fromJson(Map<String, dynamic>.from(json['activity'] as Map));
      },
    );
  }

  @override
  Future<NetworkResult<Contact>> transferContact(String id, String toUserId, {String? note}) {
    return _client.post(
      path: '/api/contacts/$id/transfer',
      data: {'toUserId': toUserId, if (note != null && note.isNotEmpty) 'note': note},
      decoder: _contact,
    );
  }

  @override
  Future<NetworkResult<Contact>> addTag(String id, String tag) {
    return _client.post(path: '/api/contacts/$id/tags', data: {'tag': tag}, decoder: _contact);
  }

  @override
  Future<NetworkResult<Contact>> removeTag(String id, String tag) {
    return _client.delete(path: '/api/contacts/$id/tags/${Uri.encodeComponent(tag)}', decoder: _contact);
  }

  @override
  Future<NetworkResult<Contact>> scheduleCallback(
    String id, {
    required DateTime when,
    String? note,
    bool remind15 = true,
    bool remind10 = true,
  }) async {
    final result = await _client.post(
      path: '/api/contacts/$id/callbacks',
      data: {
        'when': when.toIso8601String(),
        if (note != null && note.isNotEmpty) 'note': note,
        'remind15': remind15,
        'remind10': remind10,
      },
      decoder: (data) => data,
    );
    // The endpoint returns just the callback, not the contact — refetch for a consistent shape.
    return result.fold(
      ifLeft: (e) => Left(e),
      ifRight: (_) => getContact(id),
    );
  }

  @override
  Future<NetworkResult<void>> cancelCallback(String callbackId) {
    return _client.delete(path: '/api/callbacks/$callbackId');
  }

  @override
  Future<NetworkResult<Contact>> sendEmail(String id, {String? templateId, String? subject, String? body}) {
    return _client.post(
      path: '/api/contacts/$id/send-email',
      data: {
        if (templateId != null) 'templateId': templateId,
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
      decoder: _contact,
    );
  }

  @override
  Future<NetworkResult<Contact>> sendSms(String id, {String? templateId, String? body}) {
    return _client.post(
      path: '/api/contacts/$id/send-sms',
      data: {
        if (templateId != null) 'templateId': templateId,
        if (body != null) 'body': body,
      },
      decoder: _contact,
    );
  }

  @override
  Future<NetworkResult<Contact>> logReply(String id, {required String channel, required String body}) {
    return _client.post(
      path: '/api/contacts/$id/receive',
      data: {'channel': channel, 'body': body},
      decoder: _contact,
    );
  }

  @override
  Future<NetworkResult<Contact>> placeOrder(String id, String kind, {String? company, DateTime? etaAt, String? notes}) {
    return _client.post(
      path: '/api/contacts/$id/orders/$kind',
      data: {
        if (company != null) 'company': company,
        if (etaAt != null) 'etaAt': etaAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
      decoder: _contact,
    );
  }

  @override
  Future<NetworkResult<Contact>> cancelOrder(String id, String kind) {
    return _client.delete(path: '/api/contacts/$id/orders/$kind', decoder: _contact);
  }
}
