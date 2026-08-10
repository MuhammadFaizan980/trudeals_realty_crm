import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/entities/workflow.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/repositories/workflow_repository.dart';

class WorkflowState {
  final List<Workflow> workflows;
  final bool isLoading;
  final String? errorMessage;

  const WorkflowState({
    this.workflows = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowState &&
          runtimeType == other.runtimeType &&
          listEquals(workflows, other.workflows) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => workflows.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;

  WorkflowState copyWith({
    List<Workflow>? workflows,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkflowState(
      workflows: workflows ?? this.workflows,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class WorkflowCubit extends Cubit<WorkflowState> {
  final WorkflowRepository _repository;

  WorkflowCubit(this._repository) : super(const WorkflowState());

  Future<void> loadWorkflows() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _repository.getWorkflows();
    result.fold(
      ifLeft: (error) => emit(state.copyWith(isLoading: false, errorMessage: error.message)),
      ifRight: (workflows) => emit(state.copyWith(isLoading: false, workflows: workflows)),
    );
  }

  Future<void> toggleWorkflow(String id, bool active) async {
    final result = await _repository.toggleWorkflow(id, active);
    result.fold(
      ifLeft: (error) => emit(state.copyWith(errorMessage: error.message)),
      ifRight: (updatedWf) {
        final newList = state.workflows.map((wf) => wf.id == id ? updatedWf : wf).toList();
        emit(state.copyWith(workflows: newList));
      },
    );
  }
}
