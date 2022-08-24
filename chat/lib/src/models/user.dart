import 'dart:convert';

class User {
  late String username;
  late String photoUrl;
  late String id;
  late bool active;
  late DateTime lastseen;

  User({
    required this.username,
    required this.photoUrl,
    required this.active,
    required this.lastseen,
    required this.id,
  });

  String getId() {
    return this.id;
  }

  toJson() => {
        'username': username,
        'photo_url': photoUrl,
        'active': active,
        "last_seen": lastseen,
        "id": id,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
      username: json["username"],
      photoUrl: json['photo_url'],
      active: json['active'],
      lastseen: json['last_seen'],
      id: json['id'],
    );
    return user;
  }
}
