library controller;

import 'dart:async';
import 'dart:collection';

import 'logger.dart';
import 'model.dart' as model;
import 'platform.dart' as platform;
import 'pubsub.dart' show PubSubException;
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
  sendManualMessage,
  addTag,
  addFilterTag,
  removeConversationTag,
  removeMessageTag,
  removeFilterTag,
  promptAfterDateFilter,
  updateAfterDateFilter,
  showConversation,
  selectConversation,
  deselectConversation,
  markConversationRead,
  markConversationUnread,
  selectMessage,
  deselectMessage,
  userSignedIn,
  userSignedOut,
  signInButtonClicked,
  signOutButtonClicked,
  keyPressed,
  addNewSuggestedReply,
  addNewTag,
  enableMultiSelectMode,
  disableMultiSelectMode,
  updateSystemMessages,
}

class Data {}

class MessageData extends Data {
  String conversationId;
  int messageIndex;
  MessageData(this.conversationId, this.messageIndex);
}

class ReplyData extends Data {
  int replyIndex;
  bool replyWithTranslation;
  ReplyData(this.replyIndex, {this.replyWithTranslation: false});
}

class ManualReplyData extends Data {
  String replyText;
  ManualReplyData(this.replyText);
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

class AfterDateFilterData extends Data {
  String tagId;
  DateTime afterDateFilter;
  AfterDateFilterData(this.tagId, [this.afterDateFilter]);
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

class SystemMessagesData extends Data {
  List<model.SystemMessage> messages;
  SystemMessagesData(this.messages);
}

List<model.SystemMessage> systemMessages;

UIActionObject actionObjectState = UIActionObject.conversation;

Set<model.Conversation> conversations;
Set<model.Conversation> filteredConversations;
List<model.SuggestedReply> suggestedReplies;
List<model.Tag> conversationTags;
List<model.Tag> messageTags;
List<model.Tag> filterTags;
DateTime afterDateFilter;
model.Conversation activeConversation;
List<model.Conversation> selectedConversations;
model.Message selectedMessage;
model.User signedInUser;

bool multiSelectMode;

void init() async {
  view.init();
  await platform.init();
}

void initUI() {
  systemMessages = [];
  conversations = emptyConversationsSet;
  filteredConversations = emptyConversationsSet;
  suggestedReplies = [];
  conversationTags = [];
  messageTags = [];
  selectedConversations = [];
  multiSelectMode = false;
  activeConversation = null;

  platform.listenForConversationTags(
    (tags) {
      var updatedIds = tags.map((t) => t.tagId).toSet();
      conversationTags.removeWhere((tag) => updatedIds.contains(tag.tagId));
      conversationTags.addAll(tags);
      _populateFilterTagsMenu(conversationTags);

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

  if (view.urlView.shouldDisableReplies) {
    view.replyPanelView.disableReplies();
  } else {
    platform.listenForSuggestedReplies(
      (updatedReplies) {
        var updatedIds = updatedReplies.map((t) => t.suggestedReplyId).toSet();
        suggestedReplies.removeWhere((suggestedReply) => updatedIds.contains(suggestedReply.suggestedReplyId));
        suggestedReplies.addAll(updatedReplies);

        _populateReplyPanelView(suggestedReplies);
      }
    );
  }

  platform.listenForConversations(
    (updatedConversations) {
      var updatedIds = updatedConversations.map((t) => t.docId).toSet();
      conversations.removeWhere((conversation) => updatedIds.contains(conversation.docId));
      conversations.addAll(updatedConversations);

      // Get any filter tags from the url
      List<String> filterTagIds = view.urlView.pageUrlFilterTags;
      filterTags = filterTagIds.map((tagId) => conversationTags.singleWhere((tag) => tag.tagId == tagId)).toList();
      filteredConversations = filterConversationsByTags(conversations, filterTags, afterDateFilter);
      _populateFilterTagsMenu(conversationTags);
      _populateSelectedFilterTags(filterTags);

      activeConversation = updateViewForConversations(filteredConversations);
      if (activeConversation == null) return;
      command(UIAction.markConversationRead, ConversationData(activeConversation.docId));
    });

  platform.listenForSystemMessages(
    (updatedMessages) {
      var updatedIds = updatedMessages.map((m) => m.msgId).toSet();
      systemMessages.removeWhere((m) => updatedIds.contains(m.msgId));
      systemMessages.addAll(updatedMessages.where((m) => !m.expired));
      command(UIAction.updateSystemMessages, SystemMessagesData(systemMessages));
    });
}

SplayTreeSet<model.Conversation> get emptyConversationsSet =>
    SplayTreeSet(model.ConversationUtil.mostRecentInboundFirst);

/// Return the element after [current],
/// or the first element if [current] is the last or not in the list.
model.Conversation nextElement(Iterable<model.Conversation> conversations, model.Conversation current) {
  var iter = conversations.iterator;
  while (iter.moveNext()) {
    if (iter.current == current) {
      if (iter.moveNext()) return iter.current;
      return conversations.first;
    }
  }
  // did not find [current] in the set... return first conversation
  return conversations.first;
}

void command(UIAction action, Data data) {
  // For most actions, a conversation needs to be active.
  // Early exist if it's not one of the actions valid without an active conversation.
  if (activeConversation == null &&
      action != UIAction.addFilterTag && action != UIAction.removeFilterTag &&
      action != UIAction.promptAfterDateFilter && action != UIAction.updateAfterDateFilter &&
      action != UIAction.signInButtonClicked && action != UIAction.signOutButtonClicked &&
      action != UIAction.userSignedIn && action != UIAction.userSignedOut) {
    return;
  }

  switch (action) {
    case UIAction.sendMessage:
      ReplyData replyData = data;
      model.SuggestedReply selectedReply = suggestedReplies[replyData.replyIndex];
      if (replyData.replyWithTranslation) {
        model.SuggestedReply translationReply = new model.SuggestedReply();
        translationReply
          ..text = selectedReply.translation
          ..translation = '';
        selectedReply = translationReply;
      }
      if (!multiSelectMode) {
        sendReply(selectedReply, activeConversation);
        return;
      }
      if (!view.sendingMultiMessagesUserConfirmation(selectedConversations.length)) {
        return;
      }
      sendMultiReply(selectedReply, selectedConversations);
      break;
    case UIAction.sendManualMessage:
      ManualReplyData replyData = data;
      model.SuggestedReply oneoffReply = new model.SuggestedReply();
      oneoffReply
        ..text = replyData.replyText
        ..translation = '';
      if (!view.sendingManualMessageUserConfirmation(oneoffReply.text)) {
        return;
      }
      sendReply(oneoffReply, activeConversation);
      view.conversationPanelView.clearNewMessageBox();
      break;
    case UIAction.addTag:
      TagData tagData = data;
      switch (actionObjectState) {
        case UIActionObject.conversation:
          model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          if (!multiSelectMode) {
            setConversationTag(tag, activeConversation);
            return;
          }
          if (!view.taggingMultiConversationsUserConfirmation(selectedConversations.length)) {
            return;
          }
          setMultiConversationTag(tag, selectedConversations);
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
      view.conversationFilter.addFilterTag(new view.FilterTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
      updateFilteredConversationList();
      break;
    case UIAction.removeConversationTag:
      ConversationTagData conversationTagData = data;
      model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
      platform.removeConversationTag(activeConversation, tag.tagId).catchError(showAndLogError);
      view.conversationPanelView.removeTag(tag.tagId);
      if (filterTags.contains(tag)) {
        // Select the next conversation in the list
        var nextConversation = nextElement(filteredConversations, activeConversation);
        filteredConversations.remove(activeConversation);
        activeConversation = nextConversation;
        activeConversation = updateViewForConversations(filteredConversations);
        updateViewForConversation(activeConversation);
      }
      break;
    case UIAction.removeMessageTag:
      MessageTagData messageTagData = data;
      var message = activeConversation.messages[messageTagData.messageIndex];
      platform.removeMessageTag(activeConversation, message, messageTagData.tagId).catchError(showAndLogError);
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
      updateFilteredConversationList();
      break;
    case UIAction.promptAfterDateFilter:
      AfterDateFilterData filterData = data;
      view.conversationPanelView.showAfterDateFilterPrompt(filterData.afterDateFilter ?? afterDateFilter);
      break;
    case UIAction.updateAfterDateFilter:
      AfterDateFilterData filterData = data;
      afterDateFilter = filterData.afterDateFilter;
      view.conversationFilter.removeFilterTag(filterData.tagId);
      if (afterDateFilter != null) {
        view.conversationFilter.addFilterTag(new view.AfterDateFilterTagView(afterDateFilter));
      }
      updateFilteredConversationList();
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
    case UIAction.markConversationRead:
      ConversationData conversationData = data;
      view.conversationListPanelView.markConversationRead(conversationData.deidentifiedPhoneNumber);
      platform.updateUnread([activeConversation], false).catchError(showAndLogError);
      break;
    case UIAction.markConversationUnread:
      if (multiSelectMode) {
        var markedConversations = <model.Conversation>[];
        for (var conversation in selectedConversations) {
          if (!conversation.unread) {
            markedConversations.add(conversation);
            view.conversationListPanelView.markConversationUnread(conversation.docId);
          }
        }
        platform.updateUnread(markedConversations, true).catchError(showAndLogError);
      } else {
        view.conversationListPanelView.markConversationUnread(activeConversation.docId);
        platform.updateUnread([activeConversation], true).catchError(showAndLogError);
      }
      break;
    case UIAction.showConversation:
      ConversationData conversationData = data;
      activeConversation = filteredConversations.singleWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
      updateViewForConversation(activeConversation);
      break;
    case UIAction.selectConversation:
      ConversationData conversationData = data;
      model.Conversation conversation = filteredConversations.singleWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
      selectedConversations.add(conversation);
      break;
    case UIAction.deselectConversation:
      ConversationData conversationData = data;
      model.Conversation conversation = filteredConversations.singleWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
      selectedConversations.remove(conversation);
      break;
    case UIAction.updateTranslation:
      if (data is ReplyTranslationData) {
        var reply = suggestedReplies[data.replyIndex];
        SaveTextAction.textChange(
          "${reply.docId}.translation",
          data.translationText,
          (newText) => platform.updateSuggestedReplyTranslation(reply, newText),
        );
      } else if (data is TranslationData) {
        TranslationData messageTranslation = data;
        var conversation = activeConversation;
        var message = conversation.messages[messageTranslation.messageIndex];
        SaveTextAction.textChange(
          "${conversation.docId}.message-${messageTranslation.messageIndex}.translation",
          messageTranslation.translationText,
          (newText) {
            return platform.setMessageTranslation(conversation, message, newText);
          },
        );
      }
      break;
    case UIAction.updateNote:
      var conversation = activeConversation;
      SaveTextAction.textChange(
        "${conversation.docId}.notes",
        (data as NoteData).noteText,
        (newText) => platform.updateNotes(conversation, newText),
      );
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
      initUI();
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
        // Select the next conversation in the list
        activeConversation = nextElement(filteredConversations, activeConversation);
        updateViewForConversation(activeConversation);
        return;
      }
      if (keyPressData.key == 'Esc' || keyPressData.key == 'Escape') {
        // Hide the snackbar if it's visible
        view.snackbarView.hideSnackbar();
      }
      // If the shortcut is for a reply, find it and send it
      var selectedReply = suggestedReplies.where((reply) => reply.shortcut == keyPressData.key);
      if (selectedReply.isNotEmpty) {
        assert (selectedReply.length == 1);
        if (!multiSelectMode) {
          sendReply(selectedReply.first, activeConversation);
          return;
        }
        if (!view.sendingMultiMessagesUserConfirmation(selectedConversations.length)) {
          return;
        }
        sendMultiReply(selectedReply.first, selectedConversations);
        return;
      }
      // If the shortcut is for a tag, find it and tag it to the conversation/message
      switch (actionObjectState) {
        case UIActionObject.conversation:
          var selectedTag = conversationTags.where((tag) => tag.shortcut == keyPressData.key);
          if (selectedTag.isEmpty) break;
          assert (selectedTag.length == 1);
          setConversationTag(selectedTag.first, activeConversation);
          if (!multiSelectMode) {
            setConversationTag(selectedTag.first, activeConversation);
            return;
          }
          if (!view.taggingMultiConversationsUserConfirmation(selectedConversations.length)) {
            return;
          }
          setMultiConversationTag(selectedTag.first, selectedConversations);
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
    case UIAction.enableMultiSelectMode:
      view.conversationListPanelView.showCheckboxes();
      view.conversationListPanelView.checkAllConversations();
      selectedConversations.clear();
      selectedConversations.addAll(filteredConversations);
      multiSelectMode = true;
      break;
    case UIAction.disableMultiSelectMode:
      view.conversationListPanelView.uncheckAllConversations();
      view.conversationListPanelView.hideCheckboxes();
      selectedConversations.clear();
      multiSelectMode = false;
      break;
    case UIAction.updateSystemMessages:
      SystemMessagesData msgData = data;
      if (msgData.messages.isNotEmpty) {
        var lines = msgData.messages.map((m) => m.text);
        view.bannerView.showBanner(lines.join(', '));
      } else {
        view.bannerView.hideBanner();
      }
      break;
    default:
  }
}

void updateFilteredConversationList() {
  filteredConversations = filterConversationsByTags(conversations, filterTags, afterDateFilter);
  activeConversation = updateViewForConversations(filteredConversations);
  if (multiSelectMode) {
    view.conversationListPanelView.showCheckboxes();
    selectedConversations = selectedConversations.toSet().intersection(filteredConversations.toSet()).toList();
    selectedConversations.forEach((conversation) => view.conversationListPanelView.checkConversation(conversation.docId));
  }
}

/// Shows the list of [conversations] and selects the first conversation.
/// Returns the first conversation in the list, or null if list is empty.
model.Conversation updateViewForConversations(Set<model.Conversation> conversations) {
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
    view.conversationListPanelView.selectConversation(conversationToSelect.docId);
    _populateConversationPanelView(conversationToSelect);
    view.replyPanelView.noteText = conversationToSelect.notes;
    actionObjectState = UIActionObject.conversation;
    return conversationToSelect;
  }

  var matches = conversations.where((conversation) => conversation.docId == activeConversation.docId).toList();
  if (matches.length == 0) {
    model.Conversation conversationToSelect = conversations.first;
    view.conversationListPanelView.selectConversation(conversationToSelect.docId);
    _populateConversationPanelView(conversationToSelect);
    view.replyPanelView.noteText = conversationToSelect.notes;
    actionObjectState = UIActionObject.conversation;
    return conversationToSelect;
  }

  if (matches.length > 1) {
    log.warning('Two conversations seem to have the same deidentified phone number: ${activeConversation.docId}');
  }
  view.conversationListPanelView.selectConversation(activeConversation.docId);
  return activeConversation;
}

void updateViewForConversation(model.Conversation conversation) {
  if (conversation == null) return;
  // Select the conversation in the list
  view.conversationListPanelView.selectConversation(conversation.docId);
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
    ..tagIds = [];
  conversation.messages.add(newMessage);
  view.conversationPanelView.addMessage(
    new view.MessageView(
      newMessage.text,
      newMessage.datetime,
      conversation.docId,
      conversation.messages.indexOf(newMessage),
      translation: newMessage.translation,
      incoming: false)
  );
  platform.sendMessage(conversation.docId, reply.text);
}

void sendMultiReply(model.SuggestedReply reply, List<model.Conversation> conversations) {
  model.Message newMessage = new model.Message()
    ..text = reply.text
    ..datetime = new DateTime.now()
    ..direction = model.MessageDirection.Out
    ..translation = reply.translation
    ..tagIds = [];
  conversations.forEach((conversation) => conversation.messages.add(newMessage));
  if (conversations.contains(activeConversation)) {
    view.conversationPanelView.addMessage(
      new view.MessageView(
        newMessage.text,
        newMessage.datetime,
        activeConversation.docId,
        activeConversation.messages.indexOf(newMessage),
        translation: newMessage.translation,
        incoming: false)
    );
  }
  List<String> ids = conversations.map((conversation) => conversation.docId).toList();
  platform.sendMultiMessage(ids, newMessage.text);
}

void setConversationTag(model.Tag tag, model.Conversation conversation) {
  if (!conversation.tagIds.contains(tag.tagId)) {
    platform.addConversationTag(conversation, tag.tagId).catchError(showAndLogError);
    view.conversationPanelView.addTags(new view.ConversationTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
  }
}

void setMultiConversationTag(model.Tag tag, List<model.Conversation> conversations) {
  conversations.forEach((conversation) {
    if (!conversation.tagIds.contains(tag.tagId)) {
      platform.addConversationTag(conversation, tag.tagId).catchError(showAndLogError);
      if (conversation == activeConversation) {
        view.conversationPanelView.addTags(new view.ConversationTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
      }
    }
  });
}

void setMessageTag(model.Tag tag, model.Message message, model.Conversation conversation) {
  if (!message.tagIds.contains(tag.tagId)) {
    platform.addMessageTag(activeConversation, message, tag.tagId).catchError(showAndLogError);
    view.conversationPanelView
      .messageViewAtIndex(conversation.messages.indexOf(message))
      .addTag(new view.MessageTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
  }
}

Set<model.Conversation> filterConversationsByTags(Set<model.Conversation> conversations, List<model.Tag> filterTags, DateTime afterDateFilter) {
  if (filterTags.isEmpty && afterDateFilter == null) return conversations;

  var filteredConversations = emptyConversationsSet;
  var filterTagIds = filterTags.map<String>((tag) => tag.tagId).toList();
  conversations.forEach((conversation) {
    // Filter by the last (most recent) conversation
    // TODO consider an option to filter by the first conversation
    if (afterDateFilter != null && conversation.messages.last.datetime.isBefore(afterDateFilter)) return;
    if (!conversation.tagIds.containsAll(filterTagIds)) return;
    filteredConversations.add(conversation);
  });
  return filteredConversations;
}

/// [SaveTextAction] manages changes to a model object's text field
/// by consolidating multiple keystrokes over a rolling 3 second period
/// into a single platform update operation.
///
/// Call [SaveTextAction.textChange] when a user modifies the field's text.
class SaveTextAction {
  /// The current action
  static SaveTextAction _currentAction;

  /// Update the text fields in a delayed fashion, where
  /// [changeId] is the id uniquely identifying the field being changed.
  static void textChange(String changeId, String newText, SaveText saveText) {
    assert(changeId != null);
    if (_currentAction?._changeId != changeId) {
      _currentAction = new SaveTextAction._(changeId, saveText);
    }
    _currentAction._textChanged(newText);
  }

  /// The identifier uniquely identifying the field being changed.
  final String _changeId;

  /// The function that will be called to store the new text
  final SaveText _saveText;

  /// A timer used to consolidate multiple keystroke changes to a field's text
  /// into a single save operation, or `null` if the text has been saved.
  Timer _timer;

  /// The text that should be saved
  String _newText = "";

  SaveTextAction._(this._changeId, this._saveText);

  void _textChanged(String newText) {
    _newText = newText;
    view.showNormalStatus('saving...');
    _timer?.cancel();
    _timer = new Timer(const Duration(seconds: 3), _updateField);
  }

  void _updateField() async {
    if (_currentAction == this) {
      _currentAction = null;
    }
    try {
      var newText = _newText;
      await _saveText(newText).catchError(showAndLogError);
      view.showNormalStatus('saved');
      log.verbose('note saved: $_changeId');
    } catch (e, s) {
      view.showWarningStatus('save failed');
      log.warning('save note failed: $_changeId\n  $e\n$s');
    }
  }
}

typedef Future<dynamic> SaveText(String newText);

void showAndLogError(error, trace) {
  log.error("$error${trace != null ? "\n$trace" : ""}");
  String errMsg;
  if (error is PubSubException) {
    errMsg = "A network problem occurred: ${error.message}";
  } else if (error is Exception) {
    errMsg = "An internal error occurred: ${error.runtimeType}";
  } else {
    errMsg = "$error";
  }
  view.snackbarView.showSnackbar(errMsg, view.SnackbarNotificationType.error);
}
