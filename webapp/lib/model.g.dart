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

  static Conversation fromFirestore(firestore.DocumentSnapshot doc, [Conversation modelObj]) =>
      fromData(doc.data(), modelObj);

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
}
typedef void ConversationCollectionListener(List<Conversation> changes);

class Message {
  MessageDirection direction;
  DateTime datetime;
  List<String> tagIds;
  String text;
  String translation;

  static Message fromFirestore(firestore.DocumentSnapshot doc, [Message modelObj]) =>
      fromData(doc.data(), modelObj);

  static Message fromData(data, [Message modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Message())
      ..direction = MessageDirection.fromString(data['direction'] as String) ?? MessageDirection.Out
      ..datetime = DateTime_fromData(data['datetime']) ?? DateTime.now()
      ..tagIds = List_fromData<String>(data['tags'], String_fromData)
      ..text = String_fromData(data['text'])
      ..translation = String_fromData(data['translation']);
  }

  static void listen(firestore.Firestore fs, MessageCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Message>(fs, listener, collectionRoot, Message.fromFirestore);
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
    if (fromStringOverride != null) {
      var value = fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      String valueName = text.startsWith('MessageDirection.') ? text.substring(17) : text;
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
  static MessageDirection Function(String text) fromStringOverride;
}

class SuggestedReply {
  String suggestedReplyId;
  String text;
  String translation;
  String shortcut;

  static SuggestedReply fromFirestore(firestore.DocumentSnapshot doc, [SuggestedReply modelObj]) =>
      fromData(doc.data(), modelObj)..suggestedReplyId = doc.id;

  static SuggestedReply fromData(data, [SuggestedReply modelObj]) {
    if (data == null) return null;
    return (modelObj ?? SuggestedReply())
      ..text = String_fromData(data['text'])
      ..translation = String_fromData(data['translation'])
      ..shortcut = String_fromData(data['shortcut']);
  }

  static void listen(firestore.Firestore fs, SuggestedReplyCollectionListener listener, String collectionRoot) =>
      listenForUpdates<SuggestedReply>(fs, listener, collectionRoot, SuggestedReply.fromFirestore);
}
typedef void SuggestedReplyCollectionListener(List<SuggestedReply> changes);

class Tag {
  String tagId;
  String text;
  TagType type;
  String shortcut;

  static Tag fromFirestore(firestore.DocumentSnapshot doc, [Tag modelObj]) =>
      fromData(doc.data(), modelObj)..tagId = doc.id;

  static Tag fromData(data, [Tag modelObj]) {
    if (data == null) return null;
    return (modelObj ?? Tag())
      ..text = String_fromData(data['text'])
      ..type = TagType.fromString(data['type'] as String) ?? TagType.Normal
      ..shortcut = String_fromData(data['shortcut']);
  }

  static void listen(firestore.Firestore fs, TagCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Tag>(fs, listener, collectionRoot, Tag.fromFirestore);
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
    if (fromStringOverride != null) {
      var value = fromStringOverride(text);
      if (value != null) return value;
    }
    if (text != null) {
      String valueName = text.startsWith('TagType.') ? text.substring(8) : text;
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
  static TagType Function(String text) fromStringOverride;
}

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
    T createModel(firestore.DocumentSnapshot doc),
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
      changes.add(createModel(doc));
    });
    listener(changes);
  });
}
