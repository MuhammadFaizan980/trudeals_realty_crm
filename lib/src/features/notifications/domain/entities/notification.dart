class AppNotification {
  final String id;
  final String text;
  final String? contactId;
  final DateTime ts;
  final bool read;

  const AppNotification({
    required this.id,
    required this.text,
    this.contactId,
    required this.ts,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? json['_id']).toString(),
      text: json['text']?.toString() ?? '',
      contactId: json['contactId']?.toString(),
      ts: DateTime.parse(json['ts'] as String),
      read: json['read'] as bool? ?? false,
    );
  }
}
