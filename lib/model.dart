import 'firebase_tools.dart' as fbt;

class Conversation {
  String deidentifiedPhoneNumber;
  String demographicsInfo;
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
}

enum TagType {
  Normal,
  Important
}

List<Conversation> conversations;
List<Tag> tags;

void init() {
  conversations = fbt.loadConversations();
  tags = fbt.loadTags();
}
