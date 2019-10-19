import 'package:firebase/firestore.dart' as firestore;

import 'model.g.dart' as g;
export 'model.g.dart' hide
  Conversation, ConversationCollectionListener,
  Message, MessageCollectionListener;

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
  List<g.Tag> tags;
  List<Message> messages;

  static Conversation fromFirestore(firestore.DocumentSnapshot doc, List<g.Tag> allConversationTags, List<g.Tag> allMessageTags) {
    var data = doc.data();
    List<Message> messages = [];
    for (Map messageData in data["messages"]) {
      //{datetime: 2019-05-10T15:19:13.567929+00:00, direction: out, tags: [], text: test message, translation: }
      List tagIds = messageData["tags"];
      messages.add(
          Message.fromData(messageData)
            ..tags = allMessageTags.where((tag) => tagIds.contains(tag.tagId)).toList()
      );
    }
    List conversationTagIds = data["tags"];
    var conversation = Conversation()
      ..deidentifiedPhoneNumber = DeidentifiedPhoneNumber.fromConversationId(doc.id)
      ..tags = allConversationTags.where((tag) => conversationTagIds.contains(tag.tagId)).toList()
      ..messages = messages;
    return g.Conversation.fromFirestore(doc, conversation);
  }
}
typedef ConversationCollectionListener(List<Conversation> changes);

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
