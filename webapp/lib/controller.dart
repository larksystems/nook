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
  selectConversationList,
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
  selectAllConversations,
  deselectAllConversations,
  updateSystemMessages,
  updateSuggestedRepliesCategory,
  hideAgeTags,
  showSnackbar
}

class Data {}

class MessageData extends Data {
  String conversationId;
  int messageIndex;
  MessageData(this.conversationId, this.messageIndex);

  @override
  String toString() => 'MessageData: {conversationId: $conversationId, messageIndex: $messageIndex}';
}

class ReplyData extends Data {
  int replyIndex;
  bool replyWithTranslation;
  ReplyData(this.replyIndex, {this.replyWithTranslation: false});

  @override
  String toString() => 'ReplyData: {replyIndex: $replyIndex, replyWithTranslation: $replyWithTranslation}';
}

class ManualReplyData extends Data {
  String replyText;
  ManualReplyData(this.replyText);

  @override
  String toString() => 'ManualReplyData: {replyText: $replyText}';
}

class TranslationData extends Data {
  String translationText;
  String conversationId;
  int messageIndex;
  TranslationData(this.translationText, this.conversationId, this.messageIndex);

  @override
  String toString() => 'TranslationData: {translationText: $translationText, conversationId: $conversationId, messageIndex: $messageIndex}';
}

class ReplyTranslationData extends Data {
  String translationText;
  int replyIndex;
  ReplyTranslationData(this.translationText, this.replyIndex);

  @override
  String toString() => 'ReplyTranslationData: {translationText: $translationText, replyIndex: $replyIndex}';
}

class MessageTagData extends Data {
  String tagId;
  int messageIndex;
  MessageTagData(this.tagId, this.messageIndex);

  @override
  String toString() => 'MessageTagData: {tagId: $tagId, messageIndex: $messageIndex}';
}

class ConversationTagData extends Data {
  String tagId;
  String conversationId;
  ConversationTagData(this.tagId, this.conversationId);

  @override
  String toString() => 'ConversationTagData: {tagId: $tagId, conversationId: $conversationId}';
}

class FilterTagData extends Data {
  String tagId;
  FilterTagData(this.tagId);

  @override
  String toString() => 'FilterTagData: {tagId: $tagId}';
}

class AfterDateFilterData extends Data {
  String tagId;
  DateTime afterDateFilter;
  AfterDateFilterData(this.tagId, [this.afterDateFilter]);

  @override
  String toString() => 'AfterDateFilter: {tagId: $tagId, afterDateFilter: $afterDateFilter}';
}

class ConversationListData extends Data {
  static const NONE = 'none';
  String conversationListRoot;
  ConversationListData(this.conversationListRoot);

  @override
  String toString() => 'ConversationListData: {conversationListRoot: $conversationListRoot}';
}

class ConversationData extends Data {
  String deidentifiedPhoneNumber;
  ConversationData(this.deidentifiedPhoneNumber);

  @override
  String toString() => 'ConversationData: {deidentifiedPhoneNumber: $deidentifiedPhoneNumber}';
}

class TagData extends Data {
  String tagId;
  TagData(this.tagId);

  @override
  String toString() => 'TagData: {tagId: $tagId}';
}

class NoteData extends Data {
  String noteText;
  NoteData(this.noteText);

  @override
  String toString() => 'NoteData: {noteText: $noteText}';

}

class UserData extends Data {
  String displayName;
  String email;
  String photoUrl;
  UserData(this.displayName, this.email, this.photoUrl);

  @override
  String toString() => 'UserData: {displayName: $displayName, email: $email, photoUrl: $photoUrl}';
}

class KeyPressData extends Data {
  String key;
  KeyPressData(this.key);

  @override
  String toString() => 'KeyPressData: {key: $key}';
}

class AddSuggestedReplyData extends Data {
  String replyText;
  String translationText;
  AddSuggestedReplyData(this.replyText, this.translationText);

  @override
  String toString() => 'AddSuggestedReply: {replyText: $replyText, translationText: $translationText}';
}

class AddTagData extends Data {
  String tagText;
  AddTagData(this.tagText);

  @override
  String toString() => 'AddTagData: {tagText: $tagText}';
}

class UpdateSuggestedRepliesCategoryData extends Data {
  String category;
  UpdateSuggestedRepliesCategoryData(this.category);

  @override
  String toString() => 'UpdateSuggestedReplies: {category: $category}';
}

class SystemMessagesData extends Data {
  List<model.SystemMessage> messages;
  SystemMessagesData(this.messages);

  @override
  String toString() => 'SystemMessagesData: {messages: ${messages.map((m) => m.toData().toString())}}';
}

class ToggleData extends Data {
  bool toggleValue;
  ToggleData(this.toggleValue);

  @override
  String toString() => 'ToggleData: {toggleValue: $toggleValue}';
}

class SnackbarData extends Data {
  String text;
  SnackbarNotificationType type;
  SnackbarData(text, type);

  @override
  String toString() => 'SnackbarData: {text: $text, type: $type}';
}

List<model.SystemMessage> systemMessages;

UIActionObject actionObjectState = UIActionObject.conversation;

StreamSubscription conversationListSubscription;
Set<model.Conversation> conversations;
Set<model.Conversation> filteredConversations;
List<model.SuggestedReply> suggestedReplies;
Map<String, List<model.SuggestedReply>> suggestedRepliesByCategory;
String selectedSuggestedRepliesCategory;
List<model.Tag> conversationTags;
List<model.Tag> messageTags;
List<model.Tag> filterTags;
DateTime afterDateFilter;
model.Conversation activeConversation;
List<model.Conversation> selectedConversations;
model.Message selectedMessage;
model.User signedInUser;

model.UserConfiguration defaultUserConfig;
model.UserConfiguration currentUserConfig;
/// This represents the current configuration of the UI.
/// It's computed by merging the [defaultUserConfig] and [currentUserConfig] (if set).
model.UserConfiguration currentConfig;

bool hideDemogsTags;

void init() async {
  defaultUserConfig = currentConfig = baseUserConfiguration;
  currentUserConfig = emptyUserConfiguration;
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
  activeConversation = null;
  selectedSuggestedRepliesCategory = '';
  hideDemogsTags = true;

  platform.listenForConversationTags(
    (added, modified, removed) {
      var updatedIds = new Set()
        ..addAll(added.map((t) => t.tagId))
        ..addAll(modified.map((t) => t.tagId))
        ..addAll(removed.map((t) => t.tagId));
      conversationTags.removeWhere((tag) => updatedIds.contains(tag.tagId));
      conversationTags
        ..addAll(added)
        ..addAll(modified);

      var filteredTags = _filterDemogsTagsIfNeeded(conversationTags);
      _populateFilterTagsMenu(filteredTags);

      if (actionObjectState == UIActionObject.conversation) {
        _populateTagPanelView(filteredTags, TagReceiver.Conversation);
      }
    }
  );

  platform.listenForMessageTags(
    (added, modified, removed) {
      var updatedIds = new Set()
        ..addAll(added.map((t) => t.tagId))
        ..addAll(modified.map((t) => t.tagId))
        ..addAll(removed.map((t) => t.tagId));
      messageTags.removeWhere((tag) => updatedIds.contains(tag.tagId));
      messageTags
        ..addAll(added)
        ..addAll(modified);

      if (actionObjectState == UIActionObject.message) {
        _populateTagPanelView(_filterDemogsTagsIfNeeded(messageTags), TagReceiver.Message);
      }
    }
  );

  if (view.urlView.shouldDisableReplies) {
    view.replyPanelView.disableReplies();
  } else {
    platform.listenForSuggestedReplies(
      (added, modified, removed) {
        var updatedIds = new Set()
          ..addAll(added.map((r) => r.suggestedReplyId))
          ..addAll(modified.map((r) => r.suggestedReplyId))
          ..addAll(removed.map((r) => r.suggestedReplyId));
        suggestedReplies.removeWhere((suggestedReply) => updatedIds.contains(suggestedReply.suggestedReplyId));
        suggestedReplies
          ..addAll(added)
          ..addAll(modified);

        // Update the replies by category map
        suggestedRepliesByCategory = _groupRepliesIntoCategories(suggestedReplies);
        // Empty sublist if there are no replies to show
        if (suggestedRepliesByCategory.isEmpty) {
          suggestedRepliesByCategory[''] = [];
        }
        // Sort by sequence number
        for (var replies in suggestedRepliesByCategory.values) {
          replies.sort((r1, r2) {
            var seqNo1 = r1.seqNumber == null ? double.nan : r1.seqNumber;
            var seqNo2 = r2.seqNumber == null ? double.nan : r2.seqNumber;
            return seqNo1.compareTo(seqNo2);
          });
        }
        List<String> categories = suggestedRepliesByCategory.keys.toList();
        categories.sort((c1, c2) => c1.compareTo(c2));
        // Replace list of categories in the UI selector
        view.replyPanelView.categories = categories;
        // If the categories have changed under us and the selected one no longer exists,
        // default to the first category, whichever it is
        if (!categories.contains(selectedSuggestedRepliesCategory)) {
          selectedSuggestedRepliesCategory = categories.first;
        }
        // Select the selected category in the UI and add the suggested replies for it
        view.replyPanelView.selectedCategory = selectedSuggestedRepliesCategory;
        _populateReplyPanelView(suggestedRepliesByCategory[selectedSuggestedRepliesCategory]);
      }
    );
  }

  platform.listenForConversationListShards(
    (added, modified, removed) {
      // TODO: handle removed shards as well
      List<model.ConversationListShard> shards = new List()
        ..addAll(added)
        ..addAll(modified);
      view.conversationListSelectView.updateConversationLists(shards);
    }
  );

  platform.listenForSystemMessages(
    (added, modified, removed) {
      var updatedIds = new Set()
        ..addAll(added.map((m) => m.msgId))
        ..addAll(modified.map((m) => m.msgId))
        ..addAll(removed.map((m) => m.msgId));
      systemMessages.removeWhere((systemMessage) => updatedIds.contains(systemMessage.msgId));
      systemMessages
        ..addAll(added.where((m) => !m.expired))
        ..addAll(modified.where((m) => !m.expired));
      command(UIAction.updateSystemMessages, SystemMessagesData(systemMessages));
    }
  );

  platform.listenForUserConfigurations(
    (added, modified, removed) {
      List<model.UserConfiguration> changedUserConfigurations = new List()
        ..addAll(added)
        ..addAll(modified);
      var defaultConfig = changedUserConfigurations.singleWhere((c) => c.docId == 'default', orElse: () => null);
      defaultConfig = removed.where((c) => c.docId == 'default').length > 0 ? baseUserConfiguration : defaultConfig;
      var userConfig = changedUserConfigurations.singleWhere((c) => c.docId == signedInUser.userEmail, orElse: () => null);
      userConfig = removed.where((c) => c.docId == signedInUser.userEmail).length > 0 ? emptyUserConfiguration : userConfig;
      if (defaultConfig == null && userConfig == null) {
        // Neither of the relevant configurations has been changed, nothing to do here
        return;
      }
      defaultUserConfig = defaultConfig ?? defaultUserConfig;
      currentUserConfig = userConfig ?? currentUserConfig;
      var newConfig = currentUserConfig.applyDefaults(defaultUserConfig);
      applyConfiguration(newConfig);
    }
  );
}


/// Sets user customization flags from the data map
/// If a flag is not set in the data map, it defaults to the existing values
void applyConfiguration(model.UserConfiguration newConfig) {
  if (currentConfig.keyboardShortcutsEnabled != newConfig.keyboardShortcutsEnabled) {
    newConfig.keyboardShortcutsEnabled ? view.replyPanelView.showShortcuts() : view.replyPanelView.hideShortcuts();
    newConfig.keyboardShortcutsEnabled ? view.tagPanelView.showShortcuts() : view.tagPanelView.hideShortcuts();
  }

  if (currentConfig.sendCustomMessagesEnabled != newConfig.sendCustomMessagesEnabled) {
    newConfig.sendCustomMessagesEnabled ? view.conversationPanelView.showCustomMessageBox() : view.conversationPanelView.hideCustomMessageBox();
  }

  if (currentConfig.sendMultiMessageEnabled != newConfig.sendMultiMessageEnabled) {
    if (newConfig.sendMultiMessageEnabled) {
      view.conversationListPanelView.showCheckboxes();
    } else {
      view.conversationListPanelView.hideCheckboxes();
      command(UIAction.deselectAllConversations, null);
    }
  }

  if (currentConfig.tagPanelVisibility != newConfig.tagPanelVisibility) {
    newConfig.tagPanelVisibility ? view.showTagPanel() : view.hideTagPanel();
  }

  currentConfig = newConfig;
  log.verbose('Updated user configuration: $currentConfig');
}

void conversationListSelected(String conversationListRoot) {
  command(UIAction.deselectAllConversations, null);
  conversationListSubscription?.cancel();
  conversationListSubscription = null;
  if (conversationListRoot == ConversationListData.NONE) return;
  conversationListSubscription = platform.listenForConversations(
    (added, modified, removed) {
      if (added.length > 0) {
        log.verbose("adding ${added.length} conversation(s)");
      }
      if (modified.length > 0) {
        log.verbose("modifying ${modified.length} conversation(s)");
      }
      if (removed.length > 0) {
        log.verbose("removing ${removed.length} conversation(s)");
      }
      var updatedIds = new Set()
        ..addAll(added.map((c) => c.docId))
        ..addAll(modified.map((c) => c.docId))
        ..addAll(removed.map((c) => c.docId));
      List<model.Conversation> changedConversations = conversations.where((conversation) => updatedIds.contains(conversation.docId)).toList();
      conversations.removeAll(changedConversations);
      conversations
        ..addAll(added)
        ..addAll(modified);

      log.debug('Updated Ids: $updatedIds');
      log.debug('Old conversations: $changedConversations');
      log.debug('New conversations, added: $added');
      log.debug('New conversations, modified: $modified');
      log.debug('New conversations, removed: $removed');

      // TODO even though they are unlikely to happen, we should also handle the removals in the UI for consistency

      // Determine if the active conversation data needs to be replaced
      String activeConversationId = activeConversation?.docId;
      if (updatedIds.contains(activeConversationId)) {
        activeConversation = conversations.firstWhere((c) => c.docId == activeConversationId);
      }

      // Get any filter tags from the url
      List<String> filterTagIds = view.urlView.pageUrlFilterTags;
      filterTags = filterTagIds.map((tagId) => conversationTags.singleWhere((tag) => tag.tagId == tagId)).toList();
      filteredConversations = filterConversationsByTags(conversations, filterTags, afterDateFilter);
      _populateFilterTagsMenu(_filterDemogsTagsIfNeeded(conversationTags));
      _populateSelectedFilterTags(filterTags);

      activeConversation = updateViewForConversations(filteredConversations, updateList: true);
      if (currentConfig.sendMultiMessageEnabled) {
        view.conversationListPanelView.showCheckboxes();
        Set selectedConversationsIds = selectedConversations.map((c) => c.docId).toSet();
        Set filteredConversationsIds = filteredConversations.map((c) => c.docId).toSet();
        Set updatedSelectedConversationsIds = selectedConversationsIds.intersection(filteredConversationsIds);
        selectedConversations = filteredConversations.where((c) => updatedSelectedConversationsIds.contains(c.docId)).toList();
        selectedConversations.forEach((conversation) => view.conversationListPanelView.checkConversation(conversation.docId));
      }
      if (activeConversation == null) return;

      // Update the active conversation view as needed
      if (updatedIds.contains(activeConversation.docId)) {
        updateViewForConversation(activeConversation);
      }
      command(UIAction.markConversationRead, ConversationData(activeConversation.docId));
    },
    conversationListRoot);
}

SplayTreeSet<model.Conversation> get emptyConversationsSet =>
    SplayTreeSet(model.ConversationUtil.mostRecentInboundFirst);

model.UserConfiguration get baseUserConfiguration => new model.UserConfiguration()
    ..keyboardShortcutsEnabled = false
    ..sendCustomMessagesEnabled = false
    ..sendMultiMessageEnabled = false
    ..tagPanelVisibility = false;

model.UserConfiguration get emptyUserConfiguration => new model.UserConfiguration();

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

DateTime lastUserActivity = new DateTime.now();

void command(UIAction action, Data data) {
  log.verbose('Executing UI command: $actionObjectState - $action - $data');
  log.verbose('Active conversation: ${activeConversation?.docId}');
  log.verbose('Selected conversations: ${selectedConversations?.map((c) => c.docId)?.toList()}');

  // For most actions, a conversation needs to be active.
  // Early exist if it's not one of the actions valid without an active conversation.
  if (activeConversation == null &&
      action != UIAction.selectConversationList &&
      action != UIAction.addFilterTag && action != UIAction.removeFilterTag &&
      action != UIAction.promptAfterDateFilter && action != UIAction.updateAfterDateFilter &&
      action != UIAction.signInButtonClicked && action != UIAction.signOutButtonClicked &&
      action != UIAction.userSignedIn && action != UIAction.userSignedOut &&
      action != UIAction.updateSuggestedRepliesCategory && action != UIAction.hideAgeTags &&
      action != UIAction.selectAllConversations && action != UIAction.deselectAllConversations &&
      action != UIAction.showSnackbar) {
    return;
  }

  switch (action) {
    case UIAction.userSignedIn:
    case UIAction.userSignedOut:
    case UIAction.updateSystemMessages:
    case UIAction.showSnackbar:
      // These are not user actions, skip
      break;
    default:
      lastUserActivity = new DateTime.now();
      break;
  }

  switch (action) {
    case UIAction.sendMessage:
      ReplyData replyData = data;
      model.SuggestedReply selectedReply = suggestedRepliesByCategory[selectedSuggestedRepliesCategory][replyData.replyIndex];
      if (replyData.replyWithTranslation) {
        model.SuggestedReply translationReply = new model.SuggestedReply();
        translationReply
          ..text = selectedReply.translation
          ..translation = '';
        selectedReply = translationReply;
      }
      if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
        sendReply(selectedReply, activeConversation);
        return;
      }
      if (!view.sendingMultiMessagesUserConfirmation(selectedConversations.length)) {
        log.verbose('User cancelled sending multi message reply: "${selectedReply.text}"');
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
      if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
        if (!view.sendingManualMessageUserConfirmation(oneoffReply.text)) {
          log.verbose('User cancelled sending manual message reply: "${oneoffReply.text}"');
          return;
        }
        sendReply(oneoffReply, activeConversation);
        view.conversationPanelView.clearNewMessageBox();
        return;
      }
      if (!view.sendingManualMultiMessageUserConfirmation(oneoffReply.text, selectedConversations.length)) {
        log.verbose('User cancelled sending manual multi message reply: "${oneoffReply.text}"');
        return;
      }
      sendMultiReply(oneoffReply, selectedConversations);
      view.conversationPanelView.clearNewMessageBox();
      break;
    case UIAction.addTag:
      TagData tagData = data;
      switch (actionObjectState) {
        case UIActionObject.conversation:
          model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == tagData.tagId);
          if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
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
        filteredConversations.remove(activeConversation);
        view.conversationPanelView.showWarning('Conversation no longer meets filtering constraints');
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
      _populateTagPanelView(_filterDemogsTagsIfNeeded(messageTags), TagReceiver.Message);
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
          _populateTagPanelView(_filterDemogsTagsIfNeeded(conversationTags), TagReceiver.Conversation);
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
      if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
        view.conversationListPanelView.markConversationUnread(activeConversation.docId);
        platform.updateUnread([activeConversation], true).catchError(showAndLogError);
        return;
      }
      var markedConversations = <model.Conversation>[];
      for (var conversation in selectedConversations) {
        if (!conversation.unread) {
          markedConversations.add(conversation);
          view.conversationListPanelView.markConversationUnread(conversation.docId);
        }
      }
      platform.updateUnread(markedConversations, true).catchError(showAndLogError);
      break;
    case UIAction.showConversation:
      ConversationData conversationData = data;
      activeConversation = filteredConversations.singleWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
      updateViewForConversation(activeConversation);
      break;
    case UIAction.selectConversationList:
      ConversationListData conversationListData = data;
      conversations = emptyConversationsSet;
      filteredConversations = emptyConversationsSet;
      selectedConversations.clear();
      activeConversation = null;
      view.conversationListPanelView.clearConversationList();
      view.conversationPanelView.clear();
      activeConversation = null;
      if (conversationListData.conversationListRoot == ConversationListData.NONE) {
        view.conversationListPanelView.showSelectConversationListMessage();
      } else {
        view.conversationListPanelView.showLoadSpinner();
      }
      conversationListSelected(conversationListData.conversationListRoot);
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
        var reply = suggestedRepliesByCategory[selectedSuggestedRepliesCategory][data.replyIndex];
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
      // Keyboard shortcuts not enabled, skip processing the action.
      if (!currentConfig.keyboardShortcutsEnabled) return;

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
      var selectedReply = suggestedRepliesByCategory[selectedSuggestedRepliesCategory].where((reply) => reply.shortcut == keyPressData.key);
      if (selectedReply.isNotEmpty) {
        assert (selectedReply.length == 1);
        if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
          sendReply(selectedReply.first, activeConversation);
          return;
        }
        if (!view.sendingMultiMessagesUserConfirmation(selectedConversations.length)) {
          return;
        }
        sendMultiReply(selectedReply.first, selectedConversations);
        return;
      }
      // If the shortcut is for a tag and tag panel is enabled, find it and tag it to the conversation/message
      if (!currentConfig.tagPanelVisibility) return;
      switch (actionObjectState) {
        case UIActionObject.conversation:
          var selectedTag = _filterDemogsTagsIfNeeded(conversationTags).where((tag) => tag.shortcut == keyPressData.key);
          if (selectedTag.isEmpty) break;
          assert (selectedTag.length == 1);
          setConversationTag(selectedTag.first, activeConversation);
          if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
            setConversationTag(selectedTag.first, activeConversation);
            return;
          }
          if (!view.taggingMultiConversationsUserConfirmation(selectedConversations.length)) {
            return;
          }
          setMultiConversationTag(selectedTag.first, selectedConversations);
          return;
        case UIActionObject.message:
          var selectedTag = _filterDemogsTagsIfNeeded(messageTags).where((tag) => tag.shortcut == keyPressData.key);
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
    case UIAction.selectAllConversations:
      view.conversationListPanelView.checkAllConversations();
      selectedConversations.clear();
      selectedConversations.addAll(filteredConversations);
      break;
    case UIAction.deselectAllConversations:
      view.conversationListPanelView.uncheckSelectAllCheckbox();
      view.conversationListPanelView.uncheckAllConversations();
      selectedConversations.clear();
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
    case UIAction.updateSuggestedRepliesCategory:
      UpdateSuggestedRepliesCategoryData updateCategoryData = data;
      selectedSuggestedRepliesCategory = updateCategoryData.category;
      _populateReplyPanelView(suggestedRepliesByCategory[selectedSuggestedRepliesCategory]);
      break;
    case UIAction.hideAgeTags:
      ToggleData toggleData = data;
      hideDemogsTags = toggleData.toggleValue;
      var filteredConversationTags = _filterDemogsTagsIfNeeded(conversationTags);
      var filteredMessageTags = _filterDemogsTagsIfNeeded(messageTags);
      switch (actionObjectState) {
        case UIActionObject.conversation:
          _populateTagPanelView(filteredConversationTags, TagReceiver.Conversation);
          break;
        case UIActionObject.message:
          _populateTagPanelView(filteredMessageTags, TagReceiver.Message);
          break;
      }
      // The filter tags menu always shows conversations tags, even when a message is selected
      _populateFilterTagsMenu(filteredConversationTags);
      break;

    case UIAction.showSnackbar:
      SnackbarData snackbarData = data;
      view.snackbarView.showSnackbar(snackbarData.text, snackbarData.type);
      break;
  }
}

void updateFilteredConversationList() {
  filteredConversations = filterConversationsByTags(conversations, filterTags, afterDateFilter);
  activeConversation = updateViewForConversations(filteredConversations);
  if (currentConfig.sendMultiMessageEnabled) {
    view.conversationListPanelView.showCheckboxes();
    selectedConversations = selectedConversations.toSet().intersection(filteredConversations.toSet()).toList();
    selectedConversations.forEach((conversation) => view.conversationListPanelView.checkConversation(conversation.docId));
  }
}

/// Shows the list of [conversations] and selects the first conversation
/// where [updateList] is `true` if this list can be updated in place.
/// Returns the first conversation in the list, or null if list is empty.
model.Conversation updateViewForConversations(Set<model.Conversation> conversations, {bool updateList = false}) {
  // Update conversationListPanelView
  _populateConversationListPanelView(conversations, updateList);

  // Update conversationPanelView
  if (conversations.isEmpty) {
    if (activeConversation != null) {
      view.conversationPanelView.showWarning('Conversation no longer meets filtering constraints');
      return activeConversation;
    }
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
    view.conversationPanelView.showWarning('Conversation no longer meets filtering constraints');
    return activeConversation;
  }

  if (matches.length > 1) {
    log.warning('Two conversations seem to have the same deidentified phone number: ${activeConversation.docId}');
  }
  view.conversationListPanelView.selectConversation(activeConversation.docId);
  view.conversationPanelView.clearWarning();
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
      _populateTagPanelView(_filterDemogsTagsIfNeeded(conversationTags), TagReceiver.Conversation);
      break;
  }
}

void sendReply(model.SuggestedReply reply, model.Conversation conversation) {
  log.verbose('Preparing to send reply "${reply.text}" to conversation ${conversation.docId}');
  model.Message newMessage = new model.Message()
    ..text = reply.text
    ..datetime = new DateTime.now()
    ..direction = model.MessageDirection.Out
    ..translation = reply.translation
    ..tagIds = [];
  log.verbose('Adding reply "${reply.text}" to conversation ${conversation.docId}');
  conversation.messages.add(newMessage);
  var newMessageView = new view.MessageView(
      newMessage.text,
      newMessage.datetime,
      conversation.docId,
      conversation.messages.indexOf(newMessage),
      translation: newMessage.translation,
      incoming: false);
  view.conversationPanelView.addMessage(newMessageView);
  log.verbose('Sending reply "${reply.text}" to conversation ${conversation.docId}');
  platform.sendMessage(conversation.docId, reply.text, onError: (error) {
    log.error('Reply "${reply.text}" failed to be sent to conversation ${conversation.docId}');
    log.error('Error: ${error}');
    command(UIAction.showSnackbar, new SnackbarData('Send Reply Failed', SnackbarNotificationType.error));
    newMessage.status = model.MessageStatus.failed;
    newMessageView.setStatus(newMessage.status);
  });
  log.verbose('Reply "${reply.text}" queued for sending to conversation ${conversation.docId}');
}

void sendMultiReply(model.SuggestedReply reply, List<model.Conversation> conversations) {
  List<String> conversationIds = conversations.map((conversation) => conversation.docId).toList();
  log.verbose('Preparing to send reply "${reply.text}" to conversations $conversationIds');
  model.Message newMessage = new model.Message()
    ..text = reply.text
    ..datetime = new DateTime.now()
    ..direction = model.MessageDirection.Out
    ..translation = reply.translation
    ..tagIds = [];
  log.verbose('Adding reply "${reply.text}" to conversations ${conversationIds}');
  conversations.forEach((conversation) => conversation.messages.add(newMessage));
  view.MessageView newMessageView;
  if (conversations.contains(activeConversation)) {
    newMessageView = new view.MessageView(
        newMessage.text,
        newMessage.datetime,
        activeConversation.docId,
        activeConversation.messages.indexOf(newMessage),
        translation: newMessage.translation,
        incoming: false);
    view.conversationPanelView.addMessage(newMessageView);
  }
  log.verbose('Sending reply "${reply.text}" to conversations ${conversationIds}');
  platform.sendMultiMessage(conversationIds, newMessage.text, onError: (error) {
    log.error('Reply "${reply.text}" failed to be sent to conversations ${conversationIds}');
    log.error('Error: ${error}');
    command(UIAction.showSnackbar, new SnackbarData('Send Multi Reply Failed', SnackbarNotificationType.error));
    newMessage.status = model.MessageStatus.failed;
    newMessageView?.setStatus(newMessage.status);
  });
  log.verbose('Reply "${reply.text}" queued for sending to conversations ${conversationIds}');
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

List<model.Tag> _filterDemogsTagsIfNeeded(List<model.Tag> tagList) {
  if (hideDemogsTags == false)
    return tagList;
  return tagList.where((model.Tag tag) => !_isDemogTag(tag)).toList();
}

bool _isDemogTag(model.Tag tag) {
  if (int.tryParse(tag.text) != null) {
    return true;
  }

  const TAG_LIST = [
    "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99",
    "ainabkoi", "ainamoi", "aldai", "alego_usonga", "awendo", "bahati", "balambala", "banissa", "baringo_central", "baringo_north", "baringo_south", "belgut", "bobasi", "bomachoge_borabu", "bomachoge_chache", "bomet_central", "bomet_east", "bonchari", "bondo", "borabu", "budalangi", "bumula", "bura", "bureti", "butere", "butula", "buuri", "central_imenti", "changamwe", "chepalungu", "cherangany", "chesumei", "dadaab", "dagoretti_north", "dagoretti_south", "eldama_ravine", "eldas", "embakasi_central", "embakasi_east", "embakasi_north", "embakasi_south", "embakasi_west", "emgwen", "emuhaya", "emurua_dikirr", "endebess", "fafi", "funyula", "galole", "ganze", "garissa_township", "garsen", "gatanga", "gatundu_north", "gatundu_south", "gem", "gichugu", "gilgil", "githunguri", "hamisi", "homa_bay_town", "igambang_ombe", "igembe_central", "igembe_north", "igembe_south", "ijara", "ikolomani", "isiolo_north", "isiolo_south", "jomvu", "juja", "kabete", "kabondo_kasipul", "kabuchai", "kacheliba", "kaimbaa", "kaiti", "kajiado_central", "kajiado_east", "kajiado_north", "kajiado_south", "kajiado_west", "kaloleni", "kamukunji", "kandara", "kanduyi", "kangema", "kangundo", "kapenguria", "kapseret", "karachuonyo", "kasarani", "kasipul", "kathiani", "keiyo_north", "keiyo_south", "kesses", "khwisero", "kiambu", "kibra", "kibwezi_east", "kibwezi_west", "kieni", "kigumo", "kiharu", "kikuyu", "kilgoris", "kilifi_north", "kilifi_south", "kilome", "kimilili", "kiminini", "kinango", "kinangop", "kipipiri", "kipkelion_east", "kipkelion_west", "kirinyaga_central", "kisauni", "kisumu_central", "kisumu_east", "kisumu_west", "kitui_central", "kitui_east", "kitui_rural", "kitui_south", "kitui_west", "kitutu_chache_north", "kitutu_chache_south", "kitutu_masaba", "konoin", "kuresoi_north", "kuresoi_south", "kuria_east", "kuria_west", "kwanza", "lafey", "lagdera", "laikipia_east", "laikipia_north", "laikipia_west", "laisamis", "lamu_east", "lamu_west", "lang'ata", "lari", "likoni", "likuyani", "limuru", "loima", "luanda", "lugari", "lunga_lunga", "lurambi", "maara", "machakos_town", "magarini", "makadara", "makueni", "malava", "malindi", "mandera_east", "mandera_north", "mandera_south", "mandera_west", "manyatta", "maragwa", "marakwet_east", "marakwet_west", "masinga", "matayos", "mathare", "mathioya", "mathira", "matuga", "matungu", "matungulu", "mavoko", "mbeere_north", "mbeere_south", "mbita", "mbooni", "mogotio", "moiben", "molo", "mosop", "moyale", "msambweni", "mt_elgon", "muhoroni", "mukurweini", "mumias_east", "mumias_west", "mvita", "mwala", "mwatate", "mwea", "mwingi_central", "mwingi_north", "mwingi_west", "naivasha", "nakuru_town_east", "nakuru_town_west", "nambale", "nandi_hills", "narok_east", "narok_north", "narok_south", "narok_west", "navakholo", "ndaragwa", "ndhiwa", "ndia", "njoro", "north_horr", "north_imenti", "north_mugirango", "nyakach", "nyali", "nyando", "nyaribari_chache", "nyaribari_masaba", "nyatike", "nyeri_town", "ol_jorok", "ol_kalou", "othaya", "pokot_south", "rabai", "rangwe", "rarieda", "rongai", "rongo", "roysambu", "ruaraka", "ruiru", "runyenjes", "sabatia", "saboti", "saku", "samburu_east", "samburu_north", "samburu_west", "seme", "shinyalu", "sigor", "sigowet_soin", "sirisia", "sotik", "south_imenti", "south_mugirango", "soy", "starehe", "suba", "subukia", "suna_east", "suna_west", "tarbaj", "taveta ", "teso_north", "teso_south", "tetu", "tharaka", "thika_town", "tiaty", "tigania_east", "tigania_west", "tinderet", "tongaren", "turbo", "turkana_central", "turkana_east", "turkana_north", "turkana_south", "turkana_west", "ugenya", "ugunja", "uriri", "vihiga", "voi", "wajir-south", "wajir_east", "wajir_north", "wajir_west", "webuye_east", "webuye_west", "west_mugirango", "westlands", "wundanyi", "yatta",
    "baringo", "bomet", "bungoma", "busia", "elgeyo_marakwet", "embu", "garissa", "homa_bay", "isiolo", "kajiado", "kakamega", "kericho", "kiambu", "kilifi", "kirinyaga", "kisii", "kisumu", "kitui", "kwale", "laikipia", "lamu", "machakos", "makueni", "mandera", "marsabit", "meru", "migori", "mombasa", "muranga", "nairobi", "nakuru", "nandi", "narok", "nyamira", "nyandarua", "nyeri", "samburu", "siaya", "taita_taveta", "tana_river", "tharaka_nithi", "trans_nzoia", "turkana", "uasin_gishu", "vihiga", "wajir", "west_pokot",
    "female", "male"
  ];
  if (TAG_LIST.contains(tag.text))
    return true;

  return false;
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
  command(UIAction.showSnackbar, new SnackbarData(errMsg, SnackbarNotificationType.error));
}
