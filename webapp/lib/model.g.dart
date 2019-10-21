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

  static Conversation fromFirestore(firestore.DocumentSnapshot doc, [Conversation modelObj]) =>
      fromData(doc.data(), modelObj);

  static Conversation fromData(data, [Conversation modelObj]) {
    return (modelObj ?? Conversation())
      ..demographicsInfo = toMap<String>(data['demographicsInfo'], String_fromData)
      ..tagIds = toList<String>(data['tags'], String_fromData)
      ..messages = toList<Message>(data['messages'], Message.fromData)
      ..notes = data['notes'];
  }

  static void listen(firestore.Firestore fs, ConversationCollectionListener listener, String collectionRoot) =>
      listenForUpdates<Conversation>(fs, listener, collectionRoot, Conversation.fromFirestore);
}
typedef ConversationCollectionListener(List<Conversation> changes);

class Message {
  MessageDirection direction;
  DateTime datetime;
  List<String> tags_ids;
  List<Tag> tags;
  String text;
  String translation;

  void cacheTags(List<Tag> allTags) {
    tags = allTags.where((e) => tags_ids.contains(e.tagId)).toList();
    tags_ids = null;
  }

  static Message fromFirestore(firestore.DocumentSnapshot doc, [Message modelObj]) =>
      fromData(doc.data(), modelObj);

  static Message fromData(data, [Message modelObj]) {
    return (modelObj ?? Message())
      ..direction = MessageDirection_fromString(data['direction'] as String)
      ..datetime = DateTime.parse(data['datetime'])
      ..tags_ids = toList<String>(data['tags'], String_fromData)
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

  static SuggestedReply fromFirestore(firestore.DocumentSnapshot doc, [SuggestedReply modelObj]) =>
      fromData(doc.data(), modelObj)..suggestedReplyId = doc.id;

  static SuggestedReply fromData(data, [SuggestedReply modelObj]) {
    return (modelObj ?? SuggestedReply())
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

  static Tag fromFirestore(firestore.DocumentSnapshot doc, [Tag modelObj]) =>
      fromData(doc.data(), modelObj)..tagId = doc.id;

  static Tag fromData(data, [Tag modelObj]) {
    return (modelObj ?? Tag())
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

String String_fromData(data) => data.toString();

List<T> toList<T>(dynamic data, T createModel(data)) =>
    (data as List).map<T>((elem) => createModel(elem)).toList();

Map<String, T> toMap<T>(dynamic data, T createModel(data)) =>
    (data as Map).map<String, T>((key, value) => MapEntry(key.toString(), createModel(value)));

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
