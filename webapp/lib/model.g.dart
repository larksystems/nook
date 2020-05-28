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
      if (messages != null) 'messages': messages.map((elem) => elem?.toData()).toList(),
      if (notes != null) 'notes': notes,
      if (unread != null) 'unread': unread,
    };
  }

  /// Add [tagId] to tagIds in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> addTagId(DocPubSubUpdate pubSubClient, String tagId) {
    return addTagIdToAll(pubSubClient, [this], tagId);
  }

  /// Add [tagId] to tagIds in each Conversation.
  /// Callers should catch and handle IOException.
  static Future<void> addTagIdToAll(DocPubSubUpdate pubSubClient, List<Conversation> docs, String tagId) async {
    final docIdsToPublish = <String>[];
    for (var doc in docs) {
      if (!doc.tagIds.contains(tagId)) {
        doc.tagIds.add(tagId);
        docIdsToPublish.add(doc.docId);
      }
    }
    if (docIdsToPublish.isEmpty) return;
    return pubSubClient.publishDocAdd(collectionName, docIdsToPublish, {"tags": [tagId]});
  }

  /// Set tagIds in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> setTagIds(DocPubSubUpdate pubSubClient, Set<String> tagIds) {
    return setTagIdsForAll(pubSubClient, [this], tagIds);
  }

  /// Set tagIds in each Conversation.
  /// Callers should catch and handle IOException.
  static Future<void> setTagIdsForAll(DocPubSubUpdate pubSubClient, List<Conversation> docs, Set<String> tagIds) async {
    final docIdsToPublish = <String>[];
    for (var doc in docs) {
      if (doc.tagIds != tagIds) {
        doc.tagIds = tagIds;
        docIdsToPublish.add(doc.docId);
      }
    }
    if (docIdsToPublish.isEmpty) return;
    return pubSubClient.publishDocChange(collectionName, docIdsToPublish, {"tags": tagIds?.toList()});
  }

  /// Remove [tagId] from tagIds in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> removeTagId(DocPubSubUpdate pubSubClient, String tagId) {
    return removeTagIdFromAll(pubSubClient, [this], tagId);
  }

  /// Remove [tagId] from tagIds in each Conversation.
  /// Callers should catch and handle IOException.
  static Future<void> removeTagIdFromAll(DocPubSubUpdate pubSubClient, List<Conversation> docs, String tagId) async {
    final docIdsToPublish = <String>[];
    for (var doc in docs) {
      if (doc.tagIds.contains(tagId)) {
        doc.tagIds.remove(tagId);
        docIdsToPublish.add(doc.docId);
      }
    }
    if (docIdsToPublish.isEmpty) return;
    return pubSubClient.publishDocRemove(collectionName, docIdsToPublish, {"tags": [tagId]});
  }

  /// Set notes in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> setNotes(DocPubSubUpdate pubSubClient, String notes) {
    return setNotesForAll(pubSubClient, [this], notes);
  }

  /// Set notes in each Conversation.
  /// Callers should catch and handle IOException.
  static Future<void> setNotesForAll(DocPubSubUpdate pubSubClient, List<Conversation> docs, String notes) async {
    final docIdsToPublish = <String>[];
    for (var doc in docs) {
      if (doc.notes != notes) {
        doc.notes = notes;
        docIdsToPublish.add(doc.docId);
      }
    }
    if (docIdsToPublish.isEmpty) return;
    return pubSubClient.publishDocChange(collectionName, docIdsToPublish, {"notes": notes});
  }

  /// Set unread in this Conversation.
  /// Callers should catch and handle IOException.
  Future<void> setUnread(DocPubSubUpdate pubSubClient, bool unread) {
    return setUnreadForAll(pubSubClient, [this], unread);
  }

  /// Set unread in each Conversation.
  /// Callers should catch and handle IOException.
  static Future<void> setUnreadForAll(DocPubSubUpdate pubSubClient, List<Conversation> docs, bool unread) async {
    final docIdsToPublish = <String>[];
    for (var doc in docs) {
      if (doc.unread != unread) {
        doc.unread = unread;
        docIdsToPublish.add(doc.docId);
      }
    }
    if (docIdsToPublish.isEmpty) return;
    return pubSubClient.publishDocChange(collectionName, docIdsToPublish, {"unread": unread});
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

  /// Set translation in this SuggestedReply.
  /// Callers should catch and handle IOException.
  Future<void> setTranslation(DocPubSubUpdate pubSubClient, String translation) {
    return setTranslationForAll(pubSubClient, [this], translation);
  }

  /// Set translation in each SuggestedReply.
  /// Callers should catch and handle IOException.
  static Future<void> setTranslationForAll(DocPubSubUpdate pubSubClient, List<SuggestedReply> docs, String translation) async {
    final docIdsToPublish = <String>[];
    for (var doc in docs) {
      if (doc.translation != translation) {
        doc.translation = translation;
        docIdsToPublish.add(doc.docId);
      }
    }
    if (docIdsToPublish.isEmpty) return;
    return pubSubClient.publishDocChange(collectionName, docIdsToPublish, {"translation": translation});
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
  bool keyboardShortcutsEnabled;
  bool sendCustomMessagesEnabled;
  bool sendMultiMessageEnabled;
  bool tagPanelVisibility;

  String get userId => docId;

  static UserConfiguration fromSnapshot(DocSnapshot doc, [UserConfiguration modelObj]) =>
      fromData(doc.data, modelObj)..docId = doc.id;

  static UserConfiguration fromData(data, [UserConfiguration modelObj]) {
    if (data == null) return null;
    return (modelObj ?? UserConfiguration())
      ..keyboardShortcutsEnabled = bool_fromData(data['keyboard_shortcuts_enabled'])
      ..sendCustomMessagesEnabled = bool_fromData(data['send_custom_messages_enabled'])
      ..sendMultiMessageEnabled = bool_fromData(data['send_multi_message_enabled'])
      ..tagPanelVisibility = bool_fromData(data['tag_panel_visibility']);
  }

  static StreamSubscription listen(DocStorage docStorage, UserConfigurationCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<UserConfiguration>(docStorage, listener, collectionRoot, UserConfiguration.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (keyboardShortcutsEnabled != null) 'keyboard_shortcuts_enabled': keyboardShortcutsEnabled,
      if (sendCustomMessagesEnabled != null) 'send_custom_messages_enabled': sendCustomMessagesEnabled,
      if (sendMultiMessageEnabled != null) 'send_multi_message_enabled': sendMultiMessageEnabled,
      if (tagPanelVisibility != null) 'tag_panel_visibility': tagPanelVisibility,
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

  /// Publish the given document list/set additions,
  /// where [additions] is a mapping of field name to new values to be added to the list/set.
  /// Callers should catch and handle IOException.
  Future<void> publishDocAdd(String collectionName, List<String> docIds, Map<String, List<dynamic>> additions);

  /// Publish the given document changes,
  /// where [changes] is a mapping of field name to new value.
  /// Callers should catch and handle IOException.
  Future<void> publishDocChange(String collectionName, List<String> docIds, Map<String, dynamic> changes);

  /// Publish the given document list/set removals,
  /// where [removals] is a mapping of field name to old values to be removed from the list/set.
  /// Callers should catch and handle IOException.
  Future<void> publishDocRemove(String collectionName, List<String> docIds, Map<String, List<dynamic>> removals);
}
