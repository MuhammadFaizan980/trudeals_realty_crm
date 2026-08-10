import '../../../../core/network/network_typedefs.dart';
import '../entities/workflow.dart';

abstract interface class WorkflowRepository {
  Future<NetworkResult<List<Workflow>>> getWorkflows();
  Future<NetworkResult<Workflow>> getWorkflow(String id);
  Future<NetworkResult<Workflow>> toggleWorkflow(String id, bool active);
}
