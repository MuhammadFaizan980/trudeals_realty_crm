import 'package:flutter/foundation.dart';

enum Priority { high, med, low }
enum LeadType { seller, buyer, cma }

class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? propertyAddress;
  final String? source;
  final LeadType? leadType;
  final String plan;
  final String stage;
  final double dealValue;
  final Priority priority;
  final String? assignedTo;
  final DateTime? followUp;
  final DateTime createdAt;
  final List<String> tags;
  final bool deleted;
  final DateTime? deletedAt;

  const Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.propertyAddress,
    this.source,
    this.leadType,
    required this.plan,
    required this.stage,
    this.dealValue = 0,
    this.priority = Priority.med,
    this.assignedTo,
    this.followUp,
    required this.createdAt,
    this.tags = const [],
    this.deleted = false,
    this.deletedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          email == other.email &&
          propertyAddress == other.propertyAddress &&
          source == other.source &&
          leadType == other.leadType &&
          plan == other.plan &&
          stage == other.stage &&
          dealValue == other.dealValue &&
          priority == other.priority &&
          assignedTo == other.assignedTo &&
          followUp == other.followUp &&
          createdAt == other.createdAt &&
          listEquals(tags, other.tags) &&
          deleted == other.deleted &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      propertyAddress.hashCode ^
      source.hashCode ^
      leadType.hashCode ^
      plan.hashCode ^
      stage.hashCode ^
      dealValue.hashCode ^
      priority.hashCode ^
      assignedTo.hashCode ^
      followUp.hashCode ^
      createdAt.hashCode ^
      tags.hashCode ^
      deleted.hashCode ^
      deletedAt.hashCode;

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      propertyAddress: (json['property_address'] ?? json['propertyAddress'])?.toString(),
      source: json['source']?.toString(),
      leadType: json['leadType'] != null ? LeadType.values.firstWhere((e) => e.name == json['leadType'], orElse: () => LeadType.seller) : null,
      plan: json['plan']?.toString() ?? 'undecided',
      stage: json['stage']?.toString() ?? 'new',
      dealValue: (json['dealValue'] as num?)?.toDouble() ?? 0.0,
      priority: Priority.values.firstWhere((e) => e.name == (json['priority'] ?? 'med'), orElse: () => Priority.med),
      assignedTo: json['assignedTo']?.toString(),
      followUp: json['followUp'] != null ? DateTime.tryParse(json['followUp'].toString()) : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
      deleted: json['deleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'property_address': propertyAddress,
      'source': source,
      'leadType': leadType?.name,
      'plan': plan,
      'stage': stage,
      'dealValue': dealValue,
      'priority': priority.name,
      'assignedTo': assignedTo,
      'followUp': followUp?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'deleted': deleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
