import 'dart:collection';

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

  static Conversation fromFirestore(firestore.DocumentSnapshot doc) {
    var conversation = Conversation();
    g.Conversation.fromFirestore(doc, conversation);
    return conversation
      ..deidentifiedPhoneNumber = DeidentifiedPhoneNumber.fromConversationId(doc.id);
  }
}
typedef ConversationCollectionListener(List<Conversation> changes);

UnmodifiableListView<g.Tag> tagIdsToTags(List<String> tagIds, Iterable<g.Tag> allTags) =>
    tagIds
      .map<g.Tag>((id) => allTags.firstWhere((tag) => tag.tagId == id, orElse: () {
        g.log.warning('failed to find tag with id: $id');
        return null;
      }))
      .where((tag) => tag != null)
      .toList();

class User {
  String userName;
  String userEmail;
}
