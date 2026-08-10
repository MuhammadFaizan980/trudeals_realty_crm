import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/entities/workflow.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/entities/enrollment_summary.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/repositories/workflow_repository.dart';

class WorkflowState {
  final List<Workflow> workflows;
  final List<EnrollmentSummary> activeEnrollments;
  final bool isLoading;
  final String? errorMessage;

  const WorkflowState({
    this.workflows = const [],
    this.activeEnrollments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int activeCountFor(String workflowId) => activeEnrollments.where((e) => e.enrollment.workflowId == workflowId).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowState &&
          runtimeType == other.runtimeType &&
          listEquals(workflows, other.workflows) &&
          listEquals(activeEnrollments, other.activeEnrollments) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => workflows.hashCode ^ activeEnrollments.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;

  WorkflowState copyWith({
    List<Workflow>? workflows,
    List<EnrollmentSummary>? activeEnrollments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkflowState(
      workflows: workflows ?? this.workflows,
      activeEnrollments: activeEnrollments ?? this.activeEnrollments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WorkflowCubit extends Cubit<WorkflowState> {
  final WorkflowRepository _repository;

  WorkflowCubit(this._repository) : super(const WorkflowState());

  Future<void> loadWorkflows() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final results = await Future.wait([_repository.getWorkflows(), _repository.getActiveEnrollments()]);

    List<Workflow>? workflows;
    List<EnrollmentSummary>? enrollments;
    String? error;

    results[0].fold(
      ifLeft: (e) => error = e.message,
      ifRight: (w) => workflows = w as List<Workflow>,
    );
    results[1].fold(
      ifLeft: (e) => error ??= e.message,
      ifRight: (en) => enrollments = en as List<EnrollmentSummary>,
    );

    emit(state.copyWith(
      isLoading: false,
      workflows: workflows ?? state.workflows,
      activeEnrollments: enrollments ?? state.activeEnrollments,
      errorMessage: error,
    ));
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

  Future<String?> deleteWorkflow(String id) async {
    final result = await _repository.deleteWorkflow(id);
    String? error;
    result.fold(ifLeft: (e) => error = e.message, ifRight: (_) {});
    if (error == null) await loadWorkflows();
    return error;
  }

  Future<String?> stopEnrollment(String enrollmentId) async {
    final result = await _repository.stopEnrollment(enrollmentId);
    String? error;
    result.fold(ifLeft: (e) => error = e.message, ifRight: (_) {});
    if (error == null) await loadWorkflows();
    return error;
  }

  Future<String?> runEnrollmentNext(String enrollmentId) async {
    final result = await _repository.runEnrollmentNext(enrollmentId);
    String? error;
    result.fold(ifLeft: (e) => error = e.message, ifRight: (_) {});
    if (error == null) await loadWorkflows();
    return error;
  }
}
