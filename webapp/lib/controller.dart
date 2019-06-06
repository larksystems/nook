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
  addFilterTag,
  removeConversationTag,
  removeMessageTag,
  removeFilterTag,
  selectConversation,
  selectMessage,
  deselectMessage,
  userSignedIn,
  userSignedOut,
  signInButtonClicked,
  signOutButtonClicked,
  keyPressed,
  addNewSuggestedReply,
  addNewTag,
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

class ReplyTranslationData extends Data {
  String translationText;
  int replyIndex;
  ReplyTranslationData(this.translationText, this.replyIndex);
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

class FilterTagData extends Data {
  String tagId;
  FilterTagData(this.tagId);
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

class AddSuggestedReplyData extends Data {
  String replyText;
  String translationText;
  AddSuggestedReplyData(this.replyText, this.translationText);
}

class AddTagData extends Data {
  String tagText;
  AddTagData(this.tagText);
}

UIActionObject actionObjectState;

List<model.Conversation> conversations;
List<model.Conversation> filteredConversations;
List<model.SuggestedReply> suggestedReplies;
List<model.Tag> conversationTags;
List<model.Tag> messageTags;
List<model.Tag> filterTags;
model.Conversation activeConversation;
model.Message selectedMessage;
model.User signedInUser;

void init() async {
  view.init();
  await platform.init();
}

void populateUI() {

  conversations = [];
  filteredConversations = conversations;
  suggestedReplies = [];
  conversationTags = [];
  messageTags = [];

  activeConversation = updateViewForConversations(filteredConversations);
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

  platform.listenForSuggestedReplies(
    (updatedReplies) {
      var updatedIds = updatedReplies.map((t) => t.suggestedReplyId).toSet();
      suggestedReplies.removeWhere((suggestedReply) => updatedIds.contains(suggestedReply.suggestedReplyId));
      suggestedReplies.addAll(updatedReplies);

      _populateReplyPanelView(suggestedReplies);
    }
  );

  platform.listenForConversations(
    (updatedConversations) {
      var updatedIds = updatedConversations.map((t) => t.deidentifiedPhoneNumber.value).toSet();
      conversations.removeWhere((conversation) => updatedIds.contains(conversation.deidentifiedPhoneNumber.value));
      conversations.addAll(updatedConversations);

      // Get any filter tags from the url
      List<String> filterTagIds = view.urlView.pageUrlFilterTags;
      filterTags = filterTagIds.map((tagId) => conversationTags.singleWhere((tag) => tag.tagId == tagId)).toList();
      filteredConversations = filterConversationsByTags(conversations, filterTags);
      _populateFilterTagsMenu(conversationTags);
      _populateSelectedFilterTags(filterTags);

      activeConversation = updateViewForConversations(filteredConversations);
    });
}

void command(UIAction action, Data data) {
  print(action);
  // For most actions, a conversation needs to be active.
  // Early exist if it's not one of the actions valid without an active conversation.
  if (activeConversation == null &&
      action != UIAction.addFilterTag && action != UIAction.removeFilterTag &&
      action != UIAction.signInButtonClicked && action != UIAction.signOutButtonClicked &&
      action != UIAction.userSignedIn && action != UIAction.userSignedOut) {
    return;
  }

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
    case UIAction.addFilterTag:
      FilterTagData tagData = data;
      model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
      if (filterTags.contains(tag)) break;
      filterTags.add(tag);
      view.urlView.pageUrlFilterTags = filterTags.map((tag) => tag.tagId).toList();
      view.conversationFilter.addFilterTag(new view.FilterTagView(tag.text, tag.tagId));
      filteredConversations = filterConversationsByTags(conversations, filterTags);
      activeConversation = updateViewForConversations(filteredConversations);
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
    case UIAction.removeFilterTag:
      FilterTagData tagData = data;
      model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
      filterTags.remove(tag);
      view.urlView.pageUrlFilterTags = filterTags.map((tag) => tag.tagId).toList();
      view.conversationFilter.removeFilterTag(tag.tagId);
      filteredConversations = filterConversationsByTags(conversations, filterTags);
      _populateConversationListPanelView(filteredConversations);
      activeConversation = updateViewForConversations(filteredConversations);
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
      activeConversation = filteredConversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.value == conversationData.deidentifiedPhoneNumber);
      updateViewForConversation(activeConversation);
      break;
    case UIAction.updateTranslation:
      break;
    case UIAction.updateNote:
      NoteData noteData = data;
      activeConversation.notes = noteData.noteText;
      platform.updateNotes(activeConversation);
      break;
    case UIAction.userSignedOut:
      signedInUser = null;
      view.authHeaderView.signOut();
      view.initSignedOutView();
      break;
    case UIAction.userSignedIn:
      UserData userData = data;
      signedInUser = new model.User()
        ..userName = userData.displayName
        ..userEmail = userData.email;
      view.authHeaderView.signIn(userData.displayName, userData.photoUrl);
      view.initSignedInView();
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
        int nextConversationIndex = filteredConversations.indexOf(activeConversation) + 1;
        nextConversationIndex = nextConversationIndex >= filteredConversations.length ? 0 : nextConversationIndex;
        // Select the next conversation in the list
        activeConversation = filteredConversations[nextConversationIndex];
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
      switch (actionObjectState) {
        case UIActionObject.conversation:
          var selectedTag = conversationTags.where((tag) => tag.shortcut == keyPressData.key);
          if (selectedTag.isEmpty) break;
          assert (selectedTag.length == 1);
          setConversationTag(selectedTag.first, activeConversation);
          return;
        case UIActionObject.message:
          var selectedTag = messageTags.where((tag) => tag.shortcut == keyPressData.key);
          if (selectedTag.isEmpty) break;
          assert (selectedTag.length == 1);
          setMessageTag(selectedTag.first, selectedMessage, activeConversation);
          return;
      }
      // There is no matching shortcut in either replies or tags, ignore
      break;
    case UIAction.addNewSuggestedReply:
      AddSuggestedReplyData replyData = data;
      // TODO: call platform
      break;
    case UIAction.addNewTag:
      AddTagData tagData = data;
      // TODO: call platform
      break;
    default:
  }
}

/// Shows the list of [conversations] and selects the first conversation.
/// Returns the first conversation in the list, or null if list is empty.
model.Conversation updateViewForConversations(List<model.Conversation> conversations) {
  // Update conversationListPanelView
  _populateConversationListPanelView(conversations);

  // Update conversationPanelView
  if (conversations.isEmpty) {
    view.conversationPanelView.clear();
    view.replyPanelView.noteText = '';
    actionObjectState = UIActionObject.conversation;
    return null;
  }

  if (activeConversation == null) {
    model.Conversation conversationToSelect = conversations.first;
    view.conversationListPanelView.selectConversation(conversationToSelect.deidentifiedPhoneNumber.value);
    _populateConversationPanelView(conversationToSelect);
    view.replyPanelView.noteText = conversationToSelect.notes;
    actionObjectState = UIActionObject.conversation;
    return conversationToSelect;
  }

  var matches = conversations.where((conversation) => conversation.deidentifiedPhoneNumber.value == activeConversation.deidentifiedPhoneNumber.value).toList();
  if (matches.length == 0) {
    model.Conversation conversationToSelect = conversations.first;
    view.conversationListPanelView.selectConversation(conversationToSelect.deidentifiedPhoneNumber.value);
    _populateConversationPanelView(conversationToSelect);
    view.replyPanelView.noteText = conversationToSelect.notes;
    actionObjectState = UIActionObject.conversation;
    return conversationToSelect;
  }

  if (matches.length > 1) {
    log.warning('Two conversations seem to have the same deidentified phone number: activeConversation.deidentifiedPhoneNumber.value');
  }
  view.conversationListPanelView.selectConversation(activeConversation.deidentifiedPhoneNumber.value);
  return activeConversation;
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
      _populateTagPanelView(conversationTags, TagReceiver.Conversation);
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

List<model.Conversation> filterConversationsByTags(List<model.Conversation> conversations, List<model.Tag> filterTags) {
  if (filterTags.isEmpty) return conversations;

  List<model.Conversation> filteredConversations = [];
  conversations.forEach((conversation) {
    if (!conversation.tags.toSet().containsAll(filterTags)) return;
    filteredConversations.add(conversation);
  });
  return filteredConversations;
}
