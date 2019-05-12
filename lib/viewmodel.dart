import 'model.dart' as model;
import 'view.dart' as view;

enum UIState {
  idle,
}

enum UIAction {
  updateTranslation,
  sendMessage,
  removeLabel,
  selectConversation,
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

class ConversationData extends Data {
  String deidentifiedPhoneNumber;
  ConversationData(this.deidentifiedPhoneNumber);
}

UIState state = UIState.idle;

model.Conversation activeConversation;

void init() {
  model.init();
  view.init();

  // Fill in conversationListPanelView
  for (var conversation in model.conversations) {
    view.conversationListPanelView.addConversation(
      new view.ConversationSummary(
        conversation.deidentifiedPhoneNumber,
        conversation.messages.first.content)
    );
  }

  // Fill in conversationPanelView
  activeConversation = model.conversations[0];
  view.conversationListPanelView.selectConversation(activeConversation.deidentifiedPhoneNumber);
  populateConversationPanelView(activeConversation);

  // Fill in replyPanelView
  // TODO

  // Fill in tagPanelView
  // TODO
}

void command(UIAction action, Data data) {
  switch (state) {
    case UIState.idle:
      switch (action) {
        case UIAction.updateTranslation:
          break;
        case UIAction.sendMessage:
          break;
        case UIAction.removeLabel:
          break;
        case UIAction.selectConversation:
          ConversationData conversationData = data;
          activeConversation = model.conversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber == conversationData.deidentifiedPhoneNumber);
          // Select the new conversation in the list
          view.conversationListPanelView.selectConversation(conversationData.deidentifiedPhoneNumber);
          // Replace the previous conversation in the conversation panel
          populateConversationPanelView(activeConversation);
          break;
        default:
      }

      break;
    default:
  }
}

void populateConversationPanelView(model.Conversation conversation) {
  view.conversationPanelView.clear();
  view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.deidentifiedPhoneNumber
    ..demographicsInfo = conversation.demographicsInfo;
  for (var tag in conversation.tags) {
    view.conversationPanelView.addTags(new view.LabelView(tag.content, tag.tagId));
  }

  for (int i = 0; i < conversation.messages.length; i++) {
    var message = conversation.messages[i];
    List<view.LabelView> tags = [];
    for (var tag in message.tags) {
      tags.add(new view.LabelView(tag.content, tag.tagId));
    }
    view.conversationPanelView.addMessage(
      new view.MessageView(
        message.content,
        '${conversation.deidentifiedPhoneNumber}-${i}',
        translation: message.translation,
        incoming: message.direction == model.MessageDirection.In,
        labels: tags
      ));
  }
}
