class CallbackEvent {
  final String id;
  final String contactId;
  final String contactName;
  final DateTime scheduledAt;
  final String? note;

  const CallbackEvent({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.scheduledAt,
    this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallbackEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contactId == other.contactId &&
          scheduledAt == other.scheduledAt &&
          note == other.note;

  @override
  int get hashCode => id.hashCode ^ contactId.hashCode ^ scheduledAt.hashCode ^ note.hashCode;
}
