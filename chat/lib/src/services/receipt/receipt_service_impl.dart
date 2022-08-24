import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import '../../models/message.dart';
import '../encryption/encryption_contract.dart';

class ReceiptService implements IReceiptService {
  final Connection _connection;
  final RethinkDb r;

  //be broadcast because this can be subscribed by multiple client
  //single stream only one client
  final _controller = StreamController<Receipt>.broadcast();
  late StreamSubscription _changefeed;

  ReceiptService(this.r, this._connection);

  @override
  dispose() {
    _controller.close();
    _changefeed.cancel();
  }

  @override
  Stream<Receipt> receipts(User user) {
    //Stream consume the memory , so you do not want active a stream without anybody subscrib it
    _startReceivingReceipts(user);
    return _controller.stream;
  }

  @override
  Future<bool> send(Receipt receipt) async {
    var data = receipt.toJson();
    Map record = await r.table('receipts').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  //use rethinkdb real-time capabilities
  _startReceivingReceipts(User user) {
    //Stream of events or data that happens on that particular table
    //asking rethink to give me the table
    //then for that table i want to filter out only my massages, so 'to' that to me
    _changefeed = r
        .table('receipts')
        .filter({'recipient': user.id})
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
                final receipt = _receiptFromFeed(feedData);
                //add the message to stream, so user or client who subscribe this stream will receive messages.
                _controller.sink.add(receipt);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        });

    //include_initial this will include the initial changes so that if you are just subscribing,
    //to the changefeed but there are messages waiting on the queue for you
    //then you will immediately get those messages and not have to wait until
    //there is a next change happening on the database
  }

  Receipt _receiptFromFeed(feedData) {
    var data = feedData['new_val'];
    return Receipt.fromJson(data);
  }
}
