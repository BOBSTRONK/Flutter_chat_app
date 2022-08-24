import 'package:chat/chat.dart';

import '../../models/chat.dart';
import '../../models/local_message.dart';

abstract class IDatasource {
  //add chat to the databse
  Future<void> addChat(Chat chat);
  //add messages to the database
  Future<void> addMessage(LocalMessage message);
  Future<Chat> findChat(String chatId);
  Future<List<Chat>> findAllChats();
  Future<void> updateMessage(LocalMessage message);
  Future<List<LocalMessage>> findMessages(String chatId);
  Future<void> deleteChat(String chatId);
  Future<void> updateMessageReceipt(String messageId, ReceiptStatus status);
}
