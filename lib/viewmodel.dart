import 'firebase_tools.dart' as fbt;
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

List<model.Conversation> conversations;
List<model.Tag> tags;
model.Conversation activeConversation;

void init() {
  view.init();

  conversations = fbt.loadConversations();
  tags = fbt.loadTags();

  // Fill in conversationListPanelView
  for (var conversation in conversations) {
    view.conversationListPanelView.addConversation(
      new view.ConversationSummary(
        conversation.deidentifiedPhoneNumber.shortValue,
        conversation.messages.first.content)
    );
  }

  // Fill in conversationPanelView
  activeConversation = conversations[0];
  view.conversationListPanelView.selectConversation(activeConversation.deidentifiedPhoneNumber.shortValue);
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
          activeConversation = conversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.shortValue == conversationData.deidentifiedPhoneNumber);
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
    ..deidentifiedPhoneNumber = conversation.deidentifiedPhoneNumber.shortValue
    ..demographicsInfo = conversation.demographicsInfo.values.join(', ');
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
        '${conversation.deidentifiedPhoneNumber.shortValue}-${i}',
        translation: message.translation,
        incoming: message.direction == model.MessageDirection.In,
        labels: tags
      ));
  }
}
