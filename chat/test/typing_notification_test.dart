import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:uuid/uuid.dart' as Uuid;

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late TypingNotification sut;
  late Uuid.Uuid uuid;

  setUp(() async {
    connection = await r.connect();
    await createDb(r, connection);
    sut = TypingNotification(r, connection);
    uuid = Uuid.Uuid();
  });

  tearDown(() async {
    //sut.dispose();
    //await cleanDb(r, connection);
  });

  final user = User.fromJson({
    'username': 'test',
    'photo_url': 'url',
    'id': '1234',
    'active': true,
    'last_seen': DateTime.now(),
  });

  final user2 = User.fromJson({
    'username': 'test',
    'photo_url': 'url',
    'id': '4321',
    'active': true,
    'last_seen': DateTime.now(),
  });
  test('sent typing notification successfully', () async {
    TypingEvent typingEvent = TypingEvent(
        from: user2.id, to: user.id, event: Typing.start, id: uuid.v1());

    final res = await sut.send(event: typingEvent, to: user);
    expect(res, true);
  });

  test('successfully subscribe and receive typing events', () async {
    sut.subscribe(user2, [user.id]).listen(expectAsync1((event) {
      expect(event.from, user.id);
    }, count: 2));

    TypingEvent typing = TypingEvent(
      to: user2.id,
      from: user.id,
      event: Typing.start,
      id: uuid.v4(),
    );

    TypingEvent stopTyping = TypingEvent(
      to: user2.id,
      from: user.id,
      event: Typing.stop,
      id: uuid.v1(),
    );

    await sut.send(event: typing, to: user2);
    await sut.send(event: stopTyping, to: user2);
  });
}
