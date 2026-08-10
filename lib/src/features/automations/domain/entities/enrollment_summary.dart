import '../../../contacts/domain/entities/enrollment.dart';

/// "Contacts currently in sequences" row — pairs an [Enrollment] with the
/// contact/workflow names the list view needs, matching what
/// `GET /api/enrollments` returns.
class EnrollmentSummary {
  final String contactId;
  final String contactName;
  final String workflowName;
  final Enrollment enrollment;

  const EnrollmentSummary({
    required this.contactId,
    required this.contactName,
    required this.workflowName,
    required this.enrollment,
  });

  factory EnrollmentSummary.fromJson(Map<String, dynamic> json) {
    return EnrollmentSummary(
      contactId: json['contactId']?.toString() ?? '',
      contactName: json['contactName']?.toString() ?? '',
      workflowName: json['workflowName']?.toString() ?? '',
      enrollment: Enrollment.fromJson(Map<String, dynamic>.from(json['enrollment'] as Map)),
    );
  }
}
