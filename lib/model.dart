
class DeidentifiedPhoneNumber {
  String value;
  String shortValue;
}
class Conversation {
  DeidentifiedPhoneNumber deidentifiedPhoneNumber;
  Map<String, String> demographicsInfo;
  List<Tag> tags;
  List<Message> messages;
}

enum MessageDirection {
  In,
  Out
}

class Message {
  MessageDirection direction;
  DateTime datetime;
  String content;
  String translation;
  List<Tag> tags;
}

class Tag {
  String tagId;
  String content;
  TagType type;
  String shortcut;
}

enum TagType {
  Normal,
  Important
}
