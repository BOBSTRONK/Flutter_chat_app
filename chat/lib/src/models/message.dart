class Message {
  late final String from;
  late final String to;
  late final DateTime timestamp;
  late final String contents;
  late String id;

  Message({
    required this.from,
    required this.to,
    required this.timestamp,
    required this.contents,
    required this.id,
  });

  String getId() {
    return this.id;
  }

  toJson() => {
        'from': this.from,
        'to': this.to,
        'timestamp': this.timestamp,
        'contents': this.contents,
        'id': this.id,
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    var message = Message(
        from: json['from'],
        to: json['to'],
        contents: json['contents'],
        timestamp: json['timestamp'],
        id: json['id']);
    return message;
  }
}
