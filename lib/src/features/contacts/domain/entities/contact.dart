import 'package:flutter/foundation.dart';

import 'activity.dart';
import 'callback.dart';
import 'communication.dart';
import 'enrollment.dart';
import 'vendor_order.dart';

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
  final DateTime? linkClickedAt;
  final DateTime? lastInboundAt;
  final DateTime createdAt;
  final String? notes;
  final List<String> tags;
  final bool deleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// Embedded on the profile document itself — the real API returns these
  /// inline rather than through separate sub-resource fetches.
  final List<Activity> activities;
  final List<Communication> comms;
  final List<Callback> callbacks;
  final List<Enrollment> enrollments;
  final Map<String, VendorOrder> orders;

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
    this.linkClickedAt,
    this.lastInboundAt,
    required this.createdAt,
    this.notes,
    this.tags = const [],
    this.deleted = false,
    this.deletedAt,
    this.deletedBy,
    this.activities = const [],
    this.comms = const [],
    this.callbacks = const [],
    this.enrollments = const [],
    this.orders = const {},
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
          notes == other.notes &&
          listEquals(tags, other.tags) &&
          deleted == other.deleted &&
          deletedAt == other.deletedAt &&
          listEquals(activities, other.activities) &&
          listEquals(comms, other.comms) &&
          listEquals(callbacks, other.callbacks) &&
          listEquals(enrollments, other.enrollments);

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
      notes.hashCode ^
      tags.hashCode ^
      deleted.hashCode ^
      deletedAt.hashCode;

  factory Contact.fromJson(Map<String, dynamic> json) {
    final ordersJson = json['orders'] is Map ? Map<String, dynamic>.from(json['orders'] as Map) : const <String, dynamic>{};
    final orders = <String, VendorOrder>{};
    ordersJson.forEach((kind, value) {
      if (value is Map) orders[kind] = VendorOrder.fromJson(Map<String, dynamic>.from(value));
    });

    return Contact(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      propertyAddress: json['propertyAddress']?.toString(),
      source: json['source']?.toString(),
      leadType: json['leadType'] != null
          ? LeadType.values.firstWhere((e) => e.name == json['leadType'], orElse: () => LeadType.seller)
          : null,
      plan: json['plan']?.toString() ?? 'undecided',
      stage: json['stage']?.toString() ?? 'new',
      dealValue: (json['dealValue'] as num?)?.toDouble() ?? 0.0,
      priority: Priority.values.firstWhere((e) => e.name == (json['priority'] ?? 'med'), orElse: () => Priority.med),
      assignedTo: json['assignedTo']?.toString(),
      followUp: json['followUp'] != null ? DateTime.tryParse(json['followUp'].toString()) : null,
      linkClickedAt: json['linkClickedAt'] != null ? DateTime.tryParse(json['linkClickedAt'].toString()) : null,
      lastInboundAt: json['lastInboundAt'] != null ? DateTime.tryParse(json['lastInboundAt'].toString()) : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes']?.toString(),
      tags: List<String>.from(json['tags'] ?? const []),
      deleted: json['deleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
      deletedBy: json['deletedBy']?.toString(),
      activities: (json['activities'] as List?)
              ?.map((e) => Activity.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      comms: (json['comms'] as List?)
              ?.map((e) => Communication.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      callbacks: (json['callbacks'] as List?)
              ?.map((e) => Callback.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      enrollments: (json['enrollments'] as List?)
              ?.map((e) => Enrollment.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      orders: orders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'propertyAddress': propertyAddress,
      'source': source,
      'leadType': leadType?.name,
      'plan': plan,
      'stage': stage,
      'dealValue': dealValue,
      'priority': priority.name,
      'assignedTo': assignedTo,
      'followUp': followUp?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'tags': tags,
      'deleted': deleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
