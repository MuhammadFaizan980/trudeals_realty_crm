import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ContactDetailCubit extends Cubit<ContactDetailState> {
  final ContactsRepository repository; 

  ContactDetailCubit(this.repository) : super(const ContactDetailState());

  Future<void> loadContact(String id) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    final results = await Future.wait([
      repository.getContact(id),
      repository.getActivities(id),
      repository.getCommunications(id),
      repository.getVendorOrders(id),
    ]);

    final contactResult = results[0];
    final activitiesResult = results[1];
    final commsResult = results[2];
    final ordersResult = results[3];

    Contact? contact;
    List<Activity> activities = [];
    List<Communication> communications = [];
    List<VendorOrder> orders = [];
    String? error;

    (contactResult as dynamic).fold(ifLeft: (e) => error = (e as dynamic).message, ifRight: (c) => contact = c);
    (activitiesResult as dynamic).fold(ifLeft: (e) => error ??= (e as dynamic).message, ifRight: (a) => activities = a);
    (commsResult as dynamic).fold(ifLeft: (e) => error ??= (e as dynamic).message, ifRight: (c) => communications = c);
    (ordersResult as dynamic).fold(
      ifLeft: (e) => error ??= (e as dynamic).message, 
      ifRight: (o) => orders = (o as List).map((v) => VendorOrder.fromJson(Map<String, dynamic>.from(v as Map))).toList()
    );

    emit(state.copyWith(
      isLoading: false,
      contact: contact,
      activities: activities,
      communications: communications,
      orders: orders,
      errorMessage: error,
    ));
  }

  Future<void> updateStage(String stageKey) async {
    final contact = state.contact;
    if (contact == null) return;

    final result = await repository.updateStage(contact.id, stageKey);
    result.fold(
      ifLeft: (e) => emit(state.copyWith(errorMessage: e.message)),
      ifRight: (updated) => loadContact(updated.id),
    );
  }
}
