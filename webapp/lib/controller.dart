library controller;

import 'logger.dart';
import 'model.dart' as model;
import 'platform.dart' as platform;
import 'view.dart' as view;

part 'controller_platform_helper.dart';
part 'controller_view_helper.dart';

Logger log = new Logger('controller.dart');

enum UIActionObject {
  conversation,
  message,
}

enum UIAction {
  updateTranslation,
  updateNote,
  sendMessage,
  addTag,
  removeConversationTag,
  removeMessageTag,
  selectConversation,
  selectMessage,
  deselectMessage,
  userSignedIn,
  userSignedOut,
  signInButtonClicked,
  signOutButtonClicked,
  keyPressed,
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
  String deidentifiedPhoneNumber;
  ConversationData(this.deidentifiedPhoneNumber);
}

class TagData extends Data {
  String tagId;
  TagData(this.tagId);
}

class NoteData extends Data {
  String noteText;
  NoteData(this.noteText);
}

class UserData extends Data {
  String displayName;
  String email;
  String photoUrl;
  UserData(this.displayName, this.email, this.photoUrl);
}

class KeyPressData extends Data {
  String key;
  KeyPressData(this.key);
}

UIActionObject actionObjectState;

List<model.Conversation> conversations;
List<model.SuggestedReply> suggestedReplies;
List<model.Tag> availableTags;
List<model.Tag> conversationTags;
List<model.Tag> messageTags;
model.Conversation activeConversation;
model.Message selectedMessage;
model.User signedInUser;

void init() async {
  view.init();
  platform.init();

}

void populateUI() async {

  conversations = await _conversationsFromPlatformData(platform.loadConversations());
  suggestedReplies = await _suggestedRepliesFromPlatformData(platform.loadSuggestedReplies());
  conversationTags = [];
  messageTags = [];

  // Fill in conversationListPanelView
  for (var conversation in conversations) {
    view.conversationListPanelView.addConversation(
      new view.ConversationSummary(
        conversation.deidentifiedPhoneNumber.value,
        conversation.messages.first.text)
    );
  }

  // Fill in conversationPanelView
  activeConversation = conversations[0];
  view.conversationListPanelView.selectConversation(activeConversation.deidentifiedPhoneNumber.value);
  _populateConversationPanelView(activeConversation);
  actionObjectState = UIActionObject.conversation;

  // Fill in replyPanelView
  _populateReplyPanelView(suggestedReplies);
  view.replyPanelView.noteText = activeConversation.notes;

  platform.listenForConversationTags(
    (tags) {
      var updatedIds = tags.map((t) => t.tagId).toSet();
      conversationTags.removeWhere((tag) => updatedIds.contains(tag.tagId));
      conversationTags.addAll(tags);

      if (actionObjectState == UIActionObject.conversation) {
        _populateTagPanelView(conversationTags, TagReceiver.Conversation);
      }
    }
  );

  platform.listenForMessageTags(
    (tags) {
      var updatedIds = tags.map((t) => t.tagId).toSet();
      messageTags.removeWhere((tag) => updatedIds.contains(tag.tagId));
      messageTags.addAll(tags);

      if (actionObjectState == UIActionObject.message) {
        _populateTagPanelView(messageTags, TagReceiver.Message);
      }
    }
  );


}

void command(UIAction action, Data data) {
  switch (action) {
    case UIAction.sendMessage:
      ReplyData replyData = data;
      model.SuggestedReply selectedReply = suggestedReplies[replyData.replyIndex];
      sendReply(selectedReply, activeConversation);
      break;
    case UIAction.addTag:
      TagData tagData = data;
      switch (actionObjectState) {
        case UIActionObject.conversation:
          model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          setConversationTag(tag, activeConversation);
          break;
        case UIActionObject.message:
          model.Tag tag = messageTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          setMessageTag(tag, selectedMessage, activeConversation);
          break;
      }
      break;
    case UIAction.removeConversationTag:
      ConversationTagData conversationTagData = data;
      model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
      activeConversation.tags.remove(tag);
      platform.updateConversation(encodeConversationToPlatformData(activeConversation));
      view.conversationPanelView.removeTag(tag.tagId);
      break;
    case UIAction.removeMessageTag:
      MessageTagData messageTagData = data;
      var message = activeConversation.messages[messageTagData.messageIndex];
      message.tags.removeWhere((t) => t.tagId == messageTagData.tagId);
      platform.updateConversation(encodeConversationToPlatformData(activeConversation));
      view.conversationPanelView
        .messageViewAtIndex(messageTagData.messageIndex)
        .removeTag(messageTagData.tagId);
      break;
    case UIAction.selectMessage:
      MessageData messageData = data;
      selectedMessage = activeConversation.messages[messageData.messageIndex];
      view.conversationPanelView.selectMessage(messageData.messageIndex);
      availableTags = messageTags;
      _populateTagPanelView(availableTags, TagReceiver.Message);
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
          availableTags = conversationTags;
          _populateTagPanelView(availableTags, TagReceiver.Conversation);
          actionObjectState = UIActionObject.conversation;
          break;
      }
      break;
    case UIAction.selectConversation:
      ConversationData conversationData = data;
      activeConversation = conversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.value == conversationData.deidentifiedPhoneNumber);
      updateViewForConversation(activeConversation);
      break;
    case UIAction.updateTranslation:
      break;
    case UIAction.updateNote:
      NoteData noteData = data;
      activeConversation.notes = noteData.noteText;
      break;
    case UIAction.userSignedOut:
      signedInUser = null;
      view.authView.signOut();
      break;
    case UIAction.userSignedIn:
      UserData userData = data;
      signedInUser = new model.User()
        ..userName = userData.displayName
        ..userEmail = userData.email;
      view.authView.signIn(userData.displayName, userData.photoUrl);
      populateUI();
      break;
    case UIAction.signInButtonClicked:
      platform.signIn();
      break;
    case UIAction.signOutButtonClicked:
      platform.signOut();
      break;
    case UIAction.keyPressed:
      KeyPressData keyPressData = data;
      if (keyPressData.key == 'Enter') {
        int nextConversationIndex = conversations.indexOf(activeConversation) + 1;
        nextConversationIndex = nextConversationIndex >= conversations.length ? 0 : nextConversationIndex;
        // Select the next conversation in the list
        activeConversation = conversations[nextConversationIndex];
        updateViewForConversation(activeConversation);
        return;
      }
      // If the shortcut is for a reply, find it and send it
      var selectedReply = suggestedReplies.where((reply) => reply.shortcut == keyPressData.key);
      if (selectedReply.isNotEmpty) {
        assert (selectedReply.length == 1);
        sendReply(selectedReply.first, activeConversation);
        return;
      }
      // If the shortcut is for a tag, find it and tag it to the conversation/message
      var selectedTag = availableTags.where((tag) => tag.shortcut == keyPressData.key);
      if (selectedTag.isNotEmpty) {
        assert (selectedTag.length == 1);
        switch (actionObjectState) {
          case UIActionObject.conversation:
            setConversationTag(selectedTag.first, activeConversation);
            break;
          case UIActionObject.message:
            setMessageTag(selectedTag.first, selectedMessage, activeConversation);
            break;
        }
        return;
      }
      // There is no matching shortcut in either replies or tags, ignore
      break;
    default:
  }
}

void updateViewForConversation(model.Conversation conversation) {
  // Select the conversation in the list
  view.conversationListPanelView.selectConversation(conversation.deidentifiedPhoneNumber.value);
  // Replace the previous conversation in the conversation panel
  _populateConversationPanelView(conversation);
  view.replyPanelView.noteText = conversation.notes;
  // Deselect message if selected
  switch (actionObjectState) {
    case UIActionObject.conversation:
      break;
    case UIActionObject.message:
      selectedMessage = null;
      view.conversationPanelView.deselectMessage();
      availableTags = conversationTags;
      _populateTagPanelView(availableTags, TagReceiver.Conversation);
      break;
  }
}

void sendReply(model.SuggestedReply reply, model.Conversation conversation) {
  model.Message newMessage = new model.Message()
    ..text = reply.text
    ..datetime = new DateTime.now()
    ..direction = model.MessageDirection.Out
    ..translation = reply.translation
    ..tags = [];
  conversation.messages.add(newMessage);
  view.conversationPanelView.addMessage(
    new view.MessageView(
      newMessage.text,
      conversation.deidentifiedPhoneNumber.value,
      conversation.messages.indexOf(newMessage),
      translation: newMessage.translation,
      incoming: false)
  );
  platform
    .sendMessage(conversation.deidentifiedPhoneNumber.value, reply.text)
    .then((success) {
      log.verbose('controller.sendMessage reponse status $success');
    });
}

void setConversationTag(model.Tag tag, model.Conversation conversation) {
  if (!conversation.tags.contains(tag)) {
    conversation.tags.add(tag);
    platform.updateConversation(encodeConversationToPlatformData(conversation));
    view.conversationPanelView.addTags(new view.ConversationTagView(tag.text, tag.tagId));
  }
}

void setMessageTag(model.Tag tag, model.Message message, model.Conversation conversation) {
  if (!message.tags.contains(tag)) {
    message.tags.add(tag);
    platform.updateConversation(encodeConversationToPlatformData(conversation));
    view.conversationPanelView
      .messageViewAtIndex(conversation.messages.indexOf(message))
      .addTag(new view.MessageTagView(tag.text, tag.tagId));
  }
}
