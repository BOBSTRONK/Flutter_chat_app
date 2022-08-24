import 'package:chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:realchatapp/data/datasources/sqflite_datasource.dart';
import 'package:realchatapp/models/chat.dart';
import 'package:realchatapp/models/local_message.dart';
import 'package:sqflite/sqlite_api.dart';

import 'sqflite_datasource_test.mocks.dart';

//class MockSqfliteDatabase extends Mock implements Database {}

//class MockBatch extends Mock implements Batch {}

@GenerateMocks([Database])
@GenerateMocks([Batch])
void main() {
  late SqfliteDatasource sut;

  late MockDatabase database;

  late MockBatch batch;

  setUp(() {
    database = MockDatabase();
    batch = MockBatch();
    sut = SqfliteDatasource(database);
  });
  final message = Message.fromJson({
    'from': '111',
    'to': '222',
    'contents': 'hey',
    'timestamp': DateTime.parse("2021-04-01"),
    'id': '4444'
  });

  test('should perform insert of chat to the database', () async {
    //arrange
    final chat = Chat('1234');
    when(database.insert('chats', chat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);
    //act
    await sut.addChat(chat);

    //assert
    verify(database.insert('chats', chat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform insert of message to the database', () async {
    //arrange
    final localMessage =
        LocalMessage('1234', message, ReceiptStatus.sent, '1234');

    when(database.insert('messages', localMessage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);
    //act
    await sut.addMessage(localMessage);

    //assert
    verify(database.insert('messages', localMessage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform a database query and return message', () async {
    //arrange
    final messagesMap = [
      {
        'chat_id': '111',
        'id': '4444',
        'from': '111',
        'to': '222',
        'contents': 'hey',
        'receipt': 'sent',
        'timestamp': DateTime.parse("2021-04-01"),
      }
    ];
    when(database.query(
      'messages',
      where: anyNamed('where'),
      whereArgs: anyNamed('whereArgs'),
    )).thenAnswer((_) async => messagesMap);

    //act
    var messages = await sut.findMessages('111');

    //assert
    expect(messages.length, 1);
    expect(messages.first.chatId, '111');
    verify(database.query(
      'messages',
      where: anyNamed('where'),
      whereArgs: anyNamed('whereArgs'),
    )).called(1);
  });
}
