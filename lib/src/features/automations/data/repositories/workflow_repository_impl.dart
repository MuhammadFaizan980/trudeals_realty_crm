import 'package:dart_either/dart_either.dart';

import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_exception.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/entities/workflow.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/entities/enrollment_summary.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/repositories/workflow_repository.dart';

class WorkflowRepositoryImpl implements WorkflowRepository {
  final NetworkClient _client;

  WorkflowRepositoryImpl(this._client);

  Workflow _decodeWorkflow(dynamic data, {String key = 'workflow'}) {
    final json = Map<String, dynamic>.from(data as Map);
    return Workflow.fromJson(Map<String, dynamic>.from(json[key] as Map));
  }

  @override
  Future<NetworkResult<List<Workflow>>> getWorkflows() {
    return _client.get(
      path: '/api/workflows',
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['workflows'] as List).map((e) => Workflow.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
  }

  @override
  Future<NetworkResult<Workflow>> getWorkflow(String id) async {
    // No single-workflow GET endpoint exists — list + find.
    final result = await getWorkflows();
    List<Workflow>? workflows;
    NetworkException? error;
    result.fold(ifLeft: (e) => error = e, ifRight: (w) => workflows = w);
    if (error != null) return Left(error!);

    final match = workflows!.where((w) => w.id == id).cast<Workflow?>().firstWhere((w) => w != null, orElse: () => null);
    if (match == null) return Left(const BadRequestException(message: 'Workflow not found'));
    return Right(match);
  }

  @override
  Future<NetworkResult<Workflow>> toggleWorkflow(String id, bool active) {
    return _client.patch(
      path: '/api/workflows/$id',
      data: {'active': active},
      decoder: (data) => _decodeWorkflow(data),
    );
  }

  @override
  Future<NetworkResult<Workflow>> createWorkflow(Workflow workflow) {
    return _client.post(path: '/api/workflows', data: workflow.toJson(), decoder: (data) => _decodeWorkflow(data));
  }

  @override
  Future<NetworkResult<Workflow>> updateWorkflow(Workflow workflow) {
    return _client.patch(path: '/api/workflows/${workflow.id}', data: workflow.toJson(), decoder: (data) => _decodeWorkflow(data));
  }

  @override
  Future<NetworkResult<void>> deleteWorkflow(String id) {
    return _client.delete(path: '/api/workflows/$id');
  }

  @override
  Future<NetworkResult<List<EnrollmentSummary>>> getActiveEnrollments() {
    return _client.get(
      path: '/api/enrollments',
      queryParameters: {'active': '1'},
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['enrollments'] as List)
            .map((e) => EnrollmentSummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }

  @override
  Future<NetworkResult<void>> stopEnrollment(String enrollmentId) {
    return _client.post(path: '/api/enrollments/$enrollmentId/stop');
  }

  @override
  Future<NetworkResult<void>> runEnrollmentNext(String enrollmentId) {
    return _client.post(path: '/api/enrollments/$enrollmentId/run-next');
  }
}
