enum TriggerType { tag, form, stage, click }

class Workflow {
  final String id;
  final String name;
  final bool isActive;
  final TriggerType triggerType;
  final String? triggerValue;
  final List<WorkflowStep> steps;

  const Workflow({
    required this.id,
    required this.name,
    this.isActive = true,
    required this.triggerType,
    this.triggerValue,
    this.steps = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workflow &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isActive == other.isActive &&
          triggerType == other.triggerType &&
          triggerValue == other.triggerValue;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      isActive.hashCode ^
      triggerType.hashCode ^
      triggerValue.hashCode;
}

enum StepType { email, sms, wait, addTag, removeTag, notify, ifCond, stopAll }

class WorkflowStep {
  final String id;
  final String workflowId;
  final int stepOrder;
  final StepType type;
  final String? templateId;
  final int? waitAmount;
  final String? waitUnit; // min, hour, day
  final String? tagValue;
  final String? notifyTo;
  final String? notifyText;

  const WorkflowStep({
    required this.id,
    required this.workflowId,
    required this.stepOrder,
    required this.type,
    this.templateId,
    this.waitAmount,
    this.waitUnit,
    this.tagValue,
    this.notifyTo,
    this.notifyText,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowStep &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          stepOrder == other.stepOrder &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ stepOrder.hashCode ^ type.hashCode;
}
