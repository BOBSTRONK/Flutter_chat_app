import 'dart:math';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/user_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:uuid/uuid.dart' as Uuid;

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late UserService sut;
  late Uuid.Uuid uuid;

  setUp(() async {
    connection = await r.connect(host: "127.0.0.1", port: 28015);
    await createDb(r, connection);
    sut = UserService(r, connection);
    uuid = Uuid.Uuid();
  });

  tearDown(() async {
    await cleanDb(r, connection);
  });

  test('creates a new user document in database', () async {
    final user = User(
      username: 'test',
      photoUrl: 'url',
      active: true,
      lastseen: DateTime.now(),
      id: uuid.v1(),
    );
    final userWithId = await sut.connect(user);
    expect(userWithId.getId(), isNotEmpty);
  });

  test('get online users', () async {
    final user = User(
      username: 'test',
      photoUrl: 'url',
      active: true,
      lastseen: DateTime.now(),
      id: uuid.v1(),
    );
    await sut.connect(user);
    final users = await sut.online();
    expect(users.length, 3);
  });
}
