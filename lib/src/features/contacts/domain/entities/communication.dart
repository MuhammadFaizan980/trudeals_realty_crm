enum CommChannel { email, sms }
enum CommDirection { inbound, outbound }

class Communication {
  final DateTime timestamp;
  final CommChannel channel;
  final CommDirection direction;
  final String? subject;
  final String body;
  final bool isAutomated;
  final String? by;
  final String? twilioSid;
  final String? emailMsgId;

  const Communication({
    required this.timestamp,
    required this.channel,
    required this.direction,
    this.subject,
    required this.body,
    this.isAutomated = false,
    this.by,
    this.twilioSid,
    this.emailMsgId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Communication &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          channel == other.channel &&
          direction == other.direction &&
          subject == other.subject &&
          body == other.body &&
          isAutomated == other.isAutomated &&
          by == other.by;

  @override
  int get hashCode =>
      timestamp.hashCode ^
      channel.hashCode ^
      direction.hashCode ^
      subject.hashCode ^
      body.hashCode ^
      isAutomated.hashCode ^
      by.hashCode;

  factory Communication.fromJson(Map<String, dynamic> json) {
    return Communication(
      timestamp: DateTime.parse(json['ts'] as String),
      channel: json['channel'] == 'email' ? CommChannel.email : CommChannel.sms,
      direction: json['direction'] == 'in' ? CommDirection.inbound : CommDirection.outbound,
      subject: json['subject'] as String?,
      body: json['body'] as String,
      isAutomated: json['automated'] as bool? ?? false,
      by: json['by'] as String?,
      twilioSid: json['twilioSid'] as String?,
      emailMsgId: json['emailMsgId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ts': timestamp.toIso8601String(),
      'channel': channel.name,
      'direction': direction == CommDirection.inbound ? 'in' : 'out',
      'subject': subject,
      'body': body,
      'automated': isAutomated,
      'by': by,
      'twilioSid': twilioSid,
      'emailMsgId': emailMsgId,
    };
  }
}
