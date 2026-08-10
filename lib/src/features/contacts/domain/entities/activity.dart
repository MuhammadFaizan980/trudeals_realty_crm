class Activity {
  final DateTime timestamp;
  final String type;
  final String text;
  final String? by;

  const Activity({
    required this.timestamp,
    required this.type,
    required this.text,
    this.by,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          type == other.type &&
          text == other.text &&
          by == other.by;

  @override
  int get hashCode =>
      timestamp.hashCode ^ type.hashCode ^ text.hashCode ^ by.hashCode;

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      timestamp: DateTime.parse(json['ts'] as String),
      type: json['type'] as String,
      text: json['text'] as String,
      by: json['by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ts': timestamp.toIso8601String(),
      'type': type,
      'text': text,
      'by': by,
    };
  }
}
