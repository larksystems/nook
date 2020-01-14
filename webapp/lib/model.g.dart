// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'package:firebase/firestore.dart' as firestore;

import 'logger.dart';

Logger log = Logger('model.g.dart');

class Conversation {
  Map<String, String> demographicsInfo;
  List<String> tagIds;
  List<Message> messages;
  String notes;
  bool unread;

  static Conversation fromFirestore(DocSnapshot doc, [Conversation modelObj]) =>
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
      listenForUpdates<Conversation>(fs, listener, collectionRoot, Conversation.fromFirestore);

  Map<String, dynamic> toData() {
    return {
      if (demographicsInfo != null) 'demographicsInfo': demographicsInfo,
      if (tagIds != null) 'tags': tagIds,
      if (messages != null) 'messages': messages.map((elem) => elem?.toData()).toList(),
      if (notes != null) 'notes': notes,
      if (unread != null) 'unread': unread,
    };
  }

  firestore.WriteBatch updateTagIds(firestore.Firestore fs, String documentPath, List<String> newValue, [firestore.WriteBatch batch]) {
    tagIds = newValue;
    batch ??= fs.batch();
    batch.update(fs.doc(documentPath), data: {'tags': newValue});
    return batch;
  }

  firestore.WriteBatch updateMessages(firestore.Firestore fs, String documentPath, List<Message> newValue, [firestore.WriteBatch batch]) {
    messages = newValue;
    batch ??= fs.batch();
    batch.update(fs.doc(documentPath), data: {'messages': newValue?.map((elem) => elem?.toData())?.toList()});
    return batch;
  }

  firestore.WriteBatch updateNotes(firestore.Firestore fs, String documentPath, String newValue, [firestore.WriteBatch batch]) {
    notes = newValue;
    batch ??= fs.batch();
    batch.update(fs.doc(documentPath), data: {'notes': newValue});
    return batch;
  }

  firestore.WriteBatch updateUnread(firestore.Firestore fs, String documentPath, bool newValue, [firestore.WriteBatch batch]) {
    unread = newValue;
    batch ??= fs.batch();
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

  static Message fromFirestore(DocSnapshot doc, [Message modelObj]) =>
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
      listenForUpdates<Message>(fs, listener, collectionRoot, Message.fromFirestore);

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

  firestore.WriteBatch updateTagIds(firestore.Firestore fs, String documentPath, List<String> newValue, [firestore.WriteBatch batch]) {
    tagIds = newValue;
    batch ??= fs.batch();
    batch.update(fs.doc(documentPath), data: {'tags': newValue});
    return batch;
  }

  firestore.WriteBatch updateTranslation(firestore.Firestore fs, String documentPath, String newValue, [firestore.WriteBatch batch]) {
    translation = newValue;
    batch ??= fs.batch();
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

  static SuggestedReply fromFirestore(DocSnapshot doc, [SuggestedReply modelObj]) =>
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
      listenForUpdates<SuggestedReply>(fs, listener, collectionRoot, SuggestedReply.fromFirestore);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (translation != null) 'translation': translation,
      if (shortcut != null) 'shortcut': shortcut,
    };
  }

  firestore.WriteBatch updateText(firestore.Firestore fs, String documentPath, String newValue, [firestore.WriteBatch batch]) {
    text = newValue;
    batch ??= fs.batch();
    batch.update(fs.doc(documentPath), data: {'text': newValue});
    return batch;
  }

  firestore.WriteBatch updateTranslation(firestore.Firestore fs, String documentPath, String newValue, [firestore.WriteBatch batch]) {
    translation = newValue;
    batch ??= fs.batch();
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

  static Tag fromFirestore(DocSnapshot doc, [Tag modelObj]) =>
      fromData(doc.data, modelObj)..tagId = doc.id;

  static Tag fromData(data, [Tag modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Tag())
      ..text = String_fromData(data['text'])
      ..type = TagType.fromString(data['type'] as String) ?? TagType.Normal
      ..shortcut = String_fromData(data['shortcut']);
  }

  static void listen(firestore.Firestore fs, TagCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Tag>(fs, listener, collectionRoot, Tag.fromFirestore);

  Map<String, dynamic> toData() {
    return {
      if (text != null) 'text': text,
      if (type != null) 'type': type.toString(),
      if (shortcut != null) 'shortcut': shortcut,
    };
  }

  firestore.WriteBatch updateText(firestore.Firestore fs, String documentPath, String newValue, [firestore.WriteBatch batch]) {
    text = newValue;
    batch ??= fs.batch();
    batch.update(fs.doc(documentPath), data: {'text': newValue});
    return batch;
  }

  firestore.WriteBatch updateType(firestore.Firestore fs, String documentPath, TagType newValue, [firestore.WriteBatch batch]) {
    type = newValue;
    batch ??= fs.batch();
    batch.update(fs.doc(documentPath), data: {'type': newValue?.toString()});
    return batch;
  }

  firestore.WriteBatch updateShortcut(firestore.Firestore fs, String documentPath, String newValue, [firestore.WriteBatch batch]) {
    shortcut = newValue;
    batch ??= fs.batch();
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

  static SystemMessage fromFirestore(DocSnapshot doc, [SystemMessage modelObj]) =>
      fromData(doc.data, modelObj)..msgId = doc.id;

  static SystemMessage fromData(data, [SystemMessage modelObj]) {
    if (data == null) return null;
    return (modelObj ?? SystemMessage())
      ..text = String_fromData(data['text'])
      ..expired = bool_fromData(data['expired']) ?? false;
  }

  static void listen(firestore.Firestore fs, SystemMessageCollectionListener listener,
          {String collectionRoot = '/$collectionName'}) =>
      listenForUpdates<SystemMessage>(fs, listener, collectionRoot, SystemMessage.fromFirestore);

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

void listenForUpdates<T>(
    firestore.Firestore fs,
    void listener(List<T> changes),
    String collectionRoot,
    T createModel(DocSnapshot doc),
    ) async {
  log.verbose('Loading from $collectionRoot');
  log.verbose('Query root: $collectionRoot');

  fs.collection(collectionRoot).onSnapshot.listen((querySnapshot) {
    // No need to process local writes to Firebase
    if (querySnapshot.metadata.hasPendingWrites) {
      log.verbose('Skipping processing of local changes');
      return;
    }

    List<T> changes = [];
    var docChanges = querySnapshot.docChanges();
    log.verbose("Starting processing ${docChanges.length} changes.");
    querySnapshot.docChanges().forEach((documentChange) {
      var doc = documentChange.doc;
      log.verbose('Processing ${doc.id}');
      changes.add(createModel(DocSnapshot(doc.id, doc.data())));
    });
    listener(changes);
  });
}

class DocSnapshot {
  final String id;
  final Map<String, dynamic> data;

  DocSnapshot(this.id, this.data);
}

// ======================================================================
// Core pub/sub utilities
