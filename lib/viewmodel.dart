
enum UIState {
  idle,
}

enum UIAction {
  updateTranslation,
  sendMessage,
  removeLabel,
}

class Data {}

class MessageData extends Data {
  String messageText;
  String personId;
  MessageData(this.messageText, this.personId);
}

class TranslationData extends Data {
  String translationText;
  String messageId;
  TranslationData(this.translationText, this.messageId);
}

class LabelData extends Data {
  String labelId;
  String messageId;
  LabelData(this.labelId, this.messageId);
}

UIState state;

command(UIAction action, Data data) {

}
