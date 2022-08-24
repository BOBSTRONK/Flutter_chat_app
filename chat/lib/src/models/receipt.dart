enum ReceiptStatus { sent, deliverred, read }

//extension method for our enum
//extension method allows us to add new functionality to already available libraries
//not modifying existing code directly, it gives us the ability to customize a class
//in a way that we can read and use it easly
//extension <extension name> on <type>
extension EnumParsing on ReceiptStatus {
  String value() {
    //this keyword is reference to the  RecepStatus Enum
    return this.toString().split('.').last;
    //toString will be for exp : ReceipStatus.sent , so we want only last part only
  }

  //will return the receipstatus value
  //exp:give me the enum rapresentation of sent, so we pass sent here and it will return:ReceipStatus.sent
  static ReceiptStatus fromString(String status) {
    return ReceiptStatus.values
        .firstWhere((element) => element.value() == status);
  }
}

class Receipt {
  final String recipient; //接收者
  final String messageId;
  final ReceiptStatus status;
  final DateTime timestamp;
  final String id;

  Receipt(
      {required this.recipient,
      required this.messageId,
      required this.status,
      required this.timestamp,
      required this.id});

  Map<String, dynamic> toJson() => {
        'recipient': this.recipient,
        'message_id': this.messageId,
        'status': status.value(),
        'timestamp': timestamp,
        'id': id,
      };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    var receipt = Receipt(
      recipient: json['recipient'],
      messageId: json['message_id'],
      status: EnumParsing.fromString(json['status']),
      timestamp: json['timestamp'],
      id: json['id'],
    );
    return receipt;
  }
}
