class VendorOrder {
  final String? company;
  final DateTime orderedAt;
  final DateTime? eta;
  final String? notes;

  const VendorOrder({
    this.company,
    required this.orderedAt,
    this.eta,
    this.notes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorOrder &&
          runtimeType == other.runtimeType &&
          company == other.company &&
          orderedAt == other.orderedAt &&
          eta == other.eta &&
          notes == other.notes;

  @override
  int get hashCode =>
      company.hashCode ^ orderedAt.hashCode ^ eta.hashCode ^ notes.hashCode;

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      company: json['company'] as String?,
      orderedAt: DateTime.parse(json['orderedAt'] as String),
      eta: json['etaAt'] != null && json['etaAt'] != '' ? DateTime.parse(json['etaAt'] as String) : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'orderedAt': orderedAt.toIso8601String(),
      'etaAt': eta?.toIso8601String(),
      'notes': notes,
    };
  }
}
