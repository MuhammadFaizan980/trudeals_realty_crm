/// A scheduled call back on a contact, with 15/10-minute reminder flags.
class Callback {
  final String id;
  final DateTime when;
  final String? note;
  final List<int> reminders;
  final Map<String, bool> notified;

  const Callback({
    required this.id,
    required this.when,
    this.note,
    this.reminders = const [],
    this.notified = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Callback && runtimeType == other.runtimeType && id == other.id && when == other.when && note == other.note;

  @override
  int get hashCode => id.hashCode ^ when.hashCode ^ note.hashCode;

  factory Callback.fromJson(Map<String, dynamic> json) {
    return Callback(
      id: json['id'].toString(),
      when: DateTime.parse(json['when'] as String),
      note: json['note'] as String?,
      reminders: (json['reminders'] as List?)?.map((e) => e as int).toList() ?? const [],
      notified: json['notified'] != null
          ? Map<String, bool>.from((json['notified'] as Map).map((k, v) => MapEntry(k.toString(), v as bool)))
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'when': when.toIso8601String(),
      'note': note,
      'reminders': reminders,
      'notified': notified,
    };
  }
}
