library viewmodel;

import 'firebase_tools.dart' as fbt;
import 'model.dart' as model;
import 'view.dart' as view;

part 'viewmodel_helper.dart';

enum UIState {
  idle,
  messageSelected,
}

enum UIAction {
  updateTranslation,
  sendMessage,
  addTag,
  removeTag,
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
  int messageIndex;
  MessageTagData(this.tagId, this.messageIndex);
}

class ConversationTagData extends Data {
  String tagId;
  String conversationId;
  ConversationTagData(this.tagId, this.conversationId);
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
        conversation.messages.first.text)
    );
  }

  // Fill in conversationPanelView
  activeConversation = conversations[0];
  view.conversationListPanelView.selectConversation(activeConversation.deidentifiedPhoneNumber.shortValue);
  _populateConversationPanelView(activeConversation);

  // Fill in replyPanelView
  _populateReplyPanelView(suggestedReplies);

  // Fill in tagPanelView
  // Prepare list of shortcuts in case some tags don't have shortcuts
  _populateTagPanelView(conversationTags, TagReceiver.Conversation);
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
          break;
        case UIAction.removeTag:
          if (data is ConversationTagData) {
            ConversationTagData conversationTagData = data;
            model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
            activeConversation.tags.remove(tag);
            fbt.updateConversation(activeConversation);
            view.conversationPanelView.removeTag(tag.tagId);
            break;
          }
          assert (data is MessageTagData);
          MessageTagData messageTagData = data;
          print (messageTagData.messageIndex);
          var message = activeConversation.messages[messageTagData.messageIndex];
          message.tags.removeWhere((t) => t.tagId == messageTagData.tagId);
          fbt.updateConversation(activeConversation);
          view.conversationPanelView
            .messageViewAtIndex(messageTagData.messageIndex)
            .removeTag(messageTagData.tagId);
          break;
        case UIAction.selectConversation:
          ConversationData conversationData = data;
          activeConversation = conversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.shortValue == conversationData.deidentifiedPhoneNumberShort);
          // Select the new conversation in the list
          view.conversationListPanelView.selectConversation(conversationData.deidentifiedPhoneNumberShort);
          // Replace the previous conversation in the conversation panel
          _populateConversationPanelView(activeConversation);
          break;
        case UIAction.addTag:
          TagData tagData = data;
          model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          activeConversation.tags.add(tag);
          fbt.updateConversation(activeConversation);
          view.conversationPanelView.addTags(new view.TagView(tag.text, tag.tagId));
          break;
        case UIAction.selectMessage:
          MessageData messageData = data;
          selectedMessage = activeConversation.messages[messageData.messageIndex];
          view.conversationPanelView.selectMessage(messageData.messageIndex);
          _populateTagPanelView(messageTags, TagReceiver.Message);
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
          break;
        case UIAction.addTag:
          TagData tagData = data;
          model.Tag tag = messageTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          selectedMessage.tags.add(tag);
          fbt.updateConversation(activeConversation);
          view.conversationPanelView
            .messageViewAtIndex(activeConversation.messages.indexOf(selectedMessage))
            .addTag(new view.TagView(tag.text, tag.tagId));
          break;
        case UIAction.removeTag:
          if (data is ConversationTagData) {
            ConversationTagData conversationTagData = data;
            model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
            activeConversation.tags.remove(tag);
            fbt.updateConversation(activeConversation);
            view.conversationPanelView.removeTag(tag.tagId);
            break;
          }
          assert (data is MessageTagData);
          MessageTagData messageTagData = data;
          var message = activeConversation.messages[messageTagData.messageIndex];
          message.tags.removeWhere((t) => t.tagId == messageTagData.tagId);
          fbt.updateConversation(activeConversation);
          view.conversationPanelView
            .messageViewAtIndex(messageTagData.messageIndex)
            .removeTag(messageTagData.tagId);
          break;
        case UIAction.selectMessage:
          MessageData messageData = data;
          selectedMessage = activeConversation.messages[messageData.messageIndex];
          view.conversationPanelView.selectMessage(messageData.messageIndex);
          _populateTagPanelView(messageTags, TagReceiver.Message);
          break;
        case UIAction.deselectMessage:
          selectedMessage = null;
          view.conversationPanelView.deselectMessage();
          _populateTagPanelView(conversationTags, TagReceiver.Conversation);
          state = UIState.idle;
          break;
        case UIAction.selectConversation:
          ConversationData conversationData = data;
          activeConversation = conversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.shortValue == conversationData.deidentifiedPhoneNumberShort);
          // Select the new conversation in the list
          view.conversationListPanelView.selectConversation(conversationData.deidentifiedPhoneNumberShort);
          // Replace the previous conversation in the conversation panel
          _populateConversationPanelView(activeConversation);

          if (selectedMessage != null) {
            selectedMessage = null;
            view.conversationPanelView.deselectMessage();
            _populateTagPanelView(conversationTags, TagReceiver.Conversation);
          }
          break;
        default:
      }
      break;
  }
}
