/// A contact's progress through a single workflow run.
class Enrollment {
  final String id;
  final String workflowId;
  final int stepIndex;
  final DateTime enrolledAt;
  final DateTime nextAt;
  final bool done;

  const Enrollment({
    required this.id,
    required this.workflowId,
    required this.stepIndex,
    required this.enrolledAt,
    required this.nextAt,
    this.done = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Enrollment && runtimeType == other.runtimeType && id == other.id && stepIndex == other.stepIndex && done == other.done;

  @override
  int get hashCode => id.hashCode ^ stepIndex.hashCode ^ done.hashCode;

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'].toString(),
      workflowId: (json['wfId'] ?? json['workflowId']).toString(),
      stepIndex: json['stepIndex'] as int? ?? 0,
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      nextAt: DateTime.parse(json['nextAt'] as String),
      done: json['done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wfId': workflowId,
      'stepIndex': stepIndex,
      'enrolledAt': enrolledAt.toIso8601String(),
      'nextAt': nextAt.toIso8601String(),
      'done': done,
    };
  }
}
