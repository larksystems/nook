// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'dart:async';

import 'package:katikati_ui_lib/components/logger.dart';

Logger log = Logger('model.g.dart');

class ConversationListShard {
  static const collectionName = 'nook_conversation_shards';

  String docId;
  String name;

  static ConversationListShard fromSnapshot(DocSnapshot doc, [ConversationListShard modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static ConversationListShard fromData(data, [ConversationListShard modelObj]) {
    if (data == null) return null;
    return (modelObj ?? ConversationListShard())
      ..name = String_fromData(data['name']);
  }

  static ConversationListShard required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static ConversationListShard notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static StreamSubscription listen(DocStorage docStorage, ConversationListShardCollectionListener listener,
          {String collectionRoot = '/$collectionName', OnErrorListener onErrorListener}) =>
      listenForUpdates<ConversationListShard>(docStorage, listener, collectionRoot, ConversationListShard.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (name != null) 'name': name,
    };
  }

  @override
  String toString() => 'ConversationListShard [$docId]: ${toData().toString()}';
}
typedef ConversationListShardCollectionListener = void Function(
  List<ConversationListShard> added,
  List<ConversationListShard> modified,
  List<ConversationListShard> removed,
);

class Conversation {
  static const collectionName = 'nook_conversations';

  String docId;
  Map<String, String> demographicsInfo;
  Set<String> tagIds;
  Set<String> lastInboundTurnTagIds;
  List<Message> messages;
  String notes;
  bool unread;

  static Conversation fromSnapshot(DocSnapshot doc, [Conversation modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Conversation fromData(data, [Conversation modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Conversation())
      ..demographicsInfo = Map_fromData<String>(data['demographicsInfo'], String_fromData)
      ..tagIds = Set_fromData<String>(data['tags'], String_fromData)
      ..lastInboundTurnTagIds = Set_fromData<String>(data['lastInboundTurnTags'], String_fromData) ?? {}
      ..messages = List_fromData<Message>(data['messages'], Message.fromData)
      ..notes = String_fromData(data['notes'])
      ..unread = bool_fromData(data['unread']) ?? true;
  }

  static Conversation required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Conversation notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static StreamSubscription listen(DocStorage docStorage, ConversationCollectionListener listener,
          {String collectionRoot = '/$collectionName', OnErrorListener onErrorListener}) =>
      listenForUpdates<Conversation>(docStorage, listener, collectionRoot, Conversation.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (demographicsInfo != null) 'demographicsInfo': demographicsInfo,
      if (tagIds != null) 'tags': tagIds.toList(),
      if (lastInboundTurnTagIds != null) 'lastInboundTurnTags': lastInboundTurnTagIds.toList(),
      if (messages != null) 'messages': messages.map((elem) => elem?.toData()).toList(),
      if (notes != null) 'notes': notes,
      if (unread != null) 'unread': unread,
    };
  }

  /// Add [newTagIds] to tagIds in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> addTagIds(DocPubSubUpdate pubSubClient, Iterable<String> newTagIds) {
    var toBeAdded = Set<String>();
    for (var elem in newTagIds) {
      if (!tagIds.contains(elem)) {
        toBeAdded.add(elem);
      }
    }
    if (toBeAdded.isEmpty) return Future.value(null);
    tagIds.addAll(toBeAdded);
    return pubSubClient.publishAddOpinion('nook_conversations/add_tags', {
      'conversation_id': docId,
      'tags': toBeAdded.toList(),
    });
  }

  /// Set tagIds in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> setTagIds(DocPubSubUpdate pubSubClient, Set<String> newTagIds) {
    if (tagIds.length == newTagIds.length && tagIds.difference(newTagIds).isEmpty) {
      return Future.value(null);
    }
    tagIds = newTagIds;
    return pubSubClient.publishAddOpinion('nook_conversations/set_tags', {
      'conversation_id': docId,
      'tags': tagIds.toList(),
    });
  }

  /// Remove [oldTagIds] from tagIds in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> removeTagIds(DocPubSubUpdate pubSubClient, Iterable<String> oldTagIds) {
    var toBeRemoved = Set<String>();
    for (var elem in oldTagIds) {
      if (tagIds.remove(elem)) {
        toBeRemoved.add(elem);
      }
    }
    if (toBeRemoved.isEmpty) return Future.value(null);
    return pubSubClient.publishAddOpinion('nook_conversations/remove_tags', {
      'conversation_id': docId,
      'tags': toBeRemoved.toList(),
    });
  }

  /// Set notes in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> setNotes(DocPubSubUpdate pubSubClient, String newNotes) {
    if (notes == newNotes) {
      return Future.value(null);
    }
    notes = newNotes;
    return pubSubClient.publishAddOpinion('nook_conversations/set_notes', {
      'conversation_id': docId,
      'notes': notes,
    });
  }

  /// Set unread in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> setUnread(DocPubSubUpdate pubSubClient, bool newUnread) {
    if (unread == newUnread) {
      return Future.value(null);
    }
    unread = newUnread;
    return pubSubClient.publishAddOpinion('nook_conversations/set_unread', {
      'conversation_id': docId,
      'unread': unread,
    });
  }

  @override
  String toString() => 'Conversation [$docId]: ${toData().toString()}';
}
typedef ConversationCollectionListener = void Function(
  List<Conversation> added,
  List<Conversation> modified,
  List<Conversation> removed,
);

class Message {
  MessageDirection direction;
  DateTime datetime;
  MessageStatus status;
  List<String> tagIds;
  String text;
  String translation;
  String id;

  static Message fromData(data, [Message modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Message())
      ..direction = MessageDirection.fromData(data['direction']) ?? MessageDirection.Out
      ..datetime = DateTime_fromData(data['datetime'])
      ..status = MessageStatus.fromData(data['status'])
      ..tagIds = List_fromData<String>(data['tags'], String_fromData)
      ..text = String_fromData(data['text'])
      ..translation = String_fromData(data['translation'])
      ..id = String_fromData(data['id']);
  }

  static Message required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Message notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  Map<String, dynamic> toData() {
    return {
      if (direction != null) 'direction': direction.toData(),
      if (datetime != null) 'datetime': datetime.toIso8601String(),
      if (status != null) 'status': status.toData(),
      if (tagIds != null) 'tags': tagIds,
      if (text != null) 'text': text,
      if (translation != null) 'translation': translation,
      if (id != null) 'id': id,
    };
  }

  @override
  String toString() => 'Message: ${toData().toString()}';
}

class MessageDirection {
  static const In = MessageDirection('in');
  static const Out = MessageDirection('out');

  static const values = <MessageDirection>[
    In,
    Out,
  ];

  static MessageDirection fromString(String text, [MessageDirection defaultValue = MessageDirection.Out]) {
    if (text != null) {
      const prefix = 'MessageDirection.';
      var valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown MessageDirection $text');
    return defaultValue;
  }

  static MessageDirection fromData(data, [MessageDirection defaultValue = MessageDirection.Out]) {
    if (data is String || data == null) return fromString(data, defaultValue);
    log.warning('invalid MessageDirection: ${data.runtimeType}: $data');
    return defaultValue;
  }

  static MessageDirection required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static MessageDirection notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  final String name;
  const MessageDirection(this.name);

  String toData() => 'MessageDirection.$name';

  @override
  String toString() => toData();
}

class MessageStatus {
  static const pending = MessageStatus('pending');
  static const confirmed = MessageStatus('confirmed');
  static const failed = MessageStatus('failed');
  static const unknown = MessageStatus('unknown');

  static const values = <MessageStatus>[
    pending,
    confirmed,
    failed,
    unknown,
  ];

  static MessageStatus fromString(String text, [MessageStatus defaultValue = MessageStatus.unknown]) {
    if (text != null) {
      const prefix = 'MessageStatus.';
      var valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    // This is commented out because it generates too much noise in the logs
    // log.warning('unknown MessageStatus $text');
    return defaultValue;
  }

  static MessageStatus fromData(data, [MessageStatus defaultValue = MessageStatus.unknown]) {
    if (data is String || data == null) return fromString(data, defaultValue);
    log.warning('invalid MessageStatus: ${data.runtimeType}: $data');
    return defaultValue;
  }

  static MessageStatus required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static MessageStatus notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  final String name;
  const MessageStatus(this.name);

  String toData() => 'MessageStatus.$name';

  @override
  String toString() => toData();
}

class SuggestedReply {
  static const collectionName = 'suggestedReplies';

  String docId;
  String text;
  String translation;
  String shortcut;
  int seqNumber;
  String category;
  String groupId;
  String groupDescription;
  int indexInGroup;

  String get suggestedReplyId => docId;

  static SuggestedReply fromSnapshot(DocSnapshot doc, [SuggestedReply modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static SuggestedReply fromData(data, [SuggestedReply modelObj]) {
    if (data == null) return null;
    return (modelObj ?? SuggestedReply())
      ..text = String_fromData(data['text'])
      ..translation = String_fromData(data['translation'])
      ..shortcut = String_fromData(data['shortcut'])
      ..seqNumber = int_fromData(data['seq_no'])
      ..category = String_fromData(data['category'])
      ..groupId = String_fromData(data['group_id'])
      ..groupDescription = String_fromData(data['group_description'])
      ..indexInGroup = int_fromData(data['index_in_group']);
  }

  static SuggestedReply required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static SuggestedReply notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static StreamSubscription listen(DocStorage docStorage, SuggestedReplyCollectionListener listener,
          {String collectionRoot = '/$collectionName', OnErrorListener onErrorListener}) =>
      listenForUpdates<SuggestedReply>(docStorage, listener, collectionRoot, SuggestedReply.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (translation != null) 'translation': translation,
      if (shortcut != null) 'shortcut': shortcut,
      if (seqNumber != null) 'seq_no': seqNumber,
      if (category != null) 'category': category,
      if (groupId != null) 'group_id': groupId,
      if (groupDescription != null) 'group_description': groupDescription,
      if (indexInGroup != null) 'index_in_group': indexInGroup,
    };
  }

  @override
  String toString() => 'SuggestedReply [$docId]: ${toData().toString()}';
}
typedef SuggestedReplyCollectionListener = void Function(
  List<SuggestedReply> added,
  List<SuggestedReply> modified,
  List<SuggestedReply> removed,
);

class Tag {
  String docId;
  String text;
  TagType type;
  String shortcut;
  bool filterable;
  String group;
  List<String> groups;
  bool visible;
  bool isUnifier;
  String unifierTagId;
  List<String> unifiesTagIds;

  String get tagId => docId;

  static Tag fromSnapshot(DocSnapshot doc, [Tag modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Tag fromData(data, [Tag modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Tag())
      ..text = String_fromData(data['text'])
      ..type = TagType.fromData(data['type']) ?? TagType.Normal
      ..shortcut = String_fromData(data['shortcut'])
      ..filterable = bool_fromData(data['filterable'])
      ..group = String_fromData(data['group']) ?? ""
      ..groups = List_fromData<String>(data['groups'], String_fromData) ?? []
      ..visible = bool_fromData(data['visible']) ?? true
      ..isUnifier = bool_fromData(data['isUnifier']) ?? false
      ..unifierTagId = String_fromData(data['unifierTagId'])
      ..unifiesTagIds = List_fromData<String>(data['unifiesTagIds'], String_fromData);
  }

  static Tag required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static Tag notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static void listen(DocStorage docStorage, TagCollectionListener listener, String collectionRoot, {OnErrorListener onErrorListener}) =>
      listenForUpdates<Tag>(docStorage, listener, collectionRoot, Tag.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (type != null) 'type': type.toData(),
      if (shortcut != null) 'shortcut': shortcut,
      if (filterable != null) 'filterable': filterable,
      if (group != null) 'group': group,
      if (groups != null) 'groups': groups,
      if (visible != null) 'visible': visible,
      if (isUnifier != null) 'isUnifier': isUnifier,
      if (unifierTagId != null) 'unifierTagId': unifierTagId,
      if (unifiesTagIds != null) 'unifiesTagIds': unifiesTagIds,
    };
  }

  @override
  String toString() => 'Tag [$docId]: ${toData().toString()}';
}
typedef TagCollectionListener = void Function(
  List<Tag> added,
  List<Tag> modified,
  List<Tag> removed,
);

class TagType {
  static const Normal = TagType('normal');
  static const Important = TagType('important');

  static const values = <TagType>[
    Normal,
    Important,
  ];

  static TagType fromString(String text, [TagType defaultValue = TagType.Normal]) {
    if (text != null) {
      const prefix = 'TagType.';
      var valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown TagType $text');
    return defaultValue;
  }

  static TagType fromData(data, [TagType defaultValue = TagType.Normal]) {
    if (data is String || data == null) return fromString(data, defaultValue);
    log.warning('invalid TagType: ${data.runtimeType}: $data');
    return defaultValue;
  }

  static TagType required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static TagType notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  final String name;
  const TagType(this.name);

  String toData() => 'TagType.$name';

  @override
  String toString() => toData();
}

class SystemMessage {
  static const collectionName = 'systemMessages';

  String docId;
  String text;
  bool expired;

  String get msgId => docId;

  static SystemMessage fromSnapshot(DocSnapshot doc, [SystemMessage modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static SystemMessage fromData(data, [SystemMessage modelObj]) {
    if (data == null) return null;
    return (modelObj ?? SystemMessage())
      ..text = String_fromData(data['text'])
      ..expired = bool_fromData(data['expired']) ?? false;
  }

  static SystemMessage required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static SystemMessage notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static StreamSubscription listen(DocStorage docStorage, SystemMessageCollectionListener listener,
          {String collectionRoot = '/$collectionName', OnErrorListener onErrorListener}) =>
      listenForUpdates<SystemMessage>(docStorage, listener, collectionRoot, SystemMessage.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (expired != null) 'expired': expired,
    };
  }

  @override
  String toString() => 'SystemMessage [$docId]: ${toData().toString()}';
}
typedef SystemMessageCollectionListener = void Function(
  List<SystemMessage> added,
  List<SystemMessage> modified,
  List<SystemMessage> removed,
);

class UserConfiguration {
  static const collectionName = 'users';

  String docId;
  bool tagsKeyboardShortcutsEnabled;
  bool repliesKeyboardShortcutsEnabled;
  bool sendMessagesEnabled;
  bool sendCustomMessagesEnabled;
  bool sendMultiMessageEnabled;
  bool tagMessagesEnabled;
  bool tagConversationsEnabled;
  bool editTranslationsEnabled;
  bool editNotesEnabled;
  bool conversationalTurnsEnabled;
  bool tagsPanelVisibility;
  bool repliesPanelVisibility;
  bool suggestedRepliesGroupsEnabled;

  String get userId => docId;

  static UserConfiguration fromSnapshot(DocSnapshot doc, [UserConfiguration modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static UserConfiguration fromData(data, [UserConfiguration modelObj]) {
    if (data == null) return null;
    return (modelObj ?? UserConfiguration())
      ..tagsKeyboardShortcutsEnabled = bool_fromData(data['tags_keyboard_shortcuts_enabled'])
      ..repliesKeyboardShortcutsEnabled = bool_fromData(data['replies_keyboard_shortcuts_enabled'])
      ..sendMessagesEnabled = bool_fromData(data['send_messages_enabled'])
      ..sendCustomMessagesEnabled = bool_fromData(data['send_custom_messages_enabled'])
      ..sendMultiMessageEnabled = bool_fromData(data['send_multi_message_enabled'])
      ..tagMessagesEnabled = bool_fromData(data['tag_messages_enabled'])
      ..tagConversationsEnabled = bool_fromData(data['tag_conversations_enabled'])
      ..editTranslationsEnabled = bool_fromData(data['edit_translations_enabled'])
      ..editNotesEnabled = bool_fromData(data['edit_notes_enabled'])
      ..conversationalTurnsEnabled = bool_fromData(data['conversational_turns_enabled'])
      ..tagsPanelVisibility = bool_fromData(data['tags_panel_visibility'])
      ..repliesPanelVisibility = bool_fromData(data['replies_panel_visibility'])
      ..suggestedRepliesGroupsEnabled = bool_fromData(data['suggested_replies_groups_enabled']);
  }

  static UserConfiguration required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static UserConfiguration notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static StreamSubscription listen(DocStorage docStorage, UserConfigurationCollectionListener listener,
          {String collectionRoot = '/$collectionName', OnErrorListener onErrorListener}) =>
      listenForUpdates<UserConfiguration>(docStorage, listener, collectionRoot, UserConfiguration.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (tagsKeyboardShortcutsEnabled != null) 'tags_keyboard_shortcuts_enabled': tagsKeyboardShortcutsEnabled,
      if (repliesKeyboardShortcutsEnabled != null) 'replies_keyboard_shortcuts_enabled': repliesKeyboardShortcutsEnabled,
      if (sendMessagesEnabled != null) 'send_messages_enabled': sendMessagesEnabled,
      if (sendCustomMessagesEnabled != null) 'send_custom_messages_enabled': sendCustomMessagesEnabled,
      if (sendMultiMessageEnabled != null) 'send_multi_message_enabled': sendMultiMessageEnabled,
      if (tagMessagesEnabled != null) 'tag_messages_enabled': tagMessagesEnabled,
      if (tagConversationsEnabled != null) 'tag_conversations_enabled': tagConversationsEnabled,
      if (editTranslationsEnabled != null) 'edit_translations_enabled': editTranslationsEnabled,
      if (editNotesEnabled != null) 'edit_notes_enabled': editNotesEnabled,
      if (conversationalTurnsEnabled != null) 'conversational_turns_enabled': conversationalTurnsEnabled,
      if (tagsPanelVisibility != null) 'tags_panel_visibility': tagsPanelVisibility,
      if (repliesPanelVisibility != null) 'replies_panel_visibility': repliesPanelVisibility,
      if (suggestedRepliesGroupsEnabled != null) 'suggested_replies_groups_enabled': suggestedRepliesGroupsEnabled,
    };
  }

  @override
  String toString() => 'UserConfiguration [$docId]: ${toData().toString()}';
}
typedef UserConfigurationCollectionListener = void Function(
  List<UserConfiguration> added,
  List<UserConfiguration> modified,
  List<UserConfiguration> removed,
);

class UserPresence {
  static const collectionName = 'user_presence';

  String docId;
  String timestamp;
  String conversationId;

  String get userId => docId;

  static UserPresence fromSnapshot(DocSnapshot doc, [UserPresence modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static UserPresence fromData(data, [UserPresence modelObj]) {
    if (data == null) return null;
    return (modelObj ?? UserPresence())
      ..timestamp = String_fromData(data['timestamp'])
      ..conversationId = String_fromData(data['conversation_id']);
  }

  static UserPresence required(Map data, String fieldName, String className) {
    var value = fromData(data[fieldName]);
    if (value == null && !data.containsKey(fieldName))
      throw ValueException("$className.$fieldName is missing");
    return value;
  }

  static UserPresence notNull(Map data, String fieldName, String className) {
    var value = required(data, fieldName, className);
    if (value == null)
      throw ValueException("$className.$fieldName must not be null");
    return value;
  }

  static StreamSubscription listen(DocStorage docStorage, UserPresenceCollectionListener listener,
          {String collectionRoot = '/$collectionName', OnErrorListener onErrorListener}) =>
      listenForUpdates<UserPresence>(docStorage, listener, collectionRoot, UserPresence.fromSnapshot, onErrorListener);

  Map<String, dynamic> toData() {
    return {
      if (timestamp != null) 'timestamp': timestamp,
      if (conversationId != null) 'conversation_id': conversationId,
    };
  }

  @override
  String toString() => 'UserPresence [$docId]: ${toData().toString()}';
}
typedef UserPresenceCollectionListener = void Function(
  List<UserPresence> added,
  List<UserPresence> modified,
  List<UserPresence> removed,
);

typedef OnErrorListener = void Function(
  Object error,
  StackTrace stackTrace
);

// ======================================================================
// Core firebase/yaml utilities

bool bool_fromData(data) {
  if (data == null) return null;
  if (data is bool) return data;
  if (data is String) {
    var boolStr = data.toLowerCase();
    if (boolStr == 'true') return true;
    if (boolStr == 'false') return false;
  }
  log.warning('unknown bool value: ${data?.toString()}');
  return null;
}

bool bool_required(Map data, String fieldName, String className) {
  var value = bool_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

bool bool_notNull(Map data, String fieldName, String className) {
  var value = bool_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

DateTime DateTime_fromData(data) {
  if (data == null) return null;
  var datetime = DateTime.tryParse(data);
  if (datetime != null) return datetime;
  log.warning('unknown DateTime value: ${data?.toString()}');
  return null;
}

DateTime DateTime_required(Map data, String fieldName, String className) {
  var value = DateTime_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

DateTime DateTime_notNull(Map data, String fieldName, String className) {
  var value = DateTime_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

dynamic dynamic_fromData(data) => data;

dynamic dynamic_required(Map data, String fieldName, String className) {
  var value = data[fieldName];
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

dynamic dynamic_notNull(Map data, String fieldName, String className) {
  var value = dynamic_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

int int_fromData(data) {
  if (data == null) return null;
  if (data is int) return data;
  if (data is String) {
    var result = int.tryParse(data);
    if (result is int) return result;
  }
  log.warning('unknown int value: ${data?.toString()}');
  return null;
}

int int_required(Map data, String fieldName, String className) {
  var value = int_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

int int_notNull(Map data, String fieldName, String className) {
  var value = int_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

String String_fromData(data) => data?.toString();

String String_required(Map data, String fieldName, String className) {
  var value = String_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

String String_notNull(Map data, String fieldName, String className) {
  var value = String_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

String String_notEmpty(Map data, String fieldName, String className) {
  var value = String_notNull(data, fieldName, className);
  if (value.isEmpty)
    throw ValueException("$className.$fieldName must not be empty");
  return value;
}

num num_fromData(data) {
  if (data == null) return null;
  if (data is num) return data;
  if (data is String) {
    var result = num.tryParse(data);
    if (result is num) return result;
  }
  log.warning('unknown num value: ${data?.toString()}');
  return null;
}

num num_required(Map data, String fieldName, String className) {
  var value = num_fromData(data[fieldName]);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

num num_notNull(Map data, String fieldName, String className) {
  var value = num_required(data, fieldName, className);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

List<T> List_fromData<T>(dynamic data, T Function(dynamic) createModel) =>
    (data as List)?.map<T>((elem) => createModel(elem))?.toList();

List<T> List_required<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = List_fromData(data[fieldName], createModel);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

List<T> List_notNull<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = List_required(data, fieldName, className, createModel);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

List<T> List_notEmpty<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = List_notNull(data, fieldName, className, createModel);
  if (value.isEmpty)
    throw ValueException("$className.$fieldName must not be empty");
  return value;
}

Map<String, T> Map_fromData<T>(dynamic data, T Function(dynamic) createModel) =>
    (data as Map)?.map<String, T>((key, value) => MapEntry(key.toString(), createModel(value)));

Map<String, T> Map_required<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Map_fromData(data[fieldName], createModel);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

Map<String, T> Map_notNull<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Map_required(data, fieldName, className, createModel);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

Map<String, T> Map_notEmpty<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Map_notNull(data, fieldName, className, createModel);
  if (value.isEmpty)
    throw ValueException("$className.$fieldName must not be empty");
  return value;
}

Set<T> Set_fromData<T>(dynamic data, T Function(dynamic) createModel) =>
    (data as List)?.map<T>((elem) => createModel(elem))?.toSet();

Set<T> Set_required<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Set_fromData(data[fieldName], createModel);
  if (value == null && !data.containsKey(fieldName))
    throw ValueException("$className.$fieldName is missing");
  return value;
}

Set<T> Set_notNull<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Set_required(data, fieldName, className, createModel);
  if (value == null)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

Set<T> Set_notEmpty<T>(Map data, String fieldName, String className, T Function(dynamic) createModel) {
  var value = Set_notNull(data, fieldName, className, createModel);
  if (value.isEmpty)
    throw ValueException("$className.$fieldName must not be null");
  return value;
}

StreamSubscription<List<DocSnapshot>> listenForUpdates<T>(
    DocStorage docStorage,
    void Function(List<T> added, List<T> modified, List<T> removed) listener,
    String collectionRoot,
    T Function(DocSnapshot doc) createModel,
    [OnErrorListener onErrorListener]
    ) {
  log.verbose('Loading from $collectionRoot');
  log.verbose('Query root: $collectionRoot');
  return docStorage.onChange(collectionRoot).listen((List<DocSnapshot> snapshots) {
    var added = <T>[];
    var modified = <T>[];
    var removed = <T>[];
    log.verbose("Starting processing ${snapshots.length} changes.");
    for (var snapshot in snapshots) {
      log.verbose('Processing ${snapshot.id}');
      switch (snapshot.changeType) {
        case DocChangeType.added:
          added.add(createModel(snapshot));
          break;
        case DocChangeType.modified:
          modified.add(createModel(snapshot));
          break;
        case DocChangeType.removed:
          removed.add(createModel(snapshot));
          break;
      }
    }
    listener(added, modified, removed);
  }, onError: onErrorListener);
}

/// Document storage interface.
/// See [FirebaseDocStorage] for a firebase specific version of this.
abstract class DocStorage {
  /// Return a stream of document snapshots
  Stream<List<DocSnapshot>> onChange(String collectionRoot);

  /// Return a object for batching document updates.
  /// Call [DocBatchUpdate.commit] after the changes have been made.
  DocBatchUpdate batch();
}

enum DocChangeType {
  added,
  modified,
  removed
}

/// A snapshot of a document's id and data at a particular moment in time.
class DocSnapshot {
  final String id;
  final Map<String, dynamic> data;
  final DocChangeType changeType;

  DocSnapshot(this.id, this.data, this.changeType);
}

/// A batch update, used to perform multiple writes as a single atomic unit.
/// None of the writes are committed (or visible locally) until
/// [DocBatchUpdate.commit()] is called.
abstract class DocBatchUpdate {
  /// Commits all of the writes in this write batch as a single atomic unit.
  /// Returns non-null [Future] that resolves once all of the writes in the
  /// batch have been successfully written to the backend as an atomic unit.
  /// Note that it won't resolve while you're offline.
  Future<Null> commit();

  /// Updates fields in the document referred to by this [DocumentReference].
  /// The update will fail if applied to a document that does not exist.
  void update(String documentPath, {Map<String, dynamic> data});
}

// ======================================================================
// Core pub/sub utilities

/// A pub/sub based mechanism for updating documents
abstract class DocPubSubUpdate {
  /// Publish the given opinion for the given namespace.
  Future<void> publishAddOpinion(String namespace, Map<String, dynamic> opinion);
}

class ValueException implements Exception {
  String message;

  ValueException(this.message);

  @override
  String toString() => 'ValueException: $message';
}
