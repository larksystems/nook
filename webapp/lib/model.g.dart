// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'dart:async';

import 'logger.dart';

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

  static StreamSubscription listen(DocStorage docStorage, ConversationListShardCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<ConversationListShard>(docStorage, listener, collectionRoot, ConversationListShard.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (name != null) 'name': name,
    };
  }

  String toString() => 'ConversationListShard [$docId]: ${toData().toString()}';
}
typedef void ConversationListShardCollectionListener(
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

  static StreamSubscription listen(DocStorage docStorage, ConversationCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<Conversation>(docStorage, listener, collectionRoot, Conversation.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (demographicsInfo != null) 'demographicsInfo': demographicsInfo,
      if (tagIds != null) 'tags': tagIds.toList(),
      if (lastInboundTurnTagIds != null) 'lastInboundTurnTags': tagIds.toList(),
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
      'tags': tagIds,
    });
  }

  /// Remove [oldTagIds] from tagIds in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> removeTagIds(DocPubSubUpdate pubSubClient, Iterable<String> oldTagIds) {
    var toBeRemoved = Set<String>();
    for (var elem in oldTagIds) {
      if (tagIds.contains(elem)) {
        toBeRemoved.add(elem);
      }
    }
    if (toBeRemoved.isEmpty) return Future.value(null);
    tagIds.removeAll(toBeRemoved);
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

  String toString() => 'Conversation [$docId]: ${toData().toString()}';
}
typedef void ConversationCollectionListener(
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
      ..direction = MessageDirection.fromString(data['direction'] as String) ?? MessageDirection.Out
      ..datetime = DateTime_fromData(data['datetime'])
      ..status = MessageStatus.fromString(data['status'] as String)
      ..tagIds = List_fromData<String>(data['tags'], String_fromData)
      ..text = String_fromData(data['text'])
      ..translation = String_fromData(data['translation'])
      ..id = String_fromData(data['id']);
  }

  Map<String, dynamic> toData() {
    return {
      if (direction != null) 'direction': direction.toString(),
      if (datetime != null) 'datetime': datetime.toIso8601String(),
      if (status != null) 'status': status.toString(),
      if (tagIds != null) 'tags': tagIds,
      if (text != null) 'text': text,
      if (translation != null) 'translation': translation,
      if (id != null) 'id': id,
    };
  }

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
    if (MessageDirection_fromStringOverride != null) {
      var value = MessageDirection_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'MessageDirection.';
      String valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown MessageDirection $text');
    return defaultValue;
  }

  final String name;
  const MessageDirection(this.name);
  String toString() => 'MessageDirection.$name';
}
MessageDirection Function(String text) MessageDirection_fromStringOverride;

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
    if (MessageStatus_fromStringOverride != null) {
      var value = MessageStatus_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'MessageStatus.';
      String valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    // This is commented out because it generates too much noise in the logs
    // log.warning('unknown MessageStatus $text');
    return defaultValue;
  }

  final String name;
  const MessageStatus(this.name);
  String toString() => 'MessageStatus.$name';
}
MessageStatus Function(String text) MessageStatus_fromStringOverride;

class SuggestedReply {
  static const collectionName = 'suggestedReplies';

  String docId;
  String text;
  String translation;
  String shortcut;
  int seqNumber;
  String category;

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
      ..category = String_fromData(data['category']);
  }

  static StreamSubscription listen(DocStorage docStorage, SuggestedReplyCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<SuggestedReply>(docStorage, listener, collectionRoot, SuggestedReply.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (translation != null) 'translation': translation,
      if (shortcut != null) 'shortcut': shortcut,
      if (seqNumber != null) 'seq_no': seqNumber,
      if (category != null) 'category': category,
    };
  }

  String toString() => 'SuggestedReply [$docId]: ${toData().toString()}';
}
typedef void SuggestedReplyCollectionListener(
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

  String get tagId => docId;

  static Tag fromSnapshot(DocSnapshot doc, [Tag modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static Tag fromData(data, [Tag modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Tag())
      ..text = String_fromData(data['text'])
      ..type = TagType.fromString(data['type'] as String) ?? TagType.Normal
      ..shortcut = String_fromData(data['shortcut'])
      ..filterable = bool_fromData(data['filterable'])
      ..group = String_fromData(data['group']) ?? '';
  }

  static void listen(DocStorage docStorage, TagCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Tag>(docStorage, listener, collectionRoot, Tag.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (type != null) 'type': type.toString(),
      if (shortcut != null) 'shortcut': shortcut,
      if (filterable != null) 'filterable': filterable,
      if (group != null) 'group': group,
    };
  }

  String toString() => 'Tag [$docId]: ${toData().toString()}';
}
typedef void TagCollectionListener(
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
    if (TagType_fromStringOverride != null) {
      var value = TagType_fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      const prefix = 'TagType.';
      String valueName = text.startsWith(prefix) ? text.substring(prefix.length) : text;
      for (var value in values) {
        if (value.name == valueName) return value;
      }
    }
    log.warning('unknown TagType $text');
    return defaultValue;
  }

  final String name;
  const TagType(this.name);
  String toString() => 'TagType.$name';
}
TagType Function(String text) TagType_fromStringOverride;

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

  static StreamSubscription listen(DocStorage docStorage, SystemMessageCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<SystemMessage>(docStorage, listener, collectionRoot, SystemMessage.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (expired != null) 'expired': expired,
    };
  }

  String toString() => 'SystemMessage [$docId]: ${toData().toString()}';
}
typedef void SystemMessageCollectionListener(
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
      ..repliesPanelVisibility = bool_fromData(data['replies_panel_visibility']);
  }

  static StreamSubscription listen(DocStorage docStorage, UserConfigurationCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<UserConfiguration>(docStorage, listener, collectionRoot, UserConfiguration.fromSnapshot);

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
    };
  }

  String toString() => 'UserConfiguration [$docId]: ${toData().toString()}';
}
typedef void UserConfigurationCollectionListener(
  List<UserConfiguration> added,
  List<UserConfiguration> modified,
  List<UserConfiguration> removed,
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

DateTime DateTime_fromData(data) {
  if (data == null) return null;
  var datetime = DateTime.tryParse(data);
  if (datetime != null) return datetime;
  log.warning('unknown DateTime value: ${data?.toString()}');
  return null;
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

String String_fromData(data) => data?.toString();

List<T> List_fromData<T>(dynamic data, T createModel(data)) =>
    (data as List)?.map<T>((elem) => createModel(elem))?.toList();

Map<String, T> Map_fromData<T>(dynamic data, T createModel(data)) =>
    (data as Map)?.map<String, T>((key, value) => MapEntry(key.toString(), createModel(value)));

Set<T> Set_fromData<T>(dynamic data, T createModel(data)) =>
    (data as List)?.map<T>((elem) => createModel(elem))?.toSet();

StreamSubscription<List<DocSnapshot>> listenForUpdates<T>(
    DocStorage docStorage,
    void listener(List<T> added, List<T> modified, List<T> removed),
    String collectionRoot,
    T createModel(DocSnapshot doc),
    ) {
  log.verbose('Loading from $collectionRoot');
  log.verbose('Query root: $collectionRoot');
  return docStorage.onChange(collectionRoot).listen((List<DocSnapshot> snapshots) {
    List<T> added = [];
    List<T> modified = [];
    List<T> removed = [];
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
  });
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
