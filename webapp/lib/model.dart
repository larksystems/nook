import 'model.g.dart' as g;
export 'model.g.dart';

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

class Message {
  g.MessageDirection direction;
  DateTime datetime;
  String text;
  String translation;
  List<Tag> tags;
}

class SuggestedReply {
  String suggestedReplyId;
  String text;
  String translation;
  String shortcut;
}

class Tag {
  String tagId;
  String text;
  g.TagType type;
  String shortcut;
}

class User {
  String userName;
  String userEmail;
}
