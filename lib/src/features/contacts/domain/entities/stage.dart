import 'package:flutter/foundation.dart';

class Stage {
  final String key;
  final String label;
  final List<String> roles;
  final int sortOrder;

  const Stage({
    required this.key,
    required this.label,
    required this.roles,
    required this.sortOrder,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stage &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          label == other.label &&
          listEquals(roles, other.roles) &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => key.hashCode ^ label.hashCode ^ roles.hashCode ^ sortOrder.hashCode;

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      key: json['key'] as String,
      label: json['label'] as String,
      roles: List<String>.from(json['roles'] as List),
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'roles': roles,
      'sort_order': sortOrder,
    };
  }
}
