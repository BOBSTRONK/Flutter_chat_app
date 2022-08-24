import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/services/typing/typing_notification_service_contract.dart';
import 'package:chat/src/services/user_service_impl.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class TypingNotification implements ITypingNotification {
  final Connection _connection;
  final RethinkDb r;

  //be broadcast because this can be subscribed by multiple client
  //single stream only one client
  final _controller = StreamController<TypingEvent>.broadcast();
  late StreamSubscription _changefeed;

  TypingNotification(this.r, this._connection);

  @override
  void dispose() {
    //_changefeed.cancel();
    _controller.close();
  }

  @override
  Future<bool> send({required TypingEvent event, required User to}) async {
    //如果用户不在线，不需要发typing event
    if (!to.active) return false;
    Map record = await r
        .table('typing_events')
        .insert(event.toJson(), {'conflict': 'update'}).run(_connection);
    return record['inserted'] == 1;
  }

  @override
  Stream<TypingEvent> subscribe(User user, List<String> userIds) {
    _startReceivingTypingEvents(user, userIds);
    return _controller.stream;
  }

  _startReceivingTypingEvents(User user, List<String> userIds) {
    _changefeed = r
        .table('typing_events')
        .filter((event) {
          return event(
                  'to') //all i want to receive events for is for those events are
              .eq(user.id) //sent to me , so event to is equal to user.id
              .and(r.expr(userIds).contains(event('from')));
          //and they are coming from the list of user ids that i send here
          //coming from my current active chats that i have.
        })
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;

                final typing = _eventFromFeed(feedData);
                _controller.sink.add(typing);
                _removeEvent(typing);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        });
  }

  TypingEvent _eventFromFeed(feedData) {
    return TypingEvent.fromJson(
        feedData['new_val']); //['new_val'] is a new value from event
    //and that is a typing event form of json
  }

  _removeEvent(TypingEvent event) {
    r
        .table('typing_events')
        .get(event.id)
        .delete({'return_changes': false}).run(_connection);
  }
}
