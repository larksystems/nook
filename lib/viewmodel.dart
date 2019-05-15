library viewmodel;

import 'firebase_tools.dart' as fbt;
import 'model.dart' as model;
import 'view.dart' as view;

part 'viewmodel_helper.dart';

enum UIActionContext {
  sendReply,
  tag,
}

enum UIActionObject {
  conversation,
  message,
}

enum UIAction {
  updateTranslation,
  sendMessage,
  addTag,
  removeMessageTag,
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

class MessageTagData extends Data {
  String tagId;
  String messageId;
  MessageTagData(this.tagId, this.messageId);
}

class ConversationData extends Data {
  String deidentifiedPhoneNumberShort;
  ConversationData(this.deidentifiedPhoneNumberShort);
}

class TagData extends Data {
  String tagId;
  TagData(this.tagId);
}

UIActionContext actionContextState;
UIActionObject actionObjectState;

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
        conversation.messages.first.text)
    );
  }

  // Fill in conversationPanelView
  activeConversation = conversations[0];
  view.conversationListPanelView.selectConversation(activeConversation.deidentifiedPhoneNumber.shortValue);
  _populateConversationPanelView(activeConversation);
  actionObjectState = UIActionObject.conversation;

  // Fill in replyPanelView
  _populateReplyPanelView(suggestedReplies);
  actionContextState = UIActionContext.sendReply;

  // Fill in tagPanelView
  // Prepare list of shortcuts in case some tags don't have shortcuts
  _populateTagPanelView(conversationTags, TagReceiver.Conversation);
}

void command(UIAction action, Data data) {
  switch (action) {
    case UIAction.sendMessage:
      ReplyData replyData = data;
      model.SuggestedReply selectedReply = suggestedReplies[replyData.replyIndex];
      model.Message newMessage = new model.Message()
        ..text = selectedReply.text
        ..datetime = new DateTime.now()
        ..direction = model.MessageDirection.Out
        ..translation = selectedReply.translation
        ..tags = [];
      activeConversation.messages.add(newMessage);
      view.conversationPanelView.addMessage(
        new view.MessageView(
          newMessage.text,
          activeConversation.deidentifiedPhoneNumber.shortValue,
          activeConversation.messages.indexOf(newMessage),
          translation: newMessage.translation,
          incoming: false)
      );
      actionContextState = UIActionContext.tag;
      break;
    case UIAction.addTag:
      TagData tagData = data;
      switch (actionObjectState) {
        case UIActionObject.conversation:
          model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          activeConversation.tags.add(tag);
          fbt.updateConversation(activeConversation);
          view.conversationPanelView.addTags(new view.TagView(tag.text, tag.tagId));
          break;
        case UIActionObject.message:
          model.Tag tag = messageTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          selectedMessage.tags.add(tag);
          fbt.updateConversation(activeConversation);
          view.conversationPanelView
            .messageViewAtIndex(activeConversation.messages.indexOf(selectedMessage))
            .addTag(new view.TagView(tag.text, tag.tagId));
          break;
      }
      break;
    case UIAction.selectMessage:
      MessageData messageData = data;
      selectedMessage = activeConversation.messages[messageData.messageIndex];
      view.conversationPanelView.selectMessage(messageData.messageIndex);
      _populateTagPanelView(messageTags, TagReceiver.Message);
      switch (actionObjectState) {
        case UIActionObject.conversation:
          actionObjectState = UIActionObject.message;
          break;
        case UIActionObject.message:
          break;
      }
      break;
    case UIAction.deselectMessage:
      switch (actionObjectState) {
        case UIActionObject.conversation:
          break;
        case UIActionObject.message:
          selectedMessage = null;
          view.conversationPanelView.deselectMessage();
          _populateTagPanelView(conversationTags, TagReceiver.Conversation);
          actionObjectState = UIActionObject.conversation;
          break;
      }
      break;
    case UIAction.selectConversation:
      ConversationData conversationData = data;
      activeConversation = conversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.shortValue == conversationData.deidentifiedPhoneNumberShort);
      // Select the new conversation in the list
      view.conversationListPanelView.selectConversation(conversationData.deidentifiedPhoneNumberShort);
      // Replace the previous conversation in the conversation panel
      _populateConversationPanelView(activeConversation);
      switch (actionObjectState) {
        case UIActionObject.conversation:
          break;
        case UIActionObject.message:
          selectedMessage = null;
          view.conversationPanelView.deselectMessage();
          _populateTagPanelView(conversationTags, TagReceiver.Conversation);
          break;
      }
      actionContextState = UIActionContext.sendReply;
      break;
    case UIAction.removeMessageTag:
      break;
    case UIAction.updateTranslation:
      break;
    default:
  }
}
