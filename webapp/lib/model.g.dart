// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'dart:async';

import 'package:firebase/firestore.dart' as firestore;

import 'logger.dart';

Logger log = Logger('model.g.dart');

class Conversation {
  Map<String, String> demographicsInfo;
  List<String> tagIds;
  List<Message> messages;
  String notes;
  bool unread;

  static Conversation fromSnapshot(DocSnapshot doc, [Conversation modelObj]) =>
      fromData(doc.data, modelObj);

  static Conversation fromData(data, [Conversation modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Conversation())
      ..demographicsInfo = Map_fromData<String>(data['demographicsInfo'], String_fromData)
      ..tagIds = List_fromData<String>(data['tags'], String_fromData)
      ..messages = List_fromData<Message>(data['messages'], Message.fromData)
      ..notes = String_fromData(data['notes'])
      ..unread = bool_fromData(data['unread']) ?? true;
  }

  static void listen(firestore.Firestore fs, ConversationCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Conversation>(fs, listener, collectionRoot, Conversation.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (demographicsInfo != null) 'demographicsInfo': demographicsInfo,
      if (tagIds != null) 'tags': tagIds,
      if (messages != null) 'messages': messages.map((elem) => elem?.toData()).toList(),
      if (notes != null) 'notes': notes,
      if (unread != null) 'unread': unread,
    };
  }

  DocBatchUpdate updateTagIds(firestore.Firestore fs, String documentPath, List<String> newValue, [DocBatchUpdate batch]) {
    tagIds = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'tags': newValue});
    return batch;
  }

  DocBatchUpdate updateMessages(firestore.Firestore fs, String documentPath, List<Message> newValue, [DocBatchUpdate batch]) {
    messages = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'messages': newValue?.map((elem) => elem?.toData())?.toList()});
    return batch;
  }

  DocBatchUpdate updateNotes(firestore.Firestore fs, String documentPath, String newValue, [DocBatchUpdate batch]) {
    notes = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'notes': newValue});
    return batch;
  }

  DocBatchUpdate updateUnread(firestore.Firestore fs, String documentPath, bool newValue, [DocBatchUpdate batch]) {
    unread = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'unread': newValue});
    return batch;
  }
}
typedef void ConversationCollectionListener(List<Conversation> changes);

class Message {
  MessageDirection direction;
  DateTime datetime;
  MessageStatus status;
  List<String> tagIds;
  String text;
  String translation;

  static Message fromSnapshot(DocSnapshot doc, [Message modelObj]) =>
      fromData(doc.data, modelObj);

  static Message fromData(data, [Message modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Message())
      ..direction = MessageDirection.fromString(data['direction'] as String) ?? MessageDirection.Out
      ..datetime = DateTime_fromData(data['datetime']) ?? DateTime.now()
      ..status = MessageStatus.fromString(data['status'] as String)
      ..tagIds = List_fromData<String>(data['tags'], String_fromData)
      ..text = String_fromData(data['text'])
      ..translation = String_fromData(data['translation']);
  }

  static void listen(firestore.Firestore fs, MessageCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Message>(fs, listener, collectionRoot, Message.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (direction != null) 'direction': direction.toString(),
      if (datetime != null) 'datetime': datetime.toIso8601String(),
      if (status != null) 'status': status.toString(),
      if (tagIds != null) 'tags': tagIds,
      if (text != null) 'text': text,
      if (translation != null) 'translation': translation,
    };
  }

  DocBatchUpdate updateTagIds(firestore.Firestore fs, String documentPath, List<String> newValue, [DocBatchUpdate batch]) {
    tagIds = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'tags': newValue});
    return batch;
  }

  DocBatchUpdate updateTranslation(firestore.Firestore fs, String documentPath, String newValue, [DocBatchUpdate batch]) {
    translation = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'translation': newValue});
    return batch;
  }
}
typedef void MessageCollectionListener(List<Message> changes);

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
    log.warning('unknown MessageStatus $text');
    return defaultValue;
  }

  final String name;
  const MessageStatus(this.name);
  String toString() => 'MessageStatus.$name';
}
MessageStatus Function(String text) MessageStatus_fromStringOverride;

class SuggestedReply {
  static const collectionName = 'suggestedReplies';

  String suggestedReplyId;
  String text;
  String translation;
  String shortcut;

  static SuggestedReply fromSnapshot(DocSnapshot doc, [SuggestedReply modelObj]) =>
      fromData(doc.data, modelObj)..suggestedReplyId = doc.id;

  static SuggestedReply fromData(data, [SuggestedReply modelObj]) {
    if (data == null) return null;
    return (modelObj ?? SuggestedReply())
      ..text = String_fromData(data['text'])
      ..translation = String_fromData(data['translation'])
      ..shortcut = String_fromData(data['shortcut']);
  }

  static void listen(firestore.Firestore fs, SuggestedReplyCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<SuggestedReply>(fs, listener, collectionRoot, SuggestedReply.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (translation != null) 'translation': translation,
      if (shortcut != null) 'shortcut': shortcut,
    };
  }

  DocBatchUpdate updateText(firestore.Firestore fs, String documentPath, String newValue, [DocBatchUpdate batch]) {
    text = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'text': newValue});
    return batch;
  }

  DocBatchUpdate updateTranslation(firestore.Firestore fs, String documentPath, String newValue, [DocBatchUpdate batch]) {
    translation = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'translation': newValue});
    return batch;
  }
}
typedef void SuggestedReplyCollectionListener(List<SuggestedReply> changes);

class Tag {
  String tagId;
  String text;
  TagType type;
  String shortcut;

  static Tag fromSnapshot(DocSnapshot doc, [Tag modelObj]) =>
      fromData(doc.data, modelObj)..tagId = doc.id;

  static Tag fromData(data, [Tag modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Tag())
      ..text = String_fromData(data['text'])
      ..type = TagType.fromString(data['type'] as String) ?? TagType.Normal
      ..shortcut = String_fromData(data['shortcut']);
  }

  static void listen(firestore.Firestore fs, TagCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Tag>(fs, listener, collectionRoot, Tag.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (type != null) 'type': type.toString(),
      if (shortcut != null) 'shortcut': shortcut,
    };
  }

  DocBatchUpdate updateText(firestore.Firestore fs, String documentPath, String newValue, [DocBatchUpdate batch]) {
    text = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'text': newValue});
    return batch;
  }

  DocBatchUpdate updateType(firestore.Firestore fs, String documentPath, TagType newValue, [DocBatchUpdate batch]) {
    type = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'type': newValue?.toString()});
    return batch;
  }

  DocBatchUpdate updateShortcut(firestore.Firestore fs, String documentPath, String newValue, [DocBatchUpdate batch]) {
    shortcut = newValue;
    batch ??= FirebaseBatchUpdate(fs.batch());
    batch.update(fs.doc(documentPath), data: {'shortcut': newValue});
    return batch;
  }
}
typedef void TagCollectionListener(List<Tag> changes);

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

  String msgId;
  String text;
  bool expired;

  static SystemMessage fromSnapshot(DocSnapshot doc, [SystemMessage modelObj]) =>
      fromData(doc.data, modelObj)..msgId = doc.id;

  static SystemMessage fromData(data, [SystemMessage modelObj]) {
    if (data == null) return null;
    return (modelObj ?? SystemMessage())
      ..text = String_fromData(data['text'])
      ..expired = bool_fromData(data['expired']) ?? false;
  }

  static void listen(firestore.Firestore fs, SystemMessageCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<SystemMessage>(fs, listener, collectionRoot, SystemMessage.fromSnapshot);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (expired != null) 'expired': expired,
    };
  }
}
typedef void SystemMessageCollectionListener(List<SystemMessage> changes);

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

StreamSubscription<List<DocSnapshot>> listenForUpdates<T>(
    firestore.Firestore fs,
    void listener(List<T> changes),
    String collectionRoot,
    T createModel(DocSnapshot doc),
    ) {
  log.verbose('Loading from $collectionRoot');
  log.verbose('Query root: $collectionRoot');
  return FirestoreDocStorage(fs).onChange(collectionRoot).listen((List<DocSnapshot> snapshots) {
    List<T> changes = [];
    log.verbose("Starting processing ${snapshots.length} changes.");
    for (var snapshot in snapshots) {
      log.verbose('Processing ${snapshot.id}');
      changes.add(createModel(snapshot));
    }
    listener(changes);
  });
}

/// Document storage interface.
/// See [FirestoreDocStorage] for a firebase specific version of this.
abstract class DocStorage {
  Stream<List<DocSnapshot>> onChange(String collectionRoot);
}

/// Firebase specific document storage.
class FirestoreDocStorage implements DocStorage {
  final firestore.Firestore fs;

  FirestoreDocStorage(this.fs);

  @override
  Stream<List<DocSnapshot>> onChange(String collectionRoot) {
    return fs.collection(collectionRoot).onSnapshot.transform<List<DocSnapshot>>(StreamTransformer.fromHandlers(
      handleData: (firestore.QuerySnapshot querySnapshot, EventSink<List<DocSnapshot>> sink) {
        // No need to process local writes to Firebase
        if (querySnapshot.metadata.hasPendingWrites) {
          log.verbose('Skipping processing of local changes');
          return;
        }
        var event = <DocSnapshot>[];
        for (var change in querySnapshot.docChanges()) {
          var doc = change.doc;
          event.add(DocSnapshot(doc.id, doc.data()));
        }
        sink.add(event);
      },
    ));
  }
}

/// A snapshot of a document's id and data at a particular moment in time.
class DocSnapshot {
  final String id;
  final Map<String, dynamic> data;

  DocSnapshot(this.id, this.data);
}

/// A batch update, used to perform multiple writes as a single atomic unit.
/// None of the writes are committed (or visible locally) until
/// [DocUpdate.commit()] is called.
abstract class DocBatchUpdate {
  /// Commits all of the writes in this write batch as a single atomic unit.
  /// Returns non-null [Future] that resolves once all of the writes in the
  /// batch have been successfully written to the backend as an atomic unit.
  /// Note that it won't resolve while you're offline.
  Future<Null> commit();

  /// Updates fields in the document referred to by this [DocumentReference].
  /// The update will fail if applied to a document that does not exist.
  void update(firestore.DocumentReference doc, {Map<String, dynamic> data});
}

/// A batch update for documents in firestore.
class FirebaseBatchUpdate implements DocBatchUpdate {
  final firestore.WriteBatch _batch;

  FirebaseBatchUpdate(this._batch);

  @override
  Future<Null> commit() => _batch.commit();

  @override
  void update(firestore.DocumentReference doc, {Map<String, dynamic> data}) {
    _batch.update(doc, data: data);
  }
}

// ======================================================================
// Core pub/sub utilities
