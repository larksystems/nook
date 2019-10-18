// This generated file is used by `model.dart`
// and should not be imported or exported by any other file.

import 'package:firebase/firestore.dart' as firestore;

class Message {
  MessageDirection direction;
  DateTime datetime;
  String text;
  String translation;
}

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

  static SuggestedReply fromData(Map<String, dynamic> data, [SuggestedReply obj]) {
    return (obj ?? SuggestedReply())
      ..text = data['text']
      ..translation = data['translation']
      ..shortcut = data['shortcut'];
  }
}

class Tag {
  String tagId;
  String text;
  TagType type;
  String shortcut;

  static Tag fromFirestore(firestore.DocumentSnapshot doc, [Tag obj]) =>
      fromData(doc.data(), obj)..tagId = doc.id;

  static Tag fromData(Map<String, dynamic> data, [Tag obj]) {
    return (obj ?? Tag())
      ..text = data['text']
      ..type = TagType_fromString(data['type'] as String)
      ..shortcut = data['shortcut'];
  }
}

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
