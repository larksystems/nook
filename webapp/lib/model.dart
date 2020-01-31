import 'dart:collection';

import 'model.g.dart' as g;
export 'model.g.dart' hide
  Conversation,
  ConversationCollectionListener,
  MessageCollectionListener,
  MessageDirection_fromStringOverride,
  TagType_fromStringOverride;

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
  static const collectionName = g.Conversation.collectionName;

  DeidentifiedPhoneNumber deidentifiedPhoneNumber;

  String get documentPath => "$collectionName/${deidentifiedPhoneNumber.value}";

  /// Return the most recent inbound message, or `null`
  g.Message get mostRecentMessageInbound {
    for (int index = messages.length - 1; index >= 0; --index) {
      var message = messages[index];
      if (message.direction == g.MessageDirection.In) {
        return message;
      }
    }
    return null;
  }

  static Conversation fromSnapshot(g.DocSnapshot doc) {
    var conversation = Conversation();
    g.Conversation.fromSnapshot(doc, conversation);
    return conversation
      ..deidentifiedPhoneNumber = DeidentifiedPhoneNumber.fromConversationId(doc.id);
  }

  static Comparator<Conversation> mostRecentInboundFirst = (c1, c2) {
    var m1 = c1.mostRecentMessageInbound;
    var m2 = c2.mostRecentMessageInbound;
    if (m1 == null) {
      if (m2 == null) {
        m1 = c1.messages.last;
        m2 = c2.messages.last;
      } else {
        return -1;
      }
    } else {
      if (m2 == null) {
        return 1;
      } else {
        // fall through
      }
    }
    var result = m2.datetime.compareTo(m1.datetime);
    return result != 0 ? result : c2.hashCode.compareTo(c1.hashCode);
  };
}
typedef ConversationCollectionListener(List<Conversation> changes);

UnmodifiableListView<g.Tag> tagIdsToTags(List<String> tagIds, Iterable<g.Tag> allTags) {
  var tags = <g.Tag>[];
  for (var id in tagIds) {
    var tag = allTags.firstWhere((tag) => tag.tagId == id, orElse: () {
      g.log.warning('failed to find tag with id: $id');
      return null;
    });
    if (tag != null) tags.add(tag);
  }
  return UnmodifiableListView(tags);
}

class User {
  String userName;
  String userEmail;
}
