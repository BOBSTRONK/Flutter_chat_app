import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/receipt/receipt_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:uuid/uuid.dart' as Uuid;
import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late ReceiptService sut;
  late Uuid.Uuid uuid;

  setUp(() async {
    connection = await r.connect();
    await createDb(r, connection);
    sut = ReceiptService(r, connection);
    uuid = Uuid.Uuid();
  });

  tearDown(() async {
    //sut.dispose();
    await cleanDb(r, connection);
  });

  final user = User.fromJson({
    'username': 'test',
    'photo_url': 'url',
    'id': '1234',
    'active': true,
    'last_seen': DateTime.now(),
  });

  test('sent receipt successfully', () async {
    Receipt receipt = Receipt(
      recipient: '444',
      messageId: '1234',
      status: ReceiptStatus.deliverred,
      timestamp: DateTime.now(),
      id: uuid.v1(),
    );

    final res = await sut.send(receipt);
    expect(res, true);
  });

  test('successfully subscribe and receive receipts', () async {
    sut.receipts(user).listen(expectAsync1((receipt) {
          expect(receipt.recipient, user.id);
        }, count: 2)); //count means this method will be called twice

    Receipt receipt = Receipt(
      recipient: user.id,
      messageId: '1234',
      status: ReceiptStatus.deliverred,
      timestamp: DateTime.now(),
      id: uuid.v1(),
    );

    Receipt anotherReceipt = Receipt(
      recipient: user.id,
      messageId: '1234',
      status: ReceiptStatus.read,
      timestamp: DateTime.now(),
      id: uuid.v1(),
    );

    await sut.send(receipt);
    await sut.send(anotherReceipt);
  });
}
