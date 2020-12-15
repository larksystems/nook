library controller;

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:firebase/firebase.dart' show FirebaseError;

import 'logger.dart';
import 'model.dart' as model;
import 'platform.dart' as platform;
import 'pubsub.dart' show PubSubException;
import 'view.dart' as view;

part 'controller_filter_helper.dart';
part 'controller_platform_helper.dart';
part 'controller_view_helper.dart';

Logger log = new Logger('controller.dart');

enum UIActionObject {
  conversation,
  message,
  loadingConversations,
}

enum UIAction {
  updateTranslation,
  updateNote,
  sendMessage,
  sendMessageGroup,
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
  updateDisplayedTagsGroup,
  hideAgeTags,
  showSnackbar,
  updateConversationIdFilter,
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

class GroupReplyData extends Data {
  String replyGroupId;
  bool replyWithTranslation;
  GroupReplyData(this.replyGroupId, {this.replyWithTranslation: false});

  @override
  String toString() => 'GroupReplyData: {replyGroupId: $replyGroupId, replyWithTranslation: $replyWithTranslation}';
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
  TagFilterType filterType;
  FilterTagData(this.tagId, this.filterType);

  @override
  String toString() => 'FilterTagData: {tagId: $tagId, filterType: $filterType}';
}

class AfterDateFilterData extends Data {
  String tagId;
  DateTime afterDateFilter;
  TagFilterType filterType;
  AfterDateFilterData(this.tagId, this.filterType, [this.afterDateFilter]);

  @override
  String toString() => 'AfterDateFilter: {tagId: $tagId, filterType: $filterType, afterDateFilter: $afterDateFilter}';
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

class ConversationIdFilterData extends Data {
  String idFilter;
  ConversationIdFilterData(this.idFilter);

  @override
  String toString() => 'ConversationIdFilterData: {idFilter: $idFilter}';
}

class UserData extends Data {
  String displayName;
  String email;
  String photoUrl;
  UserData(this.displayName, this.email, this.photoUrl);

  @override
  String toString() => 'UserData: {displayName: $displayName, email: $email, photoUrl: $photoUrl}';
}

enum SignInDomain { avf, lark, ucam, gmail }
const signInDomainsInfo = {
  SignInDomain.avf: {"displayName": "Africa's Voices", "domain": "africasvoices.org"},
  SignInDomain.lark: {"displayName": "Lark Systems", "domain": "lark.systems"},
  SignInDomain.ucam: {"displayName": "University of Cambridge", "domain": "cam.ac.uk"},
  SignInDomain.gmail: {"displayName": "Gmail", "domain": "gmail.com"},
};

class SignInData extends Data {
  SignInDomain domain;
  SignInData(this.domain);

  @override
  String toString() => 'SignInData: {domain: $domain}';
}

class KeyPressData extends Data {
  String key;
  bool hasModifierKey;
  KeyPressData(this.key, this.hasModifierKey);

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
  String toString() => 'UpdateSuggestedRepliesCategoryData: {category: $category}';
}

class UpdateTagsGroupData extends Data {
  String group;
  UpdateTagsGroupData(this.group);

  @override
  String toString() => 'UpdateTagsGroupData: {group: $group}';
}

class UpdateFilterTagsCategoryData extends Data {
  String category;
  UpdateFilterTagsCategoryData(this.category);

  @override
  String toString() => 'UpdateFilterTagsCategoryData: {category: $category}';
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
  SnackbarData(this.text, this.type);

  @override
  String toString() => 'SnackbarData: {text: $text, type: $type}';
}

List<model.SystemMessage> systemMessages;

UIActionObject actionObjectState = UIActionObject.loadingConversations;

StreamSubscription conversationListSubscription;
Set<model.Conversation> conversations;
Set<model.Conversation> filteredConversations;
List<model.SuggestedReply> suggestedReplies;
Map<String, List<model.SuggestedReply>> suggestedRepliesByCategory;
String selectedSuggestedRepliesCategory;
List<model.Tag> conversationTags;
Map<String, List<model.Tag>> conversationTagsByGroup;
Map<String, model.Tag> conversationTagIdsToTags;
String selectedConversationTagsGroup;
List<model.Tag> messageTags;
Map<String, List<model.Tag>> messageTagsByGroup;
Map<String, model.Tag> messageTagIdsToTags;
String selectedMessageTagsGroup;
ConversationFilter conversationFilter;
Map<String, List<model.Tag>> filterTagsByCategory;
Map<String, List<model.Tag>> filterLastInboundTurnTagsByCategory;
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
  defaultUserConfig = baseUserConfiguration;
  currentUserConfig = currentConfig = emptyUserConfiguration;
  view.init();
  await platform.init();
}

void initUI() {
  systemMessages = [];
  conversations = emptyConversationsSet;
  filteredConversations = emptyConversationsSet;
  suggestedReplies = [];
  conversationTags = [];
  conversationTagIdsToTags = {};
  messageTags = [];
  messageTagIdsToTags = {};
  selectedConversations = [];
  activeConversation = null;
  selectedSuggestedRepliesCategory = '';
  selectedConversationTagsGroup = '';
  selectedMessageTagsGroup = '';
  hideDemogsTags = true;

  // Get any filter tags from the url
  conversationFilter = new ConversationFilter.fromUrl();
  _populateSelectedFilterTags(conversationFilter.filterTags[TagFilterType.include], TagFilterType.include);
  view.conversationIdFilter.filter = conversationFilter.conversationIdFilter;

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

      conversationTagIdsToTags = Map.fromEntries(conversationTags.map((t) => MapEntry(t.tagId, t)));

      // Update the filter tags by category map
      filterTagsByCategory = _groupTagsIntoCategories(conversationTags);

      _removeTagsFromFilterMenu(_groupTagsIntoCategories(removed), TagFilterType.include);
      _addTagsToFilterMenu(_groupTagsIntoCategories(added), TagFilterType.include);
      _modifyTagsInFilterMenu(_groupTagsIntoCategories(modified), TagFilterType.include);

      _removeTagsFromFilterMenu(_groupTagsIntoCategories(removed), TagFilterType.exclude);
      _addTagsToFilterMenu(_groupTagsIntoCategories(added), TagFilterType.exclude);
      _modifyTagsInFilterMenu(_groupTagsIntoCategories(modified), TagFilterType.exclude);

      // Update the conversation tags by group map
      conversationTagsByGroup = _groupTagsIntoCategories(conversationTags);
      // Empty sublist if there are no tags to show
      if (conversationTagsByGroup.isEmpty) {
        conversationTagsByGroup[''] = [];
      }
      List<String> groups = conversationTagsByGroup.keys.toList();
      groups.sort();
      // Replace list of groups in the UI selector
      view.tagPanelView.groups = groups;
      // If the groups have changed under us and the selected one no longer exists,
      // default to the first group, whichever it is
      if (!groups.contains(selectedConversationTagsGroup)) {
        selectedConversationTagsGroup = groups.first;
      }

      if (actionObjectState == UIActionObject.conversation || actionObjectState == UIActionObject.loadingConversations) {
        view.tagPanelView.selectedGroup = selectedConversationTagsGroup;
        _populateTagPanelView(conversationTagsByGroup[selectedConversationTagsGroup], TagReceiver.Conversation);
      }

      // Re-read the conversation filter from the URL since we now have the names of the tags
      conversationFilter = new ConversationFilter.fromUrl();
      _populateSelectedFilterTags(conversationFilter.filterTags[TagFilterType.include], TagFilterType.include);
      _populateSelectedAfterDateFilterTag(conversationFilter.afterDateFilter[TagFilterType.include], TagFilterType.include);

      if (currentConfig.conversationalTurnsEnabled) {
        _populateSelectedFilterTags(conversationFilter.filterTags[TagFilterType.exclude], TagFilterType.exclude);
        _populateSelectedAfterDateFilterTag(conversationFilter.afterDateFilter[TagFilterType.exclude], TagFilterType.exclude);
      }
    }, showAndLogError);

  _addDateTagToFilterMenu(TagFilterType.include);
  _addDateTagToFilterMenu(TagFilterType.exclude);

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

      messageTagIdsToTags = Map.fromEntries(messageTags.map((t) => MapEntry(t.tagId, t)));

      filterLastInboundTurnTagsByCategory = _groupTagsIntoCategories(messageTags);
      _removeTagsFromFilterMenu(_groupTagsIntoCategories(removed), TagFilterType.lastInboundTurn);
      _addTagsToFilterMenu(_groupTagsIntoCategories(added), TagFilterType.lastInboundTurn);
      _modifyTagsInFilterMenu(_groupTagsIntoCategories(modified), TagFilterType.lastInboundTurn);

      // Update the message tags by group map
      messageTagsByGroup = _groupTagsIntoCategories(messageTags);
      // Empty sublist if there are no tags to show
      if (messageTagsByGroup.isEmpty) {
        messageTagsByGroup[''] = [];
      }
      // Sort tags alphabetically
      for (var tags in messageTagsByGroup.values) {
        tags.sort((t1, t2) => t1.text.compareTo(t2.text));
      }
      List<String> groups = messageTagsByGroup.keys.toList();
      groups.sort((c1, c2) => c1.compareTo(c2));
      // Replace list of groups in the UI selector
      view.tagPanelView.groups = groups;
      // If the groups have changed under us and the selected one no longer exists,
      // default to the first group, whichever it is
      if (!groups.contains(selectedMessageTagsGroup)) {
        selectedMessageTagsGroup = groups.first;
      }

      if (actionObjectState == UIActionObject.message) {
        view.tagPanelView.selectedGroup = selectedMessageTagsGroup;
        _populateTagPanelView(messageTagsByGroup[selectedMessageTagsGroup], TagReceiver.Message);
      }

      // Re-read the conversation filter from the URL since we now have the names of the tags
      conversationFilter = new ConversationFilter.fromUrl();
      if (currentConfig.conversationalTurnsEnabled) {
        _populateSelectedFilterTags(conversationFilter.filterTags[TagFilterType.lastInboundTurn], TagFilterType.lastInboundTurn);
      }
    }, showAndLogError);

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
      }, showAndLogError);
  }

  platform.listenForConversationListShards(
    (added, modified, removed) {
      // TODO: handle removed shards as well
      List<model.ConversationListShard> shards = new List()
        ..addAll(added)
        ..addAll(modified);
      view.conversationListSelectView.updateConversationLists(shards);

      // Read any conversation shards from the URL
      String urlConversationListRoot = view.urlView.getPageUrlConversationList();
      String conversationListRoot = urlConversationListRoot;
      if (urlConversationListRoot == null) {
        conversationListRoot = ConversationListData.NONE;
        if (shards.length == 1) { // we have just one shard - select it and load the data
          conversationListRoot = shards.first.conversationListRoot;
        }
      } else if (shards.where((shard) => shard.conversationListRoot == urlConversationListRoot).isEmpty) {
        log.warning("Attempting to select shard ${conversationListRoot} that doesn't exist");
        conversationListRoot = ConversationListData.NONE;
      }
      // If we try to access a list that hasn't loaded yet, keep it in the URL
      // so it can be picked up on the next data snapshot from firebase.
      view.urlView.setPageUrlConversationList(urlConversationListRoot);
      view.conversationListSelectView.selectShard(conversationListRoot);
      command(UIAction.selectConversationList, ConversationListData(conversationListRoot));
    }, (error, stacktrace) {
      view.conversationListPanelView.hideLoadSpinner();
      showAndLogError(error, stacktrace);
    });

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
    }, showAndLogError);

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
    }, showAndLogError);
  // Apply the default configuration before loading any new configs.
  applyConfiguration(defaultUserConfig);
}


/// Sets user customization flags from the data map
/// If a flag is not set in the data map, it defaults to the existing values
void applyConfiguration(model.UserConfiguration newConfig) {
  var oldConfig = currentConfig;
  currentConfig = newConfig;
  if (oldConfig.repliesKeyboardShortcutsEnabled != newConfig.repliesKeyboardShortcutsEnabled) {
    view.replyPanelView.showShortcuts(newConfig.repliesKeyboardShortcutsEnabled);
  }

  if (oldConfig.tagsKeyboardShortcutsEnabled != newConfig.tagsKeyboardShortcutsEnabled) {
    view.tagPanelView.showShortcuts(newConfig.tagsKeyboardShortcutsEnabled);
  }

  if (oldConfig.sendMessagesEnabled != newConfig.sendMessagesEnabled) {
    view.replyPanelView.showButtons(newConfig.sendMessagesEnabled);
  }

  if (oldConfig.sendCustomMessagesEnabled != newConfig.sendCustomMessagesEnabled) {
    view.conversationPanelView.showCustomMessageBox(newConfig.sendCustomMessagesEnabled);
  }

  if (oldConfig.sendMultiMessageEnabled != newConfig.sendMultiMessageEnabled) {
    view.conversationListPanelView.showCheckboxes(newConfig.sendMultiMessageEnabled);
    // Start off with no selected conversations
    command(UIAction.deselectAllConversations, null);
  }

  if (oldConfig.tagMessagesEnabled != newConfig.tagMessagesEnabled) {
    if (actionObjectState == UIActionObject.message) {
      view.tagPanelView.showButtons(newConfig.tagMessagesEnabled);
    }
  }

  if (oldConfig.tagConversationsEnabled != newConfig.tagConversationsEnabled) {
    if (actionObjectState == UIActionObject.conversation) {
      view.tagPanelView.showButtons(newConfig.tagConversationsEnabled);
    }
  }

  if (oldConfig.editTranslationsEnabled != newConfig.editTranslationsEnabled) {
    view.conversationPanelView.enableEditableTranslations(newConfig.editTranslationsEnabled);
  }

  if (oldConfig.editNotesEnabled != newConfig.editNotesEnabled) {
    view.replyPanelView.enableEditableNotes(newConfig.editNotesEnabled);
  }

  if (oldConfig.conversationalTurnsEnabled != newConfig.conversationalTurnsEnabled) {
    view.conversationFilter[TagFilterType.lastInboundTurn].showFilter(newConfig.conversationalTurnsEnabled);
    if (oldConfig.conversationalTurnsEnabled != null && !newConfig.conversationalTurnsEnabled) {
      // only clear things up after we've received the config from the server
      conversationFilter.filterTags[TagFilterType.lastInboundTurn].clear();
      view.urlView.setPageUrlFilterTags(TagFilterType.lastInboundTurn, conversationFilter.filterTagIds[TagFilterType.lastInboundTurn]);
    } else {
      _populateSelectedFilterTags(conversationFilter.filterTags[TagFilterType.lastInboundTurn], TagFilterType.lastInboundTurn);
    }

    // exclude filtering is temporary sharing the flag with last inbound turns
    view.conversationFilter[TagFilterType.exclude].showFilter(newConfig.conversationalTurnsEnabled);
    if (oldConfig.conversationalTurnsEnabled != null && !newConfig.conversationalTurnsEnabled) {
      // only clear things up after we've received the config from the server
      conversationFilter.filterTags[TagFilterType.exclude].clear();
      view.urlView.setPageUrlFilterTags(TagFilterType.exclude, conversationFilter.filterTagIds[TagFilterType.exclude]);
    } else {
      _populateSelectedFilterTags(conversationFilter.filterTags[TagFilterType.exclude], TagFilterType.exclude);
      _populateSelectedAfterDateFilterTag(conversationFilter.afterDateFilter[TagFilterType.exclude], TagFilterType.exclude);
    }
  }

  if (oldConfig.tagsPanelVisibility != newConfig.tagsPanelVisibility ||
      oldConfig.repliesPanelVisibility != newConfig.repliesPanelVisibility) {
    view.showPanels(newConfig.repliesPanelVisibility, newConfig.tagsPanelVisibility);
  }

  if (oldConfig.suggestedRepliesGroupsEnabled != newConfig.suggestedRepliesGroupsEnabled) {
    if (suggestedRepliesByCategory != null) {
      _populateReplyPanelView(suggestedRepliesByCategory[selectedSuggestedRepliesCategory]);
    }
  }

  log.verbose('Updated user configuration: $currentConfig');
}

void conversationListSelected(String conversationListRoot) {
  command(UIAction.deselectAllConversations, null);
  conversationListSubscription?.cancel();
  if (conversationListSubscription != null) {
    // Only clear up the conversation id after the initial page loading
    view.urlView.setPageUrlConversationId(null);
  }
  conversationListSubscription = null;
  if (conversationListRoot == ConversationListData.NONE) {
    view.urlView.setPageUrlConversationList(null);
    view.conversationListPanelView.totalConversations = 0;
    return;
  }
  view.urlView.setPageUrlConversationList(conversationListRoot);
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

      view.conversationListPanelView.totalConversations = conversations.length;

      updateMissingTagIds(conversations, conversationTags, [TagFilterType.include, TagFilterType.exclude]);
      updateMissingTagIds(conversations, messageTags, [TagFilterType.lastInboundTurn]);

      if (actionObjectState == UIActionObject.loadingConversations) {
        actionObjectState = UIActionObject.conversation;
        view.tagPanelView.selectedGroup = selectedConversationTagsGroup;
        _populateTagPanelView(conversationTagsByGroup[selectedConversationTagsGroup], TagReceiver.Conversation);
      }

      // TODO even though they are unlikely to happen, we should also handle the removals in the UI for consistency

      // Determine if we need to display the conversation from the url
      String urlConversationId = view.urlView.getPageUrlConversationId();
      if (activeConversation == null && urlConversationId != null) {
        var matches = conversations.where((c) => c.docId == urlConversationId).toList();
        if (matches.length == 0) {
          activeConversation = new model.Conversation()
            ..docId = urlConversationId
            ..demographicsInfo = {"": "conversation not found"}
            ..tagIds = Set()
            ..lastInboundTurnTagIds = Set()
            ..notes = ""
            ..messages = []
            ..unread = false;
        } else {
          activeConversation = matches.first;
        }
        updateViewForConversation(activeConversation, updateInPlace: true);
      }

      // Determine if the active conversation data needs to be replaced
      String activeConversationId = activeConversation?.docId;
      if (updatedIds.contains(activeConversationId)) {
        activeConversation = conversations.firstWhere((c) => c.docId == activeConversationId);
      }

      updateFilteredAndSelectedConversationLists();

      if (activeConversation == null) return;

      // Update the active conversation view as needed
      if (updatedIds.contains(activeConversation.docId)) {
        updateViewForConversation(activeConversation, updateInPlace: true);
        if (!activeConversation.unread) {
          command(UIAction.markConversationRead, ConversationData(activeConversation.docId));
        }
      }
    },
    conversationListRoot,
    showAndLogError);
}

SplayTreeSet<model.Conversation> get emptyConversationsSet =>
    SplayTreeSet(model.ConversationUtil.compareConversationId);

model.UserConfiguration get baseUserConfiguration => new model.UserConfiguration()
    ..repliesKeyboardShortcutsEnabled = false
    ..tagsKeyboardShortcutsEnabled = false
    ..sendMessagesEnabled = false
    ..sendCustomMessagesEnabled = false
    ..sendMultiMessageEnabled = false
    ..tagMessagesEnabled = false
    ..tagConversationsEnabled = false
    ..editTranslationsEnabled = false
    ..editNotesEnabled = false
    ..conversationalTurnsEnabled = false
    ..tagsPanelVisibility = false
    ..repliesPanelVisibility = false
    ..suggestedRepliesGroupsEnabled = false;

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

Set<model.Conversation> get conversationsInView {
  if (currentConfig.sendMultiMessageEnabled) {
    return conversations.where((c) => filteredConversations.contains(c) || selectedConversations.contains(c)).toSet();
  }
  return filteredConversations;
}

DateTime lastUserActivity = new DateTime.now();

void command(UIAction action, Data data) {
  log.verbose('Executing UI command: $actionObjectState - $action - $data');
  log.verbose('Active conversation: ${activeConversation?.docId}');
  log.verbose('Selected conversations: ${selectedConversations?.map((c) => c.docId)?.toList()}');
  log.verbose('Filtered conversations: ${filteredConversations?.map((c) => c.docId)?.toList()}');

  // For most actions, a conversation needs to be active.
  // Early exist if it's not one of the actions valid without an active conversation.
  if (activeConversation == null &&
      action != UIAction.selectConversationList &&
      action != UIAction.addFilterTag && action != UIAction.removeFilterTag &&
      action != UIAction.promptAfterDateFilter && action != UIAction.updateAfterDateFilter &&
      action != UIAction.signInButtonClicked && action != UIAction.signOutButtonClicked &&
      action != UIAction.userSignedIn && action != UIAction.userSignedOut &&
      action != UIAction.updateSuggestedRepliesCategory &&
      action != UIAction.updateDisplayedTagsGroup && action != UIAction.hideAgeTags &&
      action != UIAction.selectAllConversations && action != UIAction.deselectAllConversations &&
      action != UIAction.showSnackbar && action != UIAction.updateConversationIdFilter) {
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
          ..translation = selectedReply.text;
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
    case UIAction.sendMessageGroup:
      GroupReplyData replyData = data;
      List<model.SuggestedReply> selectedReplies = suggestedRepliesByCategory[selectedSuggestedRepliesCategory].where((reply) => reply.groupId == replyData.replyGroupId).toList();
      selectedReplies.sort((reply1, reply2) => reply1.indexInGroup.compareTo(reply2.indexInGroup));
      if (replyData.replyWithTranslation) {
        List<model.SuggestedReply> translationReplies = [];
        for (var reply in selectedReplies) {
          var translationReply = new model.SuggestedReply()
            ..text = reply.translation
            ..translation = reply.text;
          translationReplies.add(translationReply);
        }
        selectedReplies = translationReplies;
      }
      if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
        sendReplyGroup(selectedReplies, activeConversation);
        return;
      }
      if (!view.sendingMultiMessageGroupUserConfirmation(selectedReplies.length, selectedConversations.length)) {
        log.verbose('User cancelled sending multi message group reply: "${selectedReplies.map((r) => r.text).join("; ")}"');
        return;
      }
      sendMultiReplyGroup(selectedReplies, selectedConversations);
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
            break;
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
        case UIActionObject.loadingConversations:
          break;
      }
      updateFilteredAndSelectedConversationLists();
      break;
    case UIAction.addFilterTag:
      FilterTagData tagData = data;
      var allTagsCollection = tagData.filterType == TagFilterType.lastInboundTurn ? messageTagIdsToTags : conversationTagIdsToTags;
      model.Tag tag = tagIdToTag(tagData.tagId, allTagsCollection);
      model.Tag unifierTag = unifierTagForTag(tag, allTagsCollection);
      var added = conversationFilter.filterTags[tagData.filterType].add(unifierTag);
      if (!added) return; // Trying to add an existing tag, nothing to do here
      view.urlView.setPageUrlFilterTags(tagData.filterType, conversationFilter.filterTagIds[tagData.filterType]);
      view.conversationFilter[tagData.filterType].addFilterTag(new view.FilterTagView(unifierTag.text, unifierTag.tagId, tagTypeToStyle(unifierTag.type), tagData.filterType));
      if (actionObjectState == UIActionObject.loadingConversations) return;
      updateFilteredAndSelectedConversationLists();
      break;
    case UIAction.removeConversationTag:
      ConversationTagData conversationTagData = data;
      model.Tag tag = conversationTags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
      platform.removeConversationTag(activeConversation, tag.tagId).catchError(showAndLogError);
      view.conversationPanelView.removeTag(tag.tagId);
      updateFilteredAndSelectedConversationLists();
      break;
    case UIAction.removeMessageTag:
      MessageTagData messageTagData = data;
      var message = activeConversation.messages[messageTagData.messageIndex];
      platform.removeMessageTag(activeConversation, message, messageTagData.tagId).then(
        (_) {
          view.conversationPanelView
            .messageViewAtIndex(messageTagData.messageIndex)
            .removeTag(messageTagData.tagId);
        }, onError: showAndLogError);
      break;
    case UIAction.removeFilterTag:
      FilterTagData tagData = data;
      var allTagsCollection = tagData.filterType == TagFilterType.lastInboundTurn ? messageTagIdsToTags : conversationTagIdsToTags;
      model.Tag tag = tagIdToTag(tagData.tagId, allTagsCollection);
      conversationFilter.filterTags[tagData.filterType].removeWhere((t) => t.tagId == tag.tagId);
      view.urlView.setPageUrlFilterTags(tagData.filterType, conversationFilter.filterTagIds[tagData.filterType]);
      view.conversationFilter[tagData.filterType].removeFilterTag(tag.tagId);
      if (actionObjectState == UIActionObject.loadingConversations) return;
      updateFilteredAndSelectedConversationLists();
      break;
    case UIAction.promptAfterDateFilter:
      AfterDateFilterData filterData = data;
      view.conversationPanelView.showAfterDateFilterPrompt(filterData.filterType, conversationFilter.afterDateFilter[filterData.filterType]);
      break;
    case UIAction.updateAfterDateFilter:
      AfterDateFilterData filterData = data;
      conversationFilter.afterDateFilter[filterData.filterType] = filterData.afterDateFilter;
      view.conversationFilter[filterData.filterType].removeFilterTag(filterData.tagId);
      if (filterData.afterDateFilter != null) {
        view.conversationFilter[filterData.filterType].addFilterTag(new view.AfterDateFilterTagView(filterData.afterDateFilter, filterData.filterType));
      }
      view.urlView.setPageUrlFilterAfterDate(filterData.filterType, filterData.afterDateFilter);
      if (actionObjectState == UIActionObject.loadingConversations) return;
      updateFilteredAndSelectedConversationLists();
      break;
    case UIAction.updateConversationIdFilter:
      ConversationIdFilterData filterData = data;
      conversationFilter.conversationIdFilter = filterData.idFilter;
      view.urlView.setPageUrlFilterConversationId(filterData.idFilter.isEmpty ? null : filterData.idFilter);
      if (actionObjectState == UIActionObject.loadingConversations) return;
      updateFilteredAndSelectedConversationLists();
      break;
    case UIAction.selectMessage:
      MessageData messageData = data;
      selectedMessage = activeConversation.messages[messageData.messageIndex];
      view.conversationPanelView.selectMessage(messageData.messageIndex);
      view.tagPanelView.selectedGroup = selectedMessageTagsGroup;
      _populateTagPanelView(messageTagsByGroup[selectedMessageTagsGroup], TagReceiver.Message);
      switch (actionObjectState) {
        case UIActionObject.conversation:
          actionObjectState = UIActionObject.message;
          break;
        case UIActionObject.message:
          break;
        case UIActionObject.loadingConversations:
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
          view.tagPanelView.selectedGroup = selectedConversationTagsGroup;
          _populateTagPanelView(conversationTagsByGroup[selectedConversationTagsGroup], TagReceiver.Conversation);
          actionObjectState = UIActionObject.conversation;
          break;
        case UIActionObject.loadingConversations:
          break;
      }
      break;
    case UIAction.markConversationRead:
      ConversationData conversationData = data;
      model.Conversation conversation = conversations.singleWhere((c) => c.docId == conversationData.deidentifiedPhoneNumber);
      view.conversationListPanelView.markConversationRead(conversation.docId);
      platform.updateUnread([conversation], false).catchError(showAndLogError);
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
      if (conversationData.deidentifiedPhoneNumber == activeConversation.docId) break;
      bool shouldRecomputeConversationList = !filteredConversations.contains(activeConversation);
      activeConversation = conversations.singleWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
      if (shouldRecomputeConversationList) updateFilteredAndSelectedConversationLists();
      updateViewForConversation(activeConversation);
      break;
    case UIAction.selectConversationList:
      ConversationListData conversationListData = data;
      conversations = emptyConversationsSet;
      filteredConversations = emptyConversationsSet;
      selectedConversations.clear();
      activeConversation = null;
      actionObjectState = UIActionObject.loadingConversations;
      view.conversationListPanelView.clearConversationList();
      view.conversationPanelView.clear();
      view.replyPanelView.noteText = '';
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
      model.Conversation conversation = conversations.singleWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
      selectedConversations.add(conversation);
      break;
    case UIAction.deselectConversation:
      ConversationData conversationData = data;
      model.Conversation conversation = conversations.singleWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
      selectedConversations.remove(conversation);
      updateFilteredAndSelectedConversationLists();
      break;
    case UIAction.updateTranslation:
      if (data is TranslationData) {
        TranslationData messageTranslation = data;
        var conversation = activeConversation;
        var message = conversation.messages[messageTranslation.messageIndex];
        SaveTextAction.textChange(
          "${conversation.docId}.message-${messageTranslation.messageIndex}.translation",
          messageTranslation.translationText,
          (newText) {
            return platform.setMessageTranslation(conversation, message, newText).catchError(showAndLogError);
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
      SignInData signInData = data;
      platform.signIn(signInDomainsInfo[signInData.domain]['domain']);
      break;
    case UIAction.signOutButtonClicked:
      platform.signOut();
      break;
    case UIAction.keyPressed:
      KeyPressData keyPressData = data;
      if (keyPressData.key == 'Enter') {
        // Select the next conversation in the list
        bool shouldRecomputeConversationList = !filteredConversations.contains(activeConversation);
        activeConversation = nextElement(conversationsInView, activeConversation);
        if (shouldRecomputeConversationList) updateFilteredAndSelectedConversationLists();
        updateViewForConversation(activeConversation);
        return;
      }
      if (keyPressData.key == 'Esc' || keyPressData.key == 'Escape') {
        // Hide the snackbar if it's visible
        view.snackbarView.hideSnackbar();
      }
      // If the keypress it has a modifier key, prevent all replies and tags
      if (keyPressData.hasModifierKey) return;
      // If the configuration allows it, try to match the key with a reply shortcut
      if (currentConfig.sendMessagesEnabled &&
          currentConfig.repliesPanelVisibility &&
          currentConfig.repliesKeyboardShortcutsEnabled) {
        // If the shortcut is for a reply, find it and send it
        var selectedReply = suggestedRepliesByCategory[selectedSuggestedRepliesCategory].where((reply) => reply.shortcut == keyPressData.key);
        if (selectedReply.isNotEmpty) {
          assert (selectedReply.length == 1);
          if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
            sendReply(selectedReply.first, activeConversation);
            return;
          }
          String text = 'Cannot send multiple messages using keyboard shortcuts. '
                        'Please use the send button on the suggested reply you want to send instead.';
          command(UIAction.showSnackbar, new SnackbarData(text, SnackbarNotificationType.warning));
          return;
        }
      }

      // If the configuration allows it, try to match the key with a conversation or message shortcut
      if (!(currentConfig.tagMessagesEnabled || currentConfig.tagConversationsEnabled) &&
          !currentConfig.tagsKeyboardShortcutsEnabled &&
          !currentConfig.tagsPanelVisibility) return;
      switch (actionObjectState) {
        case UIActionObject.conversation:
          // Early exit if tagging conversations is disabled
          if (!currentConfig.tagConversationsEnabled) return;
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
          // Early exit if tagging messages is disabled
          if (!currentConfig.tagConversationsEnabled) return;
          var selectedTag = _filterDemogsTagsIfNeeded(messageTags).where((tag) => tag.shortcut == keyPressData.key);
          if (selectedTag.isEmpty) break;
          assert (selectedTag.length == 1);
          setMessageTag(selectedTag.first, selectedMessage, activeConversation);
          return;
        case UIActionObject.loadingConversations:
          break;
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
      updateFilteredAndSelectedConversationLists();
      break;
    case UIAction.deselectAllConversations:
      view.conversationListPanelView.uncheckSelectAllCheckbox();
      view.conversationListPanelView.uncheckAllConversations();
      selectedConversations.clear();
      if (actionObjectState != UIActionObject.loadingConversations) {
        updateFilteredAndSelectedConversationLists();
      }
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
    case UIAction.updateDisplayedTagsGroup:
      UpdateTagsGroupData updateGroupData = data;
      switch (actionObjectState) {
        case UIActionObject.conversation:
          selectedConversationTagsGroup = updateGroupData.group;
          _populateTagPanelView(conversationTagsByGroup[selectedConversationTagsGroup], TagReceiver.Conversation);
          break;
        case UIActionObject.message:
          selectedMessageTagsGroup = updateGroupData.group;
          _populateTagPanelView(messageTagsByGroup[selectedMessageTagsGroup], TagReceiver.Message);
          break;
        case UIActionObject.loadingConversations:
          selectedConversationTagsGroup = updateGroupData.group;
          _populateTagPanelView(conversationTagsByGroup[selectedConversationTagsGroup], TagReceiver.Conversation);
          break;
      }
      break;
    case UIAction.hideAgeTags:
      ToggleData toggleData = data;
      hideDemogsTags = toggleData.toggleValue;
      switch (actionObjectState) {
        case UIActionObject.conversation:
          view.tagPanelView.selectedGroup = selectedConversationTagsGroup;
          _populateTagPanelView(conversationTagsByGroup[selectedConversationTagsGroup], TagReceiver.Conversation);
          break;
        case UIActionObject.message:
          view.tagPanelView.selectedGroup = selectedMessageTagsGroup;
          _populateTagPanelView(messageTagsByGroup[selectedMessageTagsGroup], TagReceiver.Message);
          break;
        case UIActionObject.loadingConversations:
          break;
      }
      break;

    case UIAction.showSnackbar:
      SnackbarData snackbarData = data;
      view.snackbarView.showSnackbar(snackbarData.text, snackbarData.type);
      break;
  }
}

void updateFilteredAndSelectedConversationLists() {
  filteredConversations = conversations.where((conversation) => conversationFilter.test(conversation)).toSet();
  if (!currentConfig.sendMultiMessageEnabled) {
    activeConversation = updateViewForConversations(conversationsInView, updateList: true);
    return;
  }
  // Update the conversation objects in [selectedConversations] in case any of them were replaced
  Set selectedConversationsIds = selectedConversations.map((c) => c.docId).toSet();
  selectedConversations = conversations.where((c) => selectedConversationsIds.contains(c.docId)).toList();

  // Show both filtered and selected conversations in the list,
  // but mark the selected conversations that don't meet the filter with a warning
  activeConversation = updateViewForConversations(conversationsInView, updateList: true);
  view.conversationListPanelView.showCheckboxes(currentConfig.sendMultiMessageEnabled);
  conversationsInView.forEach((conversation) {
    if (selectedConversations.contains(conversation)) {
      view.conversationListPanelView.checkConversation(conversation.docId);
    }
    if (filteredConversations.contains(conversation)) {
      view.conversationListPanelView.clearWarning(conversation.docId);
    } else {
      view.conversationListPanelView.showWarning(conversation.docId);
    }
  });
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
    _selectConversationInView(conversationToSelect);
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
  _selectConversationInView(activeConversation);
  view.conversationPanelView.clearWarning();
  return activeConversation;
}

void updateViewForConversation(model.Conversation conversation, {bool updateInPlace: false}) {
  if (conversation == null) return;
  // Replace the previous conversation in the conversation panel
  _populateConversationPanelView(conversation, updateInPlace: updateInPlace);
  view.replyPanelView.noteText = conversation.notes;
  // Deselect message if selected
  switch (actionObjectState) {
    case UIActionObject.conversation:
      break;
    case UIActionObject.message:
      selectedMessage = null;
      view.conversationPanelView.deselectMessage();
      view.tagPanelView.selectedGroup = selectedConversationTagsGroup;
      _populateTagPanelView(conversationTagsByGroup[selectedConversationTagsGroup], TagReceiver.Conversation);
      break;
    case UIActionObject.loadingConversations:
      break;
  }
  _selectConversationInView(conversation);
  if (!filteredConversations.contains(conversation)) {
    // If it doesn't meet the filter, show warning
    view.conversationPanelView.showWarning('Conversation no longer meets filtering constraints');
  }
}

void _selectConversationInView(model.Conversation conversation) {
  view.urlView.setPageUrlConversationId(conversation.docId);
  if (conversationsInView.contains(conversation)) {
    // Select the conversation in the list of conversations
    view.conversationListPanelView.selectConversation(conversation.docId);
  }
}

void sendReply(model.SuggestedReply reply, model.Conversation conversation) {
  log.verbose('Preparing to send reply "${reply.text}" to conversation ${conversation.docId}');
  model.Message newMessage = new model.Message()
    ..text = reply.text
    ..datetime = new DateTime.now()
    ..direction = model.MessageDirection.Out
    ..translation = reply.translation
    ..tagIds = []
    ..status = model.MessageStatus.pending;
  log.verbose('Adding reply "${reply.text}" to conversation ${conversation.docId}');
  conversation.messages.add(newMessage);
  view.conversationPanelView.addMessage(_generateMessageView(newMessage, conversation));
  log.verbose('Sending reply "${reply.text}" to conversation ${conversation.docId}');
  platform.sendMessage(conversation.docId, reply.text, onError: (error) {
    log.error('Reply "${reply.text}" failed to be sent to conversation ${conversation.docId}');
    log.error('Error: ${error}');
    command(UIAction.showSnackbar, new SnackbarData('Send Reply Failed', SnackbarNotificationType.error));
    newMessage.status = model.MessageStatus.failed;
    if (conversation.docId == activeConversation.docId) {
      int newMessageIndex = activeConversation.messages.indexOf(newMessage);
      view.conversationPanelView.messageViewAtIndex(newMessageIndex).setStatus(newMessage.status);
    }
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
    ..tagIds = []
    ..status = model.MessageStatus.pending;
  log.verbose('Adding reply "${reply.text}" to conversations ${conversationIds}');
  conversations.forEach((conversation) => conversation.messages.add(newMessage));
  if (conversations.contains(activeConversation)) {
    view.conversationPanelView.addMessage(_generateMessageView(newMessage, activeConversation));
  }
  log.verbose('Sending reply "${reply.text}" to conversations ${conversationIds}');
  platform.sendMultiMessage(conversationIds, newMessage.text, onError: (error) {
    log.error('Reply "${reply.text}" failed to be sent to conversations ${conversationIds}');
    log.error('Error: ${error}');
    command(UIAction.showSnackbar, new SnackbarData('Send Multi Reply Failed', SnackbarNotificationType.error));
    newMessage.status = model.MessageStatus.failed;
    if (conversationIds.contains(activeConversation.docId)) {
      int newMessageIndex = activeConversation.messages.indexOf(newMessage);
      view.conversationPanelView.messageViewAtIndex(newMessageIndex).setStatus(newMessage.status);
    }
  });
  log.verbose('Reply "${reply.text}" queued for sending to conversations ${conversationIds}');
}

void sendReplyGroup(List<model.SuggestedReply> replies, model.Conversation conversation) {
  List<String> textReplies = replies.map((r) => r.text).toList();
  String repliesStr = textReplies.join("; ");
  log.verbose('Preparing to send ${textReplies.length} replies "${repliesStr}" to conversation ${conversation.docId}');
  List<model.Message> newMessages = [];
  for (var reply in replies) {
    model.Message newMessage = new model.Message()
      ..text = reply.text
      ..datetime = new DateTime.now()
      ..direction = model.MessageDirection.Out
      ..translation = reply.translation
      ..tagIds = []
      ..status = model.MessageStatus.pending;
    newMessages.add(newMessage);
  }
  log.verbose('Adding ${textReplies.length} replies "${repliesStr}" to conversation ${conversation.docId}');
  conversation.messages.addAll(newMessages);
  for (var message in newMessages) {
    view.conversationPanelView.addMessage(_generateMessageView(message, conversation));
  }

  log.verbose('Sending ${textReplies.length} replies "${repliesStr}" to conversation ${conversation.docId}');
  platform.sendMessages(conversation.docId, textReplies, onError: (error) {
    log.error('${textReplies.length} replies "${repliesStr}" failed to be sent to conversation ${conversation.docId}');
    log.error('Error: ${error}');
    command(UIAction.showSnackbar, new SnackbarData('Send Reply Failed', SnackbarNotificationType.error));
    for (var message in newMessages) {
      message.status = model.MessageStatus.failed;
      if (conversation.docId == activeConversation.docId) {
        int messageIndex = activeConversation.messages.indexOf(message);
        view.conversationPanelView.messageViewAtIndex(messageIndex).setStatus(message.status);
      }
    }
  });
  log.verbose('${textReplies.length} replies "${repliesStr}" queued for sending to conversation ${conversation.docId}');
}

void sendMultiReplyGroup(List<model.SuggestedReply> replies, List<model.Conversation> conversations) {
  List<String> conversationIds = conversations.map((conversation) => conversation.docId).toList();
  List<String> textReplies = replies.map((r) => r.text).toList();
  String repliesStr = textReplies.join("; ");
  log.verbose('Preparing to send ${textReplies.length} replies "${repliesStr}" to conversations $conversationIds');
  var newMessages = <model.Message>[];
  for (var reply in replies) {
    model.Message newMessage = new model.Message()
      ..text = reply.text
      ..datetime = new DateTime.now()
      ..direction = model.MessageDirection.Out
      ..translation = reply.translation
      ..tagIds = []
      ..status = model.MessageStatus.pending;
    newMessages.add(newMessage);
  }
  log.verbose('Adding ${textReplies.length} replies "${repliesStr}" to conversation ${conversationIds}');
  conversations.forEach((conversation) => conversation.messages.addAll(newMessages));
  if (conversations.contains(activeConversation)) {
    for (var message in newMessages) {
      view.conversationPanelView.addMessage(_generateMessageView(message, activeConversation));
    }
  }
  log.verbose('Sending ${textReplies.length} replies "${repliesStr}" to conversation ${conversationIds}');
  platform.sendMultiMessages(conversationIds, textReplies, onError: (error) {
    log.error('${textReplies.length} replies "${repliesStr}" failed to be sent to conversations ${conversationIds}');
    log.error('Error: ${error}');
    command(UIAction.showSnackbar, new SnackbarData('Send Multi Reply Failed', SnackbarNotificationType.error));
    for (var message in newMessages) {
      message.status = model.MessageStatus.failed;
      if (conversationIds.contains(activeConversation.docId)) {
        int messageIndex = activeConversation.messages.indexOf(message);
        view.conversationPanelView.messageViewAtIndex(messageIndex).setStatus(message.status);
      }
    }
  });
  log.verbose('${textReplies.length} replies "${repliesStr}" queued for sending to conversations ${conversationIds}');
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
    platform.addMessageTag(activeConversation, message, tag.tagId).then(
      (_) {
        view.conversationPanelView
          .messageViewAtIndex(conversation.messages.indexOf(message))
          .addTag(new view.MessageTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
      }, onError: showAndLogError);
  }
}

void updateMissingTagIds(Set<model.Conversation> conversations, List<model.Tag> tags, List<TagFilterType> filterTypes) {
  var newTagIdsWithMissingInfo = extractTagIdsWithMissingInfo(conversations, tags.toSet());
  var tagsWithMissingInfo = tags.where((tag) => tag.type == model.NotFoundTagType.NotFound).toSet();
  if (newTagIdsWithMissingInfo.isEmpty) {
    tags.removeWhere((tag) => tag.type == model.NotFoundTagType.NotFound);
  }
  var tagIdsWithMissingInfo = tagsWithMissingInfo.map((tag) => tag.docId).toSet();
  // remove tags that are no longer missing their info
  var tagIdsToRemove = tagIdsWithMissingInfo.difference(newTagIdsWithMissingInfo);
  if (tagIdsToRemove.isNotEmpty) {
    var tagsToRemove = tagIdsToTags(tagIdsToRemove, Map.fromEntries(tags.map((t) => MapEntry(t.tagId, t))));
    tags.removeWhere((tag) => tagsToRemove.contains(tag));
    var groupsToUpdate = <String>{};
    for (var tag in tagsToRemove) {
      if (tag.groups.isEmpty) {
        groupsToUpdate.add(tag.group);
        continue;
      }
      groupsToUpdate.addAll(tag.groups);
    }
    for (var group in groupsToUpdate) {
      var tagsToRemoveForGroup = tagsToRemove.where((t) => t.groups.contains(group) || t.group == group).toList();
      for (var filterType in filterTypes) {
        _removeTagsFromFilterMenu({group: tagsToRemoveForGroup}, filterType);
      }
    }
  }
  // add tags that are new
  var tagIdsToAdd = newTagIdsWithMissingInfo.difference(tagIdsWithMissingInfo);
  if (tagIdsToAdd.isEmpty) return;
  var tagsToAdd = tagIdsToTags(tagIdsToAdd, Map.fromEntries(tags.map((t) => MapEntry(t.tagId, t))));
  tags.addAll(tagsToAdd);
  var groupsToUpdate = <String>{};
  for (var tag in tagsToAdd) {
    if (tag.groups.isEmpty) {
      groupsToUpdate.add(tag.group);
      continue;
    }
    groupsToUpdate.addAll(tag.groups);
  }
  for (var group in groupsToUpdate) {
    var tagsToAddForGroup = tagsToAdd.where((t) => t.groups.contains(group) || t.group == group).toList();
    for (var filterType in filterTypes) {
      _addTagsToFilterMenu({group: tagsToAddForGroup}, filterType);
    }
  }
}

Set<String> extractTagIdsWithMissingInfo(Set<model.Conversation> conversations, Set<model.Tag> tags) {
  Set<String> tagIdsWithMissingInfo = {};
  Set<model.Tag> tagsWithoutMissingInfo = tags.where((tag) => tag.type != model.NotFoundTagType.NotFound).toSet();
  Set<String> tagIdsWithoutMissingInfo = tagsWithoutMissingInfo.map((e) => e.docId).toSet();
  for (var conversation in conversations) {
    tagIdsWithMissingInfo.addAll(conversation.tagIds.difference(tagIdsWithoutMissingInfo));
  }
  return tagIdsWithMissingInfo;
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
    _timer = new Timer(const Duration(milliseconds: 500), _updateField);
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

Map<String, model.Tag> _notFoundTagIds = {};

UnmodifiableListView<model.Tag> tagIdsToTags(Iterable<String> tagIds, Map<String, model.Tag> allTags) {
  var tags = <model.Tag>[];
  for (var id in tagIds) {
    tags.add(tagIdToTag(id, allTags));
  }
  return UnmodifiableListView(tags);
}

UnmodifiableListView<String> tagsToTagIds(Iterable<model.Tag> tags) =>
    UnmodifiableListView(tags.map((t) => t.tagId));

model.Tag tagIdToTag(String tagId, Map<String, model.Tag> tags) {
  if (tags.containsKey(tagId))
    return tags[tagId];

  _notFoundTagIds.putIfAbsent(tagId, () =>
    new model.Tag()
      ..docId = tagId
      ..text = tagId
      ..type = model.NotFoundTagType.NotFound
      ..filterable = true
      ..groups = ['not found']
      ..isUnifier = false);
  return _notFoundTagIds[tagId];
}

model.Tag unifierTagForTag(model.Tag tag, Map<String, model.Tag> allTags) {
  if (tag.isUnifier) return tag;
  if (tag.unifierTagId == null) return tag;
  return tagIdToTag(tag.unifierTagId, allTags);
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
  } else if (error is FirebaseError) {
    errMsg = "An firestore error occured: ${error.code} [${error.message}]";
    view.bannerView.showBanner("You don't have access to this dataset. Please contact your project administrator");
  } else if (error is Exception) {
    errMsg = "An internal error occurred: ${error.runtimeType}";
  }  else {
    errMsg = "$error";
  }
  command(UIAction.showSnackbar, new SnackbarData(errMsg, SnackbarNotificationType.error));
}
