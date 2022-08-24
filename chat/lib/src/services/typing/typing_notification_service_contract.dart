import '../../models/typing_event.dart';
import '../../models/user.dart';

abstract class ITypingNotification {
  Future<bool> send({required TypingEvent event, required User to});
  //user is who is sbscribing this typingevent
  //userIDs will represent those persons whom i want to receive events from,
  //typing event only with who i already have a chat thread going on with
  Stream<TypingEvent> subscribe(User user, List<String> userIds);
  void dispose();
}
