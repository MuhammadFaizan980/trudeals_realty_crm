import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/usecases/update_contact_stage_usecase.dart';

class PipelineState {
  final List<Contact> contacts;
  final bool isLoading;
  final String? errorMessage;

  const PipelineState({
    this.contacts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineState &&
          runtimeType == other.runtimeType &&
          listEquals(contacts, other.contacts) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => contacts.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;

  PipelineState copyWith({
    List<Contact>? contacts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PipelineState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PipelineCubit extends Cubit<PipelineState> {
  final GetContactsUseCase _getContactsUseCase;
  final UpdateContactStageUseCase _updateContactStageUseCase;

  PipelineCubit(this._getContactsUseCase, this._updateContactStageUseCase) : super(const PipelineState());

  Future<void> loadContacts() async {
    debugPrint('PipelineCubit: loadContacts starting...');
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      final result = await _getContactsUseCase().timeout(const Duration(seconds: 5));
      result.fold(
        ifLeft: (error) {
          debugPrint('PipelineCubit: loadContacts Error: ${error.message}');
          emit(state.copyWith(isLoading: false, errorMessage: error.message));
        },
        ifRight: (contacts) {
          debugPrint('PipelineCubit: loadContacts Success: ${contacts.length} items');
          emit(state.copyWith(isLoading: false, contacts: contacts));
        },
      );
    } catch (e, stack) {
      debugPrint('PipelineCubit: loadContacts Exception: $e\n$stack');
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load pipeline: $e'));
    }
  }

  Future<void> moveContact(String id, String stageKey) async {
    final result = await _updateContactStageUseCase(id, stageKey);
    result.fold(
      ifLeft: (error) => emit(state.copyWith(errorMessage: error.message)),
      ifRight: (updatedContact) {
        final List<Contact> newContacts = state.contacts.map((c) => c.id == id ? updatedContact : c).toList();
        emit(state.copyWith(contacts: newContacts));
      },
    );
  }
}
