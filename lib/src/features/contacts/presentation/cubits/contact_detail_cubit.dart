import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/activity.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/communication.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/vendor_order.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/repositories/contacts_repository.dart';

class ContactDetailState {
  final Contact? contact;
  final List<Activity> activities;
  final List<Communication> communications;
  final List<VendorOrder> orders;
  final bool isLoading;
  final String? errorMessage;

  const ContactDetailState({
    this.contact,
    this.activities = const [],
    this.communications = const [],
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactDetailState &&
          runtimeType == other.runtimeType &&
          contact == other.contact &&
          listEquals(activities, other.activities) &&
          listEquals(communications, other.communications) &&
          listEquals(orders, other.orders) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      contact.hashCode ^
      activities.hashCode ^
      communications.hashCode ^
      orders.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode;

  ContactDetailState copyWith({
    Contact? contact,
    List<Activity>? activities,
    List<Communication>? communications,
    List<VendorOrder>? orders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ContactDetailState(
      contact: contact ?? this.contact,
      activities: activities ?? this.activities,
      communications: communications ?? this.communications,
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ContactDetailCubit extends Cubit<ContactDetailState> {
  final ContactsRepository repository;

  ContactDetailCubit(this.repository) : super(const ContactDetailState());

  Future<void> loadContact(String id) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // The real API returns activities/comms/callbacks/enrollments/orders
    // embedded on the contact document itself — one fetch gets everything.
    final result = await repository.getContact(id);

    result.fold(
      ifLeft: (error) => emit(state.copyWith(isLoading: false, errorMessage: error.message)),
      ifRight: (contact) => emit(state.copyWith(
        isLoading: false,
        contact: contact,
        activities: contact.activities,
        communications: contact.comms,
        orders: contact.orders.values.toList(),
      )),
    );
  }

  /// Runs a mutation against the current contact and reloads on success.
  /// Returns an error message on failure, or null on success, so the caller
  /// can show a SnackBar without conflating action errors with load errors.
  Future<String?> _mutate(Future<NetworkResult<Contact>> Function(String contactId) action) async {
    final contact = state.contact;
    if (contact == null) return 'No contact loaded';
    final result = await action(contact.id);
    String? error;
    result.fold(ifLeft: (e) => error = e.message, ifRight: (_) {});
    if (error == null) await loadContact(contact.id);
    return error;
  }

  Future<String?> updateStage(String stageKey) => _mutate((id) => repository.updateStage(id, stageKey));

  Future<String?> updateFields(Map<String, dynamic> data) => _mutate((id) => repository.updateContact(id, data));

  Future<String?> transfer(String toUserId, {String? note}) =>
      _mutate((id) => repository.transferContact(id, toUserId, note: note));

  Future<String?> addTag(String tag) => _mutate((id) => repository.addTag(id, tag));

  Future<String?> removeTag(String tag) => _mutate((id) => repository.removeTag(id, tag));

  Future<String?> sendEmail({String? templateId, String? subject, String? body}) =>
      _mutate((id) => repository.sendEmail(id, templateId: templateId, subject: subject, body: body));

  Future<String?> sendSms({String? templateId, String? body}) =>
      _mutate((id) => repository.sendSms(id, templateId: templateId, body: body));

  Future<String?> logReply({required String channel, required String body}) =>
      _mutate((id) => repository.logReply(id, channel: channel, body: body));

  Future<String?> placeOrder(String kind, {String? company, DateTime? etaAt, String? notes}) =>
      _mutate((id) => repository.placeOrder(id, kind, company: company, etaAt: etaAt, notes: notes));

  Future<String?> cancelOrder(String kind) => _mutate((id) => repository.cancelOrder(id, kind));

  Future<String?> addNote({required String type, required String text}) async {
    final contact = state.contact;
    if (contact == null) return 'No contact loaded';
    final result = await repository.addActivity(contact.id, type: type, text: text);
    String? error;
    result.fold(ifLeft: (e) => error = e.message, ifRight: (_) {});
    if (error == null) await loadContact(contact.id);
    return error;
  }

  Future<String?> scheduleCallback({required DateTime when, String? note, bool remind15 = true, bool remind10 = true}) async {
    final contact = state.contact;
    if (contact == null) return 'No contact loaded';
    final result = await repository.scheduleCallback(contact.id, when: when, note: note, remind15: remind15, remind10: remind10);
    String? error;
    result.fold(ifLeft: (e) => error = e.message, ifRight: (_) {});
    if (error == null) await loadContact(contact.id);
    return error;
  }

  Future<String?> cancelCallback(String callbackId) async {
    final contact = state.contact;
    if (contact == null) return 'No contact loaded';
    final result = await repository.cancelCallback(callbackId);
    String? error;
    result.fold(ifLeft: (e) => error = e.message, ifRight: (_) {});
    if (error == null) await loadContact(contact.id);
    return error;
  }
}
