import 'package:firebase/firestore.dart' as firestore;

import 'model.g.dart' as g;
export 'model.g.dart' hide Conversation, Message;

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

class Conversation extends g.Conversation {
  DeidentifiedPhoneNumber deidentifiedPhoneNumber;
  Map<String, String> demographicsInfo;
  List<g.Tag> tags;
  List<Message> messages;

  static Conversation fromFirestore(firestore.DocumentSnapshot doc) {
    var data = doc.data();
    var rawDemographicsInfo = data["demographicsInfo"] as Map<String, dynamic>;
    Map<String, String> demogInfo = {};
    for (var k in rawDemographicsInfo.keys) {
      demogInfo[k] = rawDemographicsInfo[k].toString();
    }
    var conversation = Conversation()
      ..deidentifiedPhoneNumber = DeidentifiedPhoneNumber.fromConversationId(doc.id)
      ..demographicsInfo = demogInfo;
    return g.Conversation.fromFirestore(doc, conversation);
  }
}

class Message extends g.Message {
  List<g.Tag> tags;

  static Message fromData(Map messageData) {
    return g.Message.fromData(messageData, Message());
  }
}

class User {
  String userName;
  String userEmail;
}
