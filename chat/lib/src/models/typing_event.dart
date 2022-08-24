enum Typing { start, stop }

//same as receipt model
extension TypingParser on Typing {
  String value() {
    return this.toString().split('.').last;
  }

  static Typing fromString(String event) {
    return Typing.values.firstWhere((element) => element.value() == event);
  }
}

class TypingEvent {
  final String from;
  final String to;
  final Typing event;
  String id;

  TypingEvent({
    required this.from,
    required this.to,
    required this.event,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'event': event.value(),
        'id': id,
      };

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    var event = TypingEvent(
      from: json['from'],
      to: json['to'],
      event: TypingParser.fromString(json['event']),
      id: json['id'],
    );
    return event;
  }
}
