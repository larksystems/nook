import 'model.g.dart' as g;
export 'model.g.dart' hide Message;

class DeidentifiedPhoneNumber {
  String value;
  String shortValue;

  static DeidentifiedPhoneNumber fromConversationId(String conversationId) {
    String shortValue = conversationId.split('uuid-')[1].split('-')[0];
    return new DeidentifiedPhoneNumber()
      ..shortValue = shortValue
      ..value = conversationId;
  }
}

class Conversation {
  DeidentifiedPhoneNumber deidentifiedPhoneNumber;
  Map<String, String> demographicsInfo;
  List<g.Tag> tags;
  List<Message> messages;
  String notes;
}

class Message extends g.Message {
  List<g.Tag> tags;
}

class User {
  String userName;
  String userEmail;
}
