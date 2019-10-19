import 'package:firebase/firestore.dart' as firestore;

import 'model.g.dart' as g;
export 'model.g.dart' hide
  Conversation, ConversationCollectionListener,
  MessageCollectionListener;

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

  static Conversation fromFirestore(firestore.DocumentSnapshot doc, List<g.Tag> allConversationTags, List<g.Tag> allMessageTags) {
    var conversation = Conversation();
    g.Conversation.fromFirestore(doc, conversation);
    for (var message in conversation.messages) {
      message
        ..tags = allMessageTags.where((tag) => message.tagIds_temp.contains(tag.tagId)).toList()
        ..tagIds_temp = null;
    }
    return conversation
      ..deidentifiedPhoneNumber = DeidentifiedPhoneNumber.fromConversationId(doc.id)
      ..tags = allConversationTags.where((tag) => conversation.tagIds_temp.contains(tag.tagId)).toList()
      ..tagIds_temp = null;
  }
}
typedef ConversationCollectionListener(List<Conversation> changes);

class User {
  String userName;
  String userEmail;
}
