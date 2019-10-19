// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'package:firebase/firestore.dart' as firestore;

import 'logger.dart';

Logger log = Logger('model.g.dart');

class Conversation {
  Map<String, String> demographicsInfo;
  List<Tag> tags;
  List<Message> messages;
  String notes;

  static Conversation fromFirestore(firestore.DocumentSnapshot doc, [Conversation obj]) =>
      fromData(doc.data(), obj);

  static Conversation fromData(Map data, [Conversation obj]) {
    return (obj ?? Conversation())
      ..demographicsInfo = toMapString(data['demographicsInfo'])
      ..notes = data['notes'];
  }

  static void listen(firestore.Firestore fs, ConversationCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Conversation>(fs, listener, collectionRoot, Conversation.fromFirestore);
}
typedef ConversationCollectionListener(List<Conversation> changes);

class Message {
  MessageDirection direction;
  DateTime datetime;
  List<Tag> tags;
  String text;
  String translation;

  static Message fromFirestore(firestore.DocumentSnapshot doc, [Message obj]) =>
      fromData(doc.data(), obj);

  static Message fromData(Map data, [Message obj]) {
    return (obj ?? Message())
      ..direction = MessageDirection_fromString(data['direction'] as String)
      ..datetime = DateTime.parse(data['datetime'])
      ..text = data['text']
      ..translation = data['translation'];
  }

  static void listen(firestore.Firestore fs, MessageCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Message>(fs, listener, collectionRoot, Message.fromFirestore);
}
typedef MessageCollectionListener(List<Message> changes);

enum MessageDirection {
  In,
  Out,
}
MessageDirection MessageDirection_fromString(String text, [MessageDirection defaultValue = MessageDirection.Out]) {
  if (text == 'in') return MessageDirection.In;
  if (text == 'out') return MessageDirection.Out;
  return defaultValue;
}
String MessageDirection_toString(MessageDirection value, [String defaultText = 'out']) {
  if (value == MessageDirection.In) return 'in';
  if (value == MessageDirection.Out) return 'out';
  return defaultText;
}

class SuggestedReply {
  String suggestedReplyId;
  String text;
  String translation;
  String shortcut;

  static SuggestedReply fromFirestore(firestore.DocumentSnapshot doc, [SuggestedReply obj]) =>
      fromData(doc.data(), obj)..suggestedReplyId = doc.id;

  static SuggestedReply fromData(Map data, [SuggestedReply obj]) {
    return (obj ?? SuggestedReply())
      ..text = data['text']
      ..translation = data['translation']
      ..shortcut = data['shortcut'];
  }

  static void listen(firestore.Firestore fs, SuggestedReplyCollectionListener listener, String collectionRoot) =>
      listenForUpdates<SuggestedReply>(fs, listener, collectionRoot, SuggestedReply.fromFirestore);
}
typedef SuggestedReplyCollectionListener(List<SuggestedReply> changes);

class Tag {
  String tagId;
  String text;
  TagType type;
  String shortcut;

  static Tag fromFirestore(firestore.DocumentSnapshot doc, [Tag obj]) =>
      fromData(doc.data(), obj)..tagId = doc.id;

  static Tag fromData(Map data, [Tag obj]) {
    return (obj ?? Tag())
      ..text = data['text']
      ..type = TagType_fromString(data['type'] as String)
      ..shortcut = data['shortcut'];
  }

  static void listen(firestore.Firestore fs, TagCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Tag>(fs, listener, collectionRoot, Tag.fromFirestore);
}
typedef TagCollectionListener(List<Tag> changes);

enum TagType {
  Normal,
  Important,
}
TagType TagType_fromString(String text, [TagType defaultValue = TagType.Normal]) {
  if (text == 'normal') return TagType.Normal;
  if (text == 'important') return TagType.Important;
  return defaultValue;
}
String TagType_toString(TagType value, [String defaultText = 'normal']) {
  if (value == TagType.Normal) return 'normal';
  if (value == TagType.Important) return 'important';
  return defaultText;
}

Map<String, String> toMapString(dynamic data) =>
    (data as Map).map<String, String>((key, value) => MapEntry(key.toString(), value.toString()));

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
