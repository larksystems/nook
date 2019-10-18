import 'model.g.dart' as g;
export 'model.g.dart';

class DeidentifiedPhoneNumber {
  String value;
  String shortValue;
}
class Conversation {
  DeidentifiedPhoneNumber deidentifiedPhoneNumber;
  Map<String, String> demographicsInfo;
  List<g.Tag> tags;
  List<Message> messages;
  String notes;
}

class Message {
  g.MessageDirection direction;
  DateTime datetime;
  String text;
  String translation;
  List<g.Tag> tags;
}

class User {
  String userName;
  String userEmail;
}
