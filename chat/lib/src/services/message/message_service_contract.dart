import '../../models/message.dart';
import '../../models/user.dart';

abstract class IMessageService {
  Future<bool> send(Message message);
  //you only get message from ur particular user
  //filter all the unnecessary messages , u only see message
  //that pertains to you
  Stream<Message> messages({required User activeUser});
  dispose();
}
