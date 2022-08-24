import 'package:chat/chat.dart';

import 'local_message.dart';

class Chat {
  String id;
  int unread = 0;
  List<LocalMessage>? messages = [];
  LocalMessage? mostRecent;
  User? from;
  Chat(this.id, {this.messages, this.mostRecent, this.from});

  toMap() => {'id': id};
  factory Chat.fromMap(Map<String, dynamic> json) => Chat(json['id']);
}
