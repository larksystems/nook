
class DeidentifiedPhoneNumber {
  String value;
  String shortValue;
}
class Conversation {
  DeidentifiedPhoneNumber deidentifiedPhoneNumber;
  Map<String, String> demographicsInfo;
  List<Tag> tags;
  List<Message> messages;
  String notes;
}

enum MessageDirection {
  In,
  Out
}

class Message {
  MessageDirection direction;
  DateTime datetime;
  String text;
  String translation;
  List<Tag> tags;
}

class SuggestedReply {
  String text;
  String translation;
  String shortcut;
}

class Tag {
  String tagId;
  String text;
  TagType type;
  String shortcut;
}

enum TagType {
  Normal,
  Important
}

class User {
  String userName;
  String userEmail;
}
