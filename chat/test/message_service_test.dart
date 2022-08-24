import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_service.dart';
import 'package:chat/src/services/message/message_service_impl.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:uuid/uuid.dart' as Uuid;

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late MessageService sut;
  late Uuid.Uuid uuid;

  setUp(() async {
    connection = await r.connect(host: '127.0.0.1', port: 28015);
    final encryption = EncryptionService(Encrypter(AES(Key.fromLength(32))));
    await createDb(r, connection);
    sut = MessageService(r, connection, encryption);
    uuid = Uuid.Uuid();
  });

  tearDown(() async {
    //sut.dispose();
    await cleanDb(r, connection);
  });

  final user = User(
    username: 'test1',
    photoUrl: 'url',
    active: true,
    lastseen: DateTime.now(),
    id: '1234',
  );

  final user2 = User(
    username: 'test2',
    photoUrl: 'url2',
    active: true,
    lastseen: DateTime.now(),
    id: '1111',
  );

  test('sent message successfully', () async {
    Message message = Message(
      from: user.id,
      to: '3456',
      timestamp: DateTime.now(),
      contents: 'this is a message',
      id: uuid.v1(),
    );

    final res = await sut.send(message);
    expect(res, true);
  });

  test('successfully subscribe and receive messages', () async {
    const contents = 'this is a message';
    sut.messages(activeUser: user2).listen(expectAsync1((message) {
          expect(message.to, user2.id); //user to me
          expect(message.id, isNotEmpty); //message.id is not empty
          expect(message.contents,
              contents); //messages content should be the contents
        }, count: 2));

    Message message = Message(
      from: user.id,
      to: user2.id,
      timestamp: DateTime.now(),
      contents: contents,
      id: uuid.v1(),
    );

    Message secondMessage = Message(
      from: user.id,
      to: user2.id,
      timestamp: DateTime.now(),
      contents: contents,
      id: uuid.v1(),
    );

    await sut.send(message);
    await sut.send(secondMessage);
  });

  test('successfully subscribe and receive new messages ', () async {
    Message message = Message(
      from: user.id,
      to: user2.id,
      timestamp: DateTime.now(),
      contents: 'this is a message',
      id: uuid.v1(),
    );

    Message secondMessage = Message(
      from: user.id,
      to: user2.id,
      timestamp: DateTime.now(),
      contents: 'this is another message',
      id: uuid.v1(),
    );

    await sut.send(message);
    await sut.send(secondMessage).whenComplete(
          () => sut.messages(activeUser: user2).listen(
                expectAsync1((message) {
                  expect(message.to, user2.id);
                }, count: 2),
              ),
        );
  });
}
