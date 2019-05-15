import 'firebase_tools.dart' as fbt;
import 'model.dart' as model;
import 'view.dart' as view;

enum UIState {
  idle,
  messageSelected,
}

enum UIAction {
  updateTranslation,
  sendMessage,
  addTag,
  removeLabel,
  selectConversation,
  selectMessage,
  deselectMessage,
}

class Data {}

class MessageData extends Data {
  String conversationId;
  int messageIndex;
  MessageData(this.conversationId, this.messageIndex);
}

class ReplyData extends Data {
  int replyIndex;
  ReplyData(this.replyIndex);
}

class TranslationData extends Data {
  String translationText;
  String conversationId;
  int messageIndex;
  TranslationData(this.translationText, this.conversationId, this.messageIndex);
}

class LabelData extends Data {
  String labelId;
  String messageId;
  LabelData(this.labelId, this.messageId);
}

class ConversationData extends Data {
  String deidentifiedPhoneNumberShort;
  ConversationData(this.deidentifiedPhoneNumberShort);
}

class TagData extends Data {
  String tagId;
  TagData(this.tagId);
}

UIState state = UIState.idle;

List<model.Conversation> conversations;
List<model.SuggestedReply> suggestedReplies;
List<model.Tag> conversationTags;
List<model.Tag> messageTags;
model.Conversation activeConversation;
model.Message selectedMessage;

void init() {
  view.init();

  conversations = fbt.loadConversations();
  suggestedReplies = fbt.loadSuggestedReplies();
  conversationTags = fbt.loadConversationTags();
  messageTags = fbt.loadMessageTags();

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
  populateReplyPanelView(suggestedReplies);

  // Fill in tagPanelView
  // Prepare list of shortcuts in case some tags don't have shortcuts
  populateTagPanelView(conversationTags, TagReceiver.Conversation);
}

void command(UIAction action, Data data) {
  switch (state) {
    case UIState.idle:
      switch (action) {
        case UIAction.updateTranslation:
          break;
        case UIAction.sendMessage:
          ReplyData replyData = data;
          model.SuggestedReply selectedReply = suggestedReplies[replyData.replyIndex];
          model.Message newMessage = new model.Message()
            ..content = selectedReply.content
            ..datetime = new DateTime.now()
            ..direction = model.MessageDirection.Out
            ..translation = selectedReply.translation
            ..tags = [];
          activeConversation.messages.add(newMessage);
          view.conversationPanelView.addMessage(
            new view.MessageView(
              newMessage.content,
              activeConversation.deidentifiedPhoneNumber.shortValue,
              activeConversation.messages.indexOf(newMessage),
              translation: newMessage.translation,
              incoming: false)
          );
          break;
        case UIAction.removeLabel:
          break;
        case UIAction.selectConversation:
          ConversationData conversationData = data;
          activeConversation = conversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.shortValue == conversationData.deidentifiedPhoneNumberShort);
          // Select the new conversation in the list
          view.conversationListPanelView.selectConversation(conversationData.deidentifiedPhoneNumberShort);
          // Replace the previous conversation in the conversation panel
          populateConversationPanelView(activeConversation);
          break;
        case UIAction.addTag:
          TagData tagData = data;
          model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          activeConversation.tags.add(tag);
          fbt.updateConversation(activeConversation);
          view.conversationPanelView.addTags(new view.LabelView(tag.content, tag.tagId));
          break;
        case UIAction.selectMessage:
          MessageData messageData = data;
          selectedMessage = activeConversation.messages[messageData.messageIndex];
          view.conversationPanelView.selectMessage(messageData.messageIndex);
          populateTagPanelView(messageTags, TagReceiver.Message);
          state = UIState.messageSelected;
          break;
        default:
      }
      break;
    case UIState.messageSelected:
      switch (action) {
        case UIAction.sendMessage:
          ReplyData replyData = data;
          model.SuggestedReply selectedReply = suggestedReplies[replyData.replyIndex];
          model.Message newMessage = new model.Message()
            ..content = selectedReply.content
            ..datetime = new DateTime.now()
            ..direction = model.MessageDirection.Out
            ..translation = selectedReply.translation
            ..tags = [];
          activeConversation.messages.add(newMessage);
          view.conversationPanelView.addMessage(
            new view.MessageView(
              newMessage.content,
              activeConversation.deidentifiedPhoneNumber.shortValue,
              activeConversation.messages.indexOf(newMessage),
              translation: newMessage.translation,
              incoming: false)
          );
          break;
        case UIAction.addTag:
          TagData tagData = data;
          model.Tag tag = messageTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          selectedMessage.tags.add(tag);
          fbt.updateConversation(activeConversation);
          view.conversationPanelView
            .messageViewAtIndex(activeConversation.messages.indexOf(selectedMessage))
            .addLabel(new view.LabelView(tag.content, tag.tagId));
          break;
        case UIAction.selectMessage:
          MessageData messageData = data;
          selectedMessage = activeConversation.messages[messageData.messageIndex];
          view.conversationPanelView.selectMessage(messageData.messageIndex);
          populateTagPanelView(messageTags, TagReceiver.Message);
          break;
        case UIAction.deselectMessage:
          selectedMessage = null;
          view.conversationPanelView.deselectMessage();
          populateTagPanelView(conversationTags, TagReceiver.Conversation);
          state = UIState.idle;
          break;
        case UIAction.selectConversation:
          ConversationData conversationData = data;
          activeConversation = conversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.shortValue == conversationData.deidentifiedPhoneNumberShort);
          // Select the new conversation in the list
          view.conversationListPanelView.selectConversation(conversationData.deidentifiedPhoneNumberShort);
          // Replace the previous conversation in the conversation panel
          populateConversationPanelView(activeConversation);

          if (selectedMessage != null) {
            selectedMessage = null;
            view.conversationPanelView.deselectMessage();
            populateTagPanelView(conversationTags, TagReceiver.Conversation);
          }
          break;
        default:
      }
      break;
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
        conversation.deidentifiedPhoneNumber.shortValue,
        i,
        translation: message.translation,
        incoming: message.direction == model.MessageDirection.In,
        labels: tags
      ));
  }
}

const SEND_REPLY_BUTTON_TEXT = 'SEND message';

populateReplyPanelView(List<model.SuggestedReply> replies) {
  view.replyPanelView.clear();
  List<String> shortcuts = '1234567890'.split('');
  for (var reply in replies) {
    shortcuts.remove(reply.shortcut);
  }
  String buttonText = SEND_REPLY_BUTTON_TEXT;
  for (var reply in replies) {
    String shortcut = reply.shortcut != null ? reply.shortcut : shortcuts.removeAt(0);
    int replyIndex = replies.indexOf(reply);
    view.replyPanelView.addReply(new view.ReplyActionView(reply.content, shortcut, replyIndex, buttonText));
  }
}

const TAG_CONVERSATION_BUTTON_TEXT = 'TAG conversation';
const TAG_MESSAGE_BUTTON_TEXT = 'TAG message';

enum TagReceiver {
  Conversation,
  Message
}

void populateTagPanelView(List<model.Tag> tags, TagReceiver tagReceiver) {
  view.tagPanelView.clear();
  List<String> shortcuts = 'abcdefghijklmnopqrstuvwxyz'.split('');
  for (var tag in tags) {
    shortcuts.remove(tag.shortcut);
  }
  String buttonText = '';
  switch (tagReceiver) {
    case TagReceiver.Conversation:
      buttonText = TAG_CONVERSATION_BUTTON_TEXT;
      break;
    case TagReceiver.Message:
      buttonText = TAG_MESSAGE_BUTTON_TEXT;
      break;
  }
  for (var tag in tags) {
    String shortcut = tag.shortcut != null ? tag.shortcut : shortcuts.removeAt(0);
    view.tagPanelView.addTag(new view.TagActionView(tag.content, shortcut, tag.tagId, buttonText));
  }
}
