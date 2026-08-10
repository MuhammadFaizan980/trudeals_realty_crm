import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/stage.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/usecases/update_contact_stage_usecase.dart';
import 'package:trudeals_realty_crm/src/features/settings/domain/repositories/settings_repository.dart';

class PipelineState {
  final List<Contact> contacts;
  final List<Stage> stages;
  final List<User> users;
  final bool isLoading;
  final String? errorMessage;

  const PipelineState({
    this.contacts = const [],
    this.stages = const [],
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Resolves a seat id (e.g. "u-sam") to its display name, falling back to
  /// the raw id if the seat list hasn't loaded yet or the id is unknown.
  String userName(String? id) {
    if (id == null || id.isEmpty) return 'Unassigned';
    for (final u in users) {
      if (u.id == id) return u.name;
    }
    return id;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineState &&
          runtimeType == other.runtimeType &&
          listEquals(contacts, other.contacts) &&
          listEquals(stages, other.stages) &&
          listEquals(users, other.users) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => contacts.hashCode ^ stages.hashCode ^ users.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;

  PipelineState copyWith({
    List<Contact>? contacts,
    List<Stage>? stages,
    List<User>? users,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PipelineState(
      contacts: contacts ?? this.contacts,
      stages: stages ?? this.stages,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Shared, app-lifetime source of truth for the contacts list + pipeline
/// stages + seats. Registered as a singleton and provided once above
/// HomePage's IndexedStack so Pipeline, Contacts, Dashboard segments, and the
/// contact drawer all see the same data and the same refreshes — previously
/// each screen created its own factory-scoped instance, so a stage move in
/// Pipeline never showed up in Contacts (and vice versa) without a restart.
class PipelineCubit extends Cubit<PipelineState> {
  final GetContactsUseCase _getContactsUseCase;
  final UpdateContactStageUseCase _updateContactStageUseCase;
  final SettingsRepository _settingsRepository;

  PipelineCubit(this._getContactsUseCase, this._updateContactStageUseCase, this._settingsRepository)
      : super(const PipelineState());

  Future<void> loadContacts() async {
    debugPrint('PipelineCubit: loadContacts starting...');
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final results = await Future.wait([
        _getContactsUseCase(),
        _settingsRepository.getStages(),
        _settingsRepository.getUsers(),
      ]);

      final contactsResult = results[0];
      final stagesResult = results[1];
      final usersResult = results[2];

      List<Contact>? contacts;
      List<Stage>? stages;
      List<User>? users;
      String? error;

      contactsResult.fold(
        ifLeft: (e) => error = e.message,
        ifRight: (c) => contacts = c as List<Contact>,
      );
      stagesResult.fold(
        ifLeft: (e) => error ??= e.message,
        ifRight: (s) => stages = (s as List<Stage>)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
      usersResult.fold(
        ifLeft: (e) => error ??= e.message,
        ifRight: (u) => users = u as List<User>,
      );

      emit(state.copyWith(
        isLoading: false,
        contacts: contacts ?? state.contacts,
        stages: stages ?? state.stages,
        users: users ?? state.users,
        errorMessage: error,
      ));
    } catch (e, stack) {
      debugPrint('PipelineCubit: loadContacts Exception: $e\n$stack');
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load pipeline: $e'));
    }
  }

  /// Re-fetches everything. Call after any mutation elsewhere in the app
  /// (create/edit/delete/restore/transfer/stage-move/tag) so every screen
  /// reading this cubit updates together.
  Future<void> refresh() => loadContacts();

  Future<String?> moveContact(String id, String stageKey) async {
    final result = await _updateContactStageUseCase(id, stageKey);
    String? error;
    result.fold(
      ifLeft: (e) => error = e.message,
      ifRight: (updatedContact) {
        final List<Contact> newContacts = state.contacts.map((c) => c.id == id ? updatedContact : c).toList();
        emit(state.copyWith(contacts: newContacts));
      },
    );
    return error;
  }
}
