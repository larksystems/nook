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

  static Conversation fromFirestore(firestore.DocumentSnapshot doc, List<g.Tag> allMessageTags) {
    var conversation = Conversation();
    g.Conversation.fromFirestore(doc, conversation);
    return conversation
      ..deidentifiedPhoneNumber = DeidentifiedPhoneNumber.fromConversationId(doc.id);
  }

  Iterable<g.Tag> tagIdsToTags(Iterable<g.Tag> allTags) {
    var tags = <g.Tag>[];
    for (var id in tagIds) {
      var tag = allTags.firstWhere((tag) => tag.tagId == id, orElse: () {
        g.log.warning('failed to find Conversation tag: $id');
        return null;
      });
      if (tag != null) tags.add(tag);
    }
    return tags;
  }
}
typedef ConversationCollectionListener(List<Conversation> changes);

Iterable<g.Tag> Message_tagIdsToTags(g.Message message, Iterable<g.Tag> allTags) {
  var tags = <g.Tag>[];
  for (var id in message.tagIds) {
    var tag = allTags.firstWhere((tag) => tag.tagId == id, orElse: () {
      g.log.warning('failed to find Message tag: $id');
      return null;
    });
    if (tag != null) tags.add(tag);
  }
  return tags;
}

class User {
  String userName;
  String userEmail;
}
