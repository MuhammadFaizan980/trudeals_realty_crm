import '../../../../core/network/network_typedefs.dart';
import '../entities/workflow.dart';
import '../entities/enrollment_summary.dart';

abstract interface class WorkflowRepository {
  Future<NetworkResult<List<Workflow>>> getWorkflows();
  Future<NetworkResult<Workflow>> getWorkflow(String id);
  Future<NetworkResult<Workflow>> toggleWorkflow(String id, bool active);
  Future<NetworkResult<Workflow>> createWorkflow(Workflow workflow);
  Future<NetworkResult<Workflow>> updateWorkflow(Workflow workflow);
  Future<NetworkResult<void>> deleteWorkflow(String id);

  Future<NetworkResult<List<EnrollmentSummary>>> getActiveEnrollments();
  Future<NetworkResult<void>> stopEnrollment(String enrollmentId);
  Future<NetworkResult<void>> runEnrollmentNext(String enrollmentId);
}
