library controller;

import 'dart:async';
import 'dart:collection';

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
  promptAfterDateFilter,
  updateAfterDateFilter,
  filterOperationChanged,
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
  FilterType filterType;
  FilterTagData(this.tagId, this.filterType);
}

class AfterDateFilterData extends Data {
  String tagId;
  DateTime afterDateFilter;
  FilterType filterType;
  AfterDateFilterData(this.tagId, this.filterType, [this.afterDateFilter]);
}

class FilterOperationData extends Data {
  FilterType filterType;
  FilterOperation filterOperation;
  FilterOperationData(this.filterOperation, this.filterType);
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

enum FilterType {
  include,
  exclude
}

enum FilterOperation {
  all,
  any
}

class ConversationFilter {
  List<model.Tag> includeTags = [];
  FilterOperation includeLogic = FilterOperation.all;
  List<model.Tag> excludeTags = [];
  FilterOperation excludeLogic = FilterOperation.all;
  DateTime includeAfterDateFilter;
  DateTime excludeAfterDateFilter;

  static final defaultIncludeLogic = FilterOperation.all;
  static final defaultExcludeLogic = FilterOperation.all;

  bool contains(model.Tag tag) {
    return includeTags.contains(tag) || excludeTags.contains(tag);
  }

  bool get isEmpty => includeTags.isEmpty
                   && excludeTags.isEmpty
                   && includeAfterDateFilter == null
                   && excludeAfterDateFilter == null;
}

List<model.SystemMessage> systemMessages;

UIActionObject actionObjectState;

Set<model.Conversation> conversations;
Set<model.Conversation> filteredConversations;
List<model.SuggestedReply> suggestedReplies;
List<model.Tag> conversationTags;
List<model.Tag> messageTags;
ConversationFilter conversationFilter;
model.Conversation activeConversation;
List<model.Conversation> selectedConversations;
model.Message selectedMessage;
model.User signedInUser;

bool multiSelectMode;

void init() async {
  view.init();
  await platform.init();
}

void populateUI() {
  systemMessages = [];
  conversations = emptyConversationsSet;
  filteredConversations = conversations;
  suggestedReplies = [];
  conversationTags = [];
  messageTags = [];
  selectedConversations = [];
  multiSelectMode = false;

  activeConversation = updateViewForConversations(filteredConversations);
  platform.listenForConversationTags(
    (tags) {
      var updatedIds = tags.map((t) => t.tagId).toSet();
      conversationTags.removeWhere((tag) => updatedIds.contains(tag.tagId));
      conversationTags.addAll(tags);
      _populateFilterTagsMenu(conversationTags, FilterType.include);
      _populateFilterTagsMenu(conversationTags, FilterType.exclude);

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
      var updatedIds = updatedConversations.map((t) => t.deidentifiedPhoneNumber.value).toSet();
      conversations.removeWhere((conversation) => updatedIds.contains(conversation.deidentifiedPhoneNumber.value));
      conversations.addAll(updatedConversations);

      conversationFilter = createConversationFilterFromUrl();
      filteredConversations = filterConversationsByTags(conversations, conversationFilter);
      _populateFilterTagsMenu(conversationTags, FilterType.include);
      _populateFilterTagsMenu(conversationTags, FilterType.exclude);
      _populateSelectedFilterTags(conversationFilter);

      activeConversation = updateViewForConversations(filteredConversations);
      command(UIAction.markConversationRead, ConversationData(activeConversation.deidentifiedPhoneNumber.value));
    });

  platform.listenForSystemMessages(
    (updatedMessages) {
      var updatedIds = updatedMessages.map((m) => m.msgId).toSet();
      systemMessages.removeWhere((m) => updatedIds.contains(m.msgId));
      systemMessages.addAll(updatedMessages.where((m) => !m.expired));
      command(UIAction.updateSystemMessages, SystemMessagesData(systemMessages));
    });
}

ConversationFilter createConversationFilterFromUrl() {
  // include filter
  conversationFilter = new ConversationFilter();
  List<String> filterTagIds = view.urlView.readPageUrlFilterTags(FilterType.include);
  conversationFilter.includeTags = filterTagIds.map((tagId) => conversationTags.singleWhere((tag) => tag.tagId == tagId)).toList();

  var operation = view.urlView.readPageUrlFilterOperation(FilterType.include);
  conversationFilter.includeLogic = operation ?? ConversationFilter.defaultIncludeLogic;

  // exclude filter
  filterTagIds = view.urlView.readPageUrlFilterTags(FilterType.exclude);
  conversationFilter.excludeTags = filterTagIds.map((tagId) => conversationTags.singleWhere((tag) => tag.tagId == tagId)).toList();

  operation = view.urlView.readPageUrlFilterOperation(FilterType.exclude);
  conversationFilter.excludeLogic = operation ?? ConversationFilter.defaultExcludeLogic;

  // after date filter
  conversationFilter.includeAfterDateFilter = view.urlView.readPageUrlFilterAfterDate(FilterType.include);
  conversationFilter.excludeAfterDateFilter = view.urlView.readPageUrlFilterAfterDate(FilterType.exclude);

  return conversationFilter;
}

SplayTreeSet<model.Conversation> get emptyConversationsSet =>
    SplayTreeSet(model.Conversation.mostRecentInboundFirst);

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
      action != UIAction.filterOperationChanged &&
      action != UIAction.signInButtonClicked && action != UIAction.signOutButtonClicked &&
      action != UIAction.userSignedIn && action != UIAction.userSignedOut) {
    return;
  }

  switch (action) {
    case UIAction.sendMessage:
      ReplyData replyData = data;
      model.SuggestedReply selectedReply = suggestedReplies[replyData.replyIndex];
      if (!multiSelectMode) {
        sendReply(selectedReply, activeConversation);
        return;
      }
      if (!view.sendingMultiMessagesUserConfirmation(selectedConversations.length)) {
        return;
      }
      sendMultiReply(selectedReply, selectedConversations);
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
      List<model.Tag> tags = tagData.filterType == FilterType.include ? conversationFilter.includeTags : conversationFilter.excludeTags;
      if (tags.contains(tag)) break;
      tags.add(tag);
      view.urlView.writePageUrlFilterTags(tagData.filterType, tags.map((tag) => tag.tagId).toList());
      view.ConversationFilterView conversationFilterView = tagData.filterType == FilterType.include ? view.conversationIncludeFilter : view.conversationExcludeFilter;
      conversationFilterView.addFilterTag(new view.FilterTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), tagData.filterType));
      updateFilteredConversationList();
      break;
    case UIAction.removeConversationTag:
      ConversationTagData conversationTagData = data;
      model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
      activeConversation.tagIds.remove(tag.tagId);
      platform.updateConversationTags(activeConversation);
      view.conversationPanelView.removeTag(tag.tagId);
      if (conversationFilter.contains(tag)) {
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
      message.tagIds.removeWhere((id) => id == messageTagData.tagId);
      platform.updateConversationMessages(activeConversation);
      view.conversationPanelView
        .messageViewAtIndex(messageTagData.messageIndex)
        .removeTag(messageTagData.tagId);
      break;
    case UIAction.removeFilterTag:
      FilterTagData tagData = data;
      model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
      List<model.Tag> tags = tagData.filterType == FilterType.include ? conversationFilter.includeTags : conversationFilter.excludeTags;
      tags.remove(tag);
      view.urlView.writePageUrlFilterTags(tagData.filterType, tags.map((tag) => tag.tagId).toList());
      view.ConversationFilterView conversationFilterView = tagData.filterType == FilterType.include ? view.conversationIncludeFilter : view.conversationExcludeFilter;
      conversationFilterView.removeFilterTag(tag.tagId);
      updateFilteredConversationList();
      break;
    case UIAction.promptAfterDateFilter:
      AfterDateFilterData filterData = data;
      DateTime existingAfterDateFilter = filterData.filterType == FilterType.include ? conversationFilter.includeAfterDateFilter : conversationFilter.excludeAfterDateFilter;
      view.conversationPanelView.showAfterDateFilterPrompt(filterData.afterDateFilter ?? existingAfterDateFilter, filterData.filterType);
      break;
    case UIAction.updateAfterDateFilter:
      AfterDateFilterData filterData = data;
      switch (filterData.filterType) {
        case FilterType.include:
          conversationFilter.includeAfterDateFilter = filterData.afterDateFilter;
          view.urlView.writePageUrlFilterAfterDate(filterData.filterType, filterData.afterDateFilter);
          view.conversationIncludeFilter.removeFilterTag(filterData.tagId);
          if (filterData.afterDateFilter != null) {
            view.conversationIncludeFilter.addFilterTag(new view.AfterDateFilterTagView(filterData.afterDateFilter, filterData.filterType));
          }
          break;
        case FilterType.exclude:
          conversationFilter.excludeAfterDateFilter = filterData.afterDateFilter;
          view.urlView.writePageUrlFilterAfterDate(filterData.filterType, filterData.afterDateFilter);
          view.conversationExcludeFilter.removeFilterTag(filterData.tagId);
          if (filterData.afterDateFilter != null) {
            view.conversationExcludeFilter.addFilterTag(new view.AfterDateFilterTagView(filterData.afterDateFilter, filterData.filterType));
          }
          break;
      }
      updateFilteredConversationList();
      break;
    case UIAction.filterOperationChanged:
      FilterOperationData operationData = data;
      switch (operationData.filterType) {
        case FilterType.include:
          conversationFilter.includeLogic = operationData.filterOperation;
          break;
        case FilterType.exclude:
          conversationFilter.excludeLogic = operationData.filterOperation;
          break;
      }
      updateFilteredConversationList();
      view.urlView.writePageUrlFilterOperation(operationData.filterType, operationData.filterOperation);
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
      platform.updateUnread([activeConversation], false);
      break;
    case UIAction.markConversationUnread:
      if (multiSelectMode) {
        var markedConversations = <model.Conversation>[];
        for (var conversation in selectedConversations) {
          if (!conversation.unread) {
            markedConversations.add(conversation);
            view.conversationListPanelView.markConversationUnread(conversation.deidentifiedPhoneNumber.value);
          }
        }
        platform.updateUnread(markedConversations, true);
      } else {
        view.conversationListPanelView.markConversationUnread(activeConversation.deidentifiedPhoneNumber.value);
        platform.updateUnread([activeConversation], true);
      }
      break;
    case UIAction.showConversation:
      ConversationData conversationData = data;
      activeConversation = filteredConversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.value == conversationData.deidentifiedPhoneNumber);
      updateViewForConversation(activeConversation);
      break;
    case UIAction.selectConversation:
      ConversationData conversationData = data;
      model.Conversation conversation = filteredConversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.value == conversationData.deidentifiedPhoneNumber);
      selectedConversations.add(conversation);
      break;
    case UIAction.deselectConversation:
      ConversationData conversationData = data;
      model.Conversation conversation = filteredConversations.singleWhere((conversation) => conversation.deidentifiedPhoneNumber.value == conversationData.deidentifiedPhoneNumber);
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
        activeConversation.messages[messageTranslation.messageIndex].translation = messageTranslation.translationText;
        platform.updateConversationMessages(activeConversation);
      }
      break;
    case UIAction.updateNote:
      SaveTextAction.textChange(
        "${activeConversation.docId}.notes",
        (data as NoteData).noteText,
        (newText) => platform.updateNotes(activeConversation, newText),
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
  }
}

void updateFilteredConversationList() {
  filteredConversations = filterConversationsByTags(conversations, conversationFilter);
  activeConversation = updateViewForConversations(filteredConversations);
  if (multiSelectMode) {
    view.conversationListPanelView.showCheckboxes();
    selectedConversations = selectedConversations.toSet().intersection(filteredConversations.toSet()).toList();
    selectedConversations.forEach((conversation) => view.conversationListPanelView.checkConversation(conversation.deidentifiedPhoneNumber.value));
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
  if (conversation == null) return;
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
    ..tagIds = [];
  conversation.messages.add(newMessage);
  view.conversationPanelView.addMessage(
    new view.MessageView(
      newMessage.text,
      newMessage.datetime,
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
        activeConversation.deidentifiedPhoneNumber.value,
        activeConversation.messages.indexOf(newMessage),
        translation: newMessage.translation,
        incoming: false)
    );
  }
  List<String> ids = conversations.map((conversation) => conversation.deidentifiedPhoneNumber.value).toList();
  platform
    .sendMultiMessage(ids, newMessage.text)
    .then((success) {
      log.verbose('controller.sendMultiMessage reponse status $success');
    });
}

void setConversationTag(model.Tag tag, model.Conversation conversation) {
  if (!conversation.tagIds.contains(tag.tagId)) {
    conversation.tagIds.add(tag.tagId);
    platform.updateConversationTags(conversation);
    view.conversationPanelView.addTags(new view.ConversationTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
  }
}

void setMultiConversationTag(model.Tag tag, List<model.Conversation> conversations) {
  conversations.forEach((conversation) {
    if (!conversation.tagIds.contains(tag.tagId)) {
      conversation.tagIds.add(tag.tagId);
      platform.updateConversationTags(conversation);
      if (conversation == activeConversation) {
        view.conversationPanelView.addTags(new view.ConversationTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
      }
    }
  });
}

void setMessageTag(model.Tag tag, model.Message message, model.Conversation conversation) {
  if (!message.tagIds.contains(tag.tagId)) {
    message.tagIds.add(tag.tagId);
    platform.updateConversationMessages(activeConversation);
    view.conversationPanelView
      .messageViewAtIndex(conversation.messages.indexOf(message))
      .addTag(new view.MessageTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
  }
}

Set<model.Conversation> filterConversationsByTags(Set<model.Conversation> conversations, ConversationFilter conversationFilter) {
  if (conversationFilter.isEmpty) return conversations;

  var filteredConversations = emptyConversationsSet;
  var includeFilterTagIds = conversationFilter.includeTags.map<String>((tag) => tag.tagId).toSet();
  var excludeFilterTagIds = conversationFilter.excludeTags.map<String>((tag) => tag.tagId).toSet();
  conversations.forEach((conversation) {
    // Filter by the last (most recent) message
    // TODO consider an option to filter by the first message
    if (conversationFilter.includeAfterDateFilter != null && conversation.messages.last.datetime.isBefore(conversationFilter.includeAfterDateFilter)) return;
    if (conversationFilter.excludeAfterDateFilter != null && conversation.messages.last.datetime.isAfter(conversationFilter.excludeAfterDateFilter)) return;

    if (conversationFilter.includeTags.isNotEmpty) {
      switch (conversationFilter.includeLogic) {
        case FilterOperation.all:
          if (!conversation.tagIds.toSet().containsAll(includeFilterTagIds)) return;
          break;
        case FilterOperation.any:
          if (!conversation.tagIds.toSet().intersection(includeFilterTagIds).isNotEmpty) return;
          break;
      }
    }

    if (conversationFilter.excludeTags.isNotEmpty) {
      switch (conversationFilter.excludeLogic) {
        case FilterOperation.all:
          if (conversation.tagIds.toSet().containsAll(excludeFilterTagIds)) return;
          break;
        case FilterOperation.any:
          if (conversation.tagIds.toSet().intersection(excludeFilterTagIds).isNotEmpty) return;
          break;
      }
    }

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
      await _saveText(newText);
      view.showNormalStatus('saved');
      log.verbose('note saved: $_changeId');
    } catch (e, s) {
      view.showWarningStatus('save failed');
      log.warning('save note failed: $_changeId\n  $e\n$s');
    }
  }
}

typedef Future<dynamic> SaveText(String newText);
