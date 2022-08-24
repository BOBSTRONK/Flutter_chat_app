import 'package:chat/src/models/receipt.dart';
import 'package:realchatapp/data/datasources/datasource_contract.dart';
import 'package:realchatapp/models/local_message.dart';
import 'package:realchatapp/models/chat.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteDatasource implements IDatasource {
  final Database _db;
  const SqfliteDatasource(this._db);

  @override
  Future<void> addChat(Chat chat) async {
    await _db.insert('chats', chat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    //ConflictAlgorithm.replace means if there is a conflict
    //go ahead and replace that record.
  }

  @override
  Future<void> addMessage(LocalMessage message) async {
    await _db.insert('messages', message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteChat(String chatId) async {
    //when i want to delete, i want delete chat from the chat table ,
    //but also delete it from the messages table ,the chats that associated with that chat

    final batch = _db
        .batch(); //batch is a group of two or more Sql Statements or a single SQL statement that has the same effect
    //as a group of two or more SQL statements, it can optimize execution because of network traffic,and will be executed before
    //any results are available.
    batch.delete('messages',
        where: 'chat_id = ?',
        whereArgs: [chatId]); //? will be replace by whereArgs
    batch.delete('chat',
        where: 'id = ?', whereArgs: [chatId]); //? will be replace by whereArgs
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Chat>> findAllChats() async {
    //fetch the chat and all the messages associated with that chat
    //also all the unread messages like on the count of the unread messages
    //and most recent message with that chat

    //avoid deadlock, we do not want to use the db object to run each query
    return _db.transaction((txn) async {
      final chatWithLatestMessage =
          await txn.rawQuery('''SELECT messages.* From 
      (SELECT 
        chat_id,MAX(created_at) as created_at
        FROM messages
        GROUP BY chat_id
      ) AS lastest_messages
      INNER JOIN messages
      ON messages.chat_id = lastest_messages.chat_id
      AND messages.created_at = latest_messages.created_at
      ''');

      if (chatWithLatestMessage.isEmpty) return [];

      final chatsWithUnreadMessages =
          await txn.rawQuery('''SELECT chat_id, count(*) as unread 
      FROM messages
      WHERE receipt = ?
      GROUP BY chat_id
      ''', ['deliverred']); //? will be replaced by deliverred

      return chatWithLatestMessage.map<Chat>((row) {
        final int? unread = int.tryParse(chatsWithUnreadMessages
            .firstWhere((ele) => row['chat_id'] == ele['chat_id'],
                orElse: () => {'unread': 0})['unread']
            .toString());

        final chat = Chat.fromMap({"id": row['chat_id']});
        chat.unread = unread!;
        chat.mostRecent = LocalMessage.fromMap(row);
        return chat;
      }).toList();
    });
  }

  @override
  Future<Chat> findChat(String chatId) async {
    return await _db.transaction((txn) async {
      //find chat where the id = chatId
      final listOfChatMaps = await txn.query(
        'chats',
        where: 'id = ?',
        whereArgs: [chatId],
      );

      if (listOfChatMaps.isEmpty) return Chat('-1');

      //COUNT in database the number of messages that are unread for this particular chat
      final unread = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM MESSAGES WHERE chat_id = ? AND receipt = ?',
          [chatId, 'deliverred']));

      //we order each message associated with ChatID in descending way
      //so the latesest message will always be in the top
      //limit:1 = get first message
      final mostRecentMessage = await txn.query('messages',
          where: 'chat_id = ?',
          whereArgs: [chatId],
          orderBy: 'created_at DESC',
          limit: 1);
      //1st one , so it will be a single element
      final chat = Chat.fromMap(listOfChatMaps.first);
      chat.unread = unread!;
      chat.mostRecent = LocalMessage.fromMap(mostRecentMessage.first);
      return chat;
    });
  }

  @override
  Future<List<LocalMessage>> findMessages(String chatId) async {
    final listOfMaps = await _db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );

    return listOfMaps
        .map<LocalMessage>((map) => LocalMessage.fromMap(map))
        .toList();
  }

  @override
  Future<void> updateMessage(LocalMessage message) async {
    //use the massa
    await _db.update('messages', message.toMap(),
        where: 'id = ?',
        whereArgs: [message.message.id], //因为LocalMessage里面有accesso的是message
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateMessageReceipt(String messageId, ReceiptStatus status) {
    // TODO: implement updateMessageReceipt
    throw UnimplementedError();
  }
  //Max(created_at) means the latest
}
