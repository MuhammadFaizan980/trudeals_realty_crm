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

  factory Workflow.fromJson(Map<String, dynamic> json) {
    final trigger = json['trigger'] != null ? Map<String, dynamic>.from(json['trigger'] as Map) : null;
    return Workflow(
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name']?.toString() ?? 'Untitled Workflow',
      isActive: json['active'] as bool? ?? true,
      triggerType: _parseTriggerType(trigger?['type']?.toString() ?? 'tag'),
      triggerValue: trigger?['value']?.toString(),
      steps: (json['steps'] as List?)?.map((s) => WorkflowStep.fromJson(Map<String, dynamic>.from(s as Map))).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'active': isActive,
      'trigger': {'type': triggerType.name, 'value': triggerValue ?? ''},
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }

  static TriggerType _parseTriggerType(String type) {
    return TriggerType.values.firstWhere((e) => e.name == type, orElse: () => TriggerType.tag);
  }
}

enum StepType { email, sms, wait, addTag, removeTag, notify, ifCond, stopAll }

/// `cond` values for `ifCond` steps.
enum IfCondition { noReply, hasTag, clicked }

class WorkflowStep {
  final String id;
  final StepType type;
  final String? templateId;
  final int? waitAmount;
  final String? waitUnit; // min, hour, day
  /// add_tag/remove_tag value, notify target ('owner'|'sales'|'support'|'super'), or if(has_tag) value.
  final String? value;
  final String? notifyText;
  final String? cond; // no_reply | has_tag | clicked
  final String? ifFalse; // stop | skip

  const WorkflowStep({
    required this.id,
    required this.type,
    this.templateId,
    this.waitAmount,
    this.waitUnit,
    this.value,
    this.notifyText,
    this.cond,
    this.ifFalse,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkflowStep && runtimeType == other.runtimeType && id == other.id && type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      id: json['id']?.toString() ?? '',
      type: _parseStepType(json['type']?.toString() ?? 'email'),
      templateId: json['tpl']?.toString(),
      waitAmount: json['amount'] as int?,
      waitUnit: json['unit']?.toString(),
      value: json['value']?.toString(),
      notifyText: json['text']?.toString(),
      cond: json['cond']?.toString(),
      ifFalse: json['ifFalse']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _stepTypeKey(type),
      'tpl': templateId,
      'amount': waitAmount,
      'unit': waitUnit,
      'value': value,
      'text': notifyText,
      'cond': cond,
      'ifFalse': ifFalse,
    };
  }

  static StepType _parseStepType(String type) {
    final mappedType = switch (type) {
      'add_tag' => 'addTag',
      'remove_tag' => 'removeTag',
      'if' => 'ifCond',
      'stop_all' => 'stopAll',
      _ => type,
    };
    return StepType.values.firstWhere((e) => e.name == mappedType, orElse: () => StepType.email);
  }

  static String _stepTypeKey(StepType type) {
    return switch (type) {
      StepType.addTag => 'add_tag',
      StepType.removeTag => 'remove_tag',
      StepType.ifCond => 'if',
      StepType.stopAll => 'stop_all',
      _ => type.name,
    };
  }
}
