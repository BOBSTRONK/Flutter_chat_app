import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/message.dart';
import 'package:chat/src/services/encryption/encryption_contract.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class MessageService implements IMessageService {
  final Connection _connection;
  final RethinkDb r;

  //be broadcast because this can be subscribed by multiple client
  //single stream only one client
  final _controller = StreamController<Message>.broadcast();
  late StreamSubscription _changefeed;

  final IEncryption _encryption;

  MessageService(this.r, this._connection, this._encryption);

  @override
  dispose() {
    _controller.close();
    _changefeed.cancel();
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    //Stream consume the memory , so you do not want active a stream without anybody subscrib it
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<bool> send(Message message) async {
    var data = message.toJson();
    data['contents'] = _encryption.encrypt(message.contents);
    Map record = await r.table('messages').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  //use rethinkdb real-time capabilities
  _startReceivingMessages(User user) {
    //Stream of events or data that happens on that particular table
    //asking rethink to give me the table
    //then for that table i want to filter out only my massages, so 'to' that to me
    _changefeed = r
        .table('messages')
        .filter({'to': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>() //rethinkDb feed
        .listen((event) {
          //listening the changes of message table , all those message that are coming to me
          event //fetch a event and fetch the message data from the event,and also this event is a stream
              .forEach((feedData) {
                //rethinkddb every event that happens on the table it triggers a change feed event
                //so if you delete a record from the table it will also trigger the change event
                //you will recevie a change event , but there will not be a new value(delete),will be a old value
                if (feedData['new_val'] == null) {
                  return;
                }
                final message = _messageFromFeed(feedData);
                //add the message to stream, so user or client who subscribe this stream will receive messages.
                _controller.sink.add(message);
                //once message is deliveried , message will be removed from server
                //and messages will be stored locally
                _removeDeliverredMessage(message);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        });

    //include_initial this will include the initial changes so that if you are just subscribing,
    //to the changefeed but there are messages waiting on the queue for you
    //then you will immediately get those messages and not have to wait until
    //there is a next change happening on the database
  }

  Message _messageFromFeed(feedData) {
    var data = feedData['new_val'];
    data['contents'] = _encryption.decrypt(data['contents']);
    return Message.fromJson(data);
  }

  _removeDeliverredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false}).run(_connection);
  }
}
