import 'dart:collection';

import 'model.g.dart' as g;
export 'model.g.dart' hide
  MessageCollectionListener,
  MessageDirection_fromStringOverride,
  TagType_fromStringOverride;

extension UserConfigurationUtil on g.UserConfiguration {
  g.UserConfiguration operator +(g.UserConfiguration other) =>
    new g.UserConfiguration()
      ..docId = other.docId
      ..keyboardShortcutsEnabled = other.keyboardShortcutsEnabled ?? this.keyboardShortcutsEnabled
      ..sendCustomMessagesEnabled = other.sendCustomMessagesEnabled ?? this.sendCustomMessagesEnabled
      ..sendMultiMessageEnabled = other.sendMultiMessageEnabled ?? this.sendMultiMessageEnabled
      ..tagPanelVisibility = other.tagPanelVisibility ?? this.tagPanelVisibility;
}

extension ConversationListShardUtil on g.ConversationListShard {
  String get conversationListRoot => docId != null
    ? "/${g.ConversationListShard.collectionName}/$docId/conversations"
    : "/nook_conversations";

  String get displayName => name ?? docId;
}

extension ConversationUtil on g.Conversation {
  String get shortDeidentifiedPhoneNumber => docId.split('uuid-')[1].split('-')[0];

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

  static int mostRecentInboundFirst(g.Conversation c1, g.Conversation c2) {
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
  }
}

extension MessageUtil on g.Message {
  /// Add [tagId] to tagIds in this Message.
  /// Callers should catch and handle IOException.
  Future<void> addTagId(g.DocPubSubUpdate pubSubClient, g.Conversation conversation, String tagId) async {
    if (tagIds.contains(tagId)) return;
    tagIds.add(tagId);
    return pubSubClient.publishDocAdd(g.Conversation.collectionName, <String>[
      conversation.docId
    ], {
      "messages/${_messageIndex(conversation)}/tags": [tagId]
    });
  }

  /// Remove [tagId] from tagIds in this Message.
  /// Callers should catch and handle IOException.
  Future<void> removeTagId(g.DocPubSubUpdate pubSubClient, g.Conversation conversation, String tagId) async {
    if (!tagIds.contains(tagId)) return;
    tagIds.remove(tagId);
    return pubSubClient
        .publishDocRemove(g.Conversation.collectionName, <String>[
      conversation.docId
    ], {
      "messages/${_messageIndex(conversation)}/tags": [tagId]
    });
  }

  Future<void> setTranslation(g.DocPubSubUpdate pubSubClient, g.Conversation conversation, String newTranslation) async {
    if (translation == newTranslation) return;
    translation = newTranslation;
    return pubSubClient.publishDocChange(
        g.Conversation.collectionName, <String>[
      conversation.docId
    ], {
      "messages/${_messageIndex(conversation)}/translation": newTranslation
    });
  }

  /// Return the index of this message within the given conversations list of messages.
  int _messageIndex(g.Conversation conversation) {
    // TODO Consider switching to a message-id independent of conversation
    var index = conversation.messages.indexOf(this);
    if (index < 0) throw Exception("Cannot find message in conversation");
    return index;
  }
}

UnmodifiableListView<g.Tag> tagIdsToTags(
    Iterable<String> tagIds, Iterable<g.Tag> allTags) {
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
