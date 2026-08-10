import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/entities/workflow.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/repositories/workflow_repository.dart';

class WorkflowRepositoryImpl implements WorkflowRepository {
  final NetworkClient _client;

  WorkflowRepositoryImpl(this._client);

  @override
  Future<NetworkResult<List<Workflow>>> getWorkflows() {
    return _client.get(
      path: '/api/workflows',
      decoder: (data) => (data as List).map((e) => _parseWorkflow(e)).toList(),
    );
  }

  @override
  Future<NetworkResult<Workflow>> getWorkflow(String id) {
    return _client.get(
      path: '/api/workflows/$id',
      decoder: (data) => _parseWorkflow(data),
    );
  }

  @override
  Future<NetworkResult<Workflow>> toggleWorkflow(String id, bool active) {
    return _client.patch(
      path: '/api/workflows/$id',
      data: {'active': active},
      decoder: (data) => _parseWorkflow(data),
    );
  }

  Workflow _parseWorkflow(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    final trigger = json['trigger'] != null ? Map<String, dynamic>.from(json['trigger'] as Map) : null;
    
    return Workflow(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Workflow',
      isActive: json['active'] as bool? ?? json['isActive'] as bool? ?? true,
      triggerType: _parseTriggerType(trigger?['type']?.toString() ?? 'tag'),
      triggerValue: trigger?['value']?.toString(),
      steps: (json['steps'] as List?)?.map((s) => _parseStep(s)).toList() ?? [],
    );
  }

  WorkflowStep _parseStep(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    return WorkflowStep(
      id: json['id']?.toString() ?? '',
      workflowId: json['workflow_id']?.toString() ?? '',
      stepOrder: json['step_order'] as int? ?? 0,
      type: _parseStepType(json['type']?.toString() ?? 'email'),
      templateId: json['tpl']?.toString() ?? json['template_id']?.toString(),
      waitAmount: json['amount'] as int? ?? json['wait_amount'] as int?,
      waitUnit: json['unit']?.toString() ?? json['wait_unit']?.toString(),
      tagValue: json['value']?.toString() ?? json['tag_value']?.toString(),
      notifyTo: json['value']?.toString() ?? json['notify_to']?.toString(),
      notifyText: json['text']?.toString() ?? json['notify_text']?.toString(),
    );
  }

  TriggerType _parseTriggerType(String type) {
    return TriggerType.values.firstWhere((e) => e.name == type, orElse: () => TriggerType.tag);
  }

  StepType _parseStepType(String type) {
    final mappedType = switch(type) {
      'add_tag' => 'addTag',
      'remove_tag' => 'removeTag',
      'if' => 'ifCond',
      'stop_all' => 'stopAll',
      _ => type,
    };
    return StepType.values.firstWhere((e) => e.name == mappedType, orElse: () => StepType.email);
  }
}
