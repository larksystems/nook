library controller;

import 'dart:async';
import 'dart:collection';
import 'package:intl/intl.dart';
import 'package:firebase/firebase.dart' show FirebaseError;

import 'package:katikati_ui_lib/components/url_view/url_view.dart';
import 'package:katikati_ui_lib/components/snackbar/snackbar.dart';
import 'package:katikati_ui_lib/components/tag/tag.dart';
import 'package:katikati_ui_lib/components/turnline/turnline.dart';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:nook/platform/platform.dart';
import 'package:nook/platform/pubsub.dart' show PubSubException;
import 'package:nook/platform/user_position_reporter.dart';

import 'view.dart';

part 'controller_filter_helper.dart';
part 'controller_view_helper.dart';

Logger log = new Logger('controller.dart');

enum UIActionObject {
  conversation,
  message,
  loadingConversations,
  addTagInline,
}

enum UIAction {
  updateTranslation,
  updateNote,
  sendMessage,
  sendMessageGroup,
  sendManualMessage,
  confirmSuggestedMessages,
  rejectSuggestedMessages,
  addTag,
  addFilterTag,
  removeConversationTag,
  removeMessageTag,
  confirmConversationTag,
  confirmMessageTag,
  rejectConversationTag,
  rejectMessageTag,
  removeFilterTag,
  showConversation,
  selectConversationList,
  selectConversation,
  deselectConversation,
  markConversationRead,
  markConversationUnread,
  changeConversationSortOrder,
  selectConversationSummary,
  deselectConversationSummary,
  selectMessage,
  deselectMessage,
  keyPressed,
  startAddNewTagInline,
  cancelAddNewTagInline,
  saveNewTagInline,
  selectAllConversations,
  deselectAllConversations,
  updateSuggestedRepliesCategory,
  updateDisplayedTagsGroup,
  showSnackbar,
  updateConversationIdFilter,
  goToUser,
}

enum UIConversationSort {
  mostRecentInMessageFirst,
  alphabeticalById,
}

class MessageData extends Data {
  String conversationId;
  String messageId;
  MessageData(this.conversationId, this.messageId);

  @override
  String toString() => 'MessageData: {conversationId: $conversationId, messageId: $messageId}';
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
  String messageId;
  TranslationData(this.translationText, this.conversationId, this.messageId);

  @override
  String toString() => 'TranslationData: {translationText: $translationText, conversationId: $conversationId, messageId: $messageId}';
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
  String messageId;
  MessageTagData(this.tagId, this.messageId);

  @override
  String toString() => 'MessageTagData: {tagId: $tagId, messageId: $messageId}';
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

class SaveTagData extends Data {
  String tagText;
  String tagId;

  SaveTagData(this.tagText, this.tagId);

  @override
  String toString() => 'SaveTagData: {tagText: $tagText, tagId: $tagId}';
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

class SnackbarData extends Data {
  String text;
  SnackbarNotificationType type;
  SnackbarData(this.text, this.type);

  @override
  String toString() => 'SnackbarData: {text: $text, type: $type}';
}

class OtherUserData extends Data {
  String userId;
  OtherUserData(this.userId);

  @override
  String toString() => 'OtherUserData: {userId: $userId}';
}

NookController controller;
NookPageView get _view => controller.view;

class NookController extends Controller {
  UIActionObject actionObjectState = UIActionObject.loadingConversations;
  UIConversationSort conversationSortOrder = UIConversationSort.mostRecentInMessageFirst;

  StreamSubscription conversationListSubscription;
  Set<model.Conversation> conversations;
  Set<model.Conversation> filteredConversations;
  List<model.SuggestedReply> suggestedReplies;
  Map<String, List<model.SuggestedReply>> suggestedRepliesByCategory;
  String selectedSuggestedRepliesCategory;
  List<model.Tag> tags;
  Map<String, List<model.Tag>> tagsByGroup;
  Map<String, model.Tag> tagIdsToTags;
  String selectedTagGroup;
  ConversationFilter conversationFilter;
  Map<String, List<model.Tag>> filterTagsByCategory;
  Map<String, List<model.Tag>> filterLastInboundTurnTagsByCategory;
  model.Conversation activeConversation;
  List<model.Conversation> selectedConversations;
  model.Message selectedMessage;
  model.Conversation selectedConversationSummary;

  model.UserConfiguration defaultUserConfig;
  model.UserConfiguration currentUserConfig;
  /// This represents the current configuration of the UI.
  /// It's computed by merging the [defaultUserConfig] and [currentUserConfig] (if set).
  model.UserConfiguration currentConfig;

  DateTime lastUserActivity = new DateTime.now();
  UserPositionReporter userPositionReporter;
  Map<String, Timer> otherUserPresenceTimersByUserId = {};
  Map<String, model.UserPresence> otherUserPresenceByUserId = {};

  NookController() : super() {
    controller = this;

    defaultUserConfig = baseUserConfiguration;
    currentUserConfig = currentConfig = emptyUserConfiguration;
    view = new NookPageView(this);
    platform = new Platform(this);
    userPositionReporter = UserPositionReporter();
  }

  @override
  void setUpOnLogin() {
    conversations = emptyConversationsSet(conversationSortOrder);
    filteredConversations = emptyConversationsSet(conversationSortOrder);
    suggestedReplies = [];
    tags = [];
    tagIdsToTags = {};
    selectedConversations = [];
    activeConversation = null;
    selectedSuggestedRepliesCategory = '';
    selectedTagGroup = '';

    // Get any filter tags from the url
    conversationFilter = new ConversationFilter.fromUrl(currentUserConfig);
    _populateSelectedFilterTags(conversationFilter.getFilters(TagFilterType.include), TagFilterType.include);
    _view.conversationIdFilter.filter = conversationFilter.conversationIdFilter;

    platform.listenForTags(
      (added, modified, removed) {
        var modifiedIds = modified.map((t) => t.tagId).toList();
        var previousModified = tags.where((tag) => modifiedIds.contains(tag.tagId)).toList();
        var updatedIds = new Set()
          ..addAll(added.map((t) => t.tagId))
          ..addAll(modified.map((t) => t.tagId))
          ..addAll(removed.map((t) => t.tagId));
        tags.removeWhere((tag) => updatedIds.contains(tag.tagId));
        tags
          ..addAll(added)
          ..addAll(modified);

        tagIdsToTags = Map.fromEntries(tags.map((t) => MapEntry(t.tagId, t)));

        // Update the filter tags by category map
        filterTagsByCategory = _groupTagsIntoCategories(tags);

        _removeTagsFromFilterMenu(_groupTagsIntoCategories(removed), TagFilterType.include);
        _removeTagsFromFilterMenu(_groupTagsIntoCategories(previousModified), TagFilterType.include);
        _addTagsToFilterMenu(_groupTagsIntoCategories(added), TagFilterType.include);
        _addTagsToFilterMenu(_groupTagsIntoCategories(modified), TagFilterType.include);

        _removeTagsFromFilterMenu(_groupTagsIntoCategories(removed), TagFilterType.exclude);
        _removeTagsFromFilterMenu(_groupTagsIntoCategories(previousModified), TagFilterType.exclude);
        _addTagsToFilterMenu(_groupTagsIntoCategories(added), TagFilterType.exclude);
        _addTagsToFilterMenu(_groupTagsIntoCategories(modified), TagFilterType.exclude);

        // Update the conversation tags by group map
        tagsByGroup = _groupTagsIntoCategories(tags);
        // Empty sublist if there are no tags to show
        if (tagsByGroup.isEmpty) {
          tagsByGroup[''] = [];
        }
        List<String> groups = tagsByGroup.keys.toList();
        groups.sort();
        // Replace list of groups in the UI selector
        _view.tagPanelView.groups = groups;
        // If the groups have changed under us and the selected one no longer exists,
        // default to the first group, whichever it is
        if (!groups.contains(selectedTagGroup)) {
          selectedTagGroup = groups.first;
        }

        _view.tagPanelView.selectedGroup = selectedTagGroup;
        _populateTagPanelView(tagsByGroup[selectedTagGroup]);

        // Re-read the conversation filter from the URL since we now have the names of the tags
        conversationFilter = new ConversationFilter.fromUrl(currentUserConfig);
        _populateSelectedFilterTags(conversationFilter.getFilters(TagFilterType.include), TagFilterType.include);

        if (currentConfig.conversationalTurnsEnabled) {
          _populateSelectedFilterTags(conversationFilter.getFilters(TagFilterType.exclude), TagFilterType.exclude);
        }
      }, showAndLogError);

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
        _view.replyPanelView.categories = categories;
        // If the categories have changed under us and the selected one no longer exists,
        // default to the first category, whichever it is
        if (!categories.contains(selectedSuggestedRepliesCategory)) {
          selectedSuggestedRepliesCategory = categories.first;
        }
        // Select the selected category in the UI and add the suggested replies for it
        _view.replyPanelView.selectedCategory = selectedSuggestedRepliesCategory;
        _populateReplyPanelView(suggestedRepliesByCategory[selectedSuggestedRepliesCategory]);
      }, showAndLogError);

    platform.listenForConversationListShards(
      (added, modified, removed) {
        // TODO: handle removed shards as well
        List<model.ConversationListShard> shards = new List()
          ..addAll(added)
          ..addAll(modified);
        _view.conversationListSelectView.updateConversationLists(shards);

        // Read any conversation shards from the URL
        String urlConversationListRoot = _view.urlView.getPageUrlConversationList();
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
        _view.urlView.setPageUrlConversationList(urlConversationListRoot);
        _view.conversationListSelectView.selectShard(conversationListRoot);
        command(UIAction.selectConversationList, ConversationListData(conversationListRoot));
      }, (error, stacktrace) {
        _view.conversationListPanelView.hideLoadSpinner();
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
        command(BaseAction.updateSystemMessages, SystemMessagesData(systemMessages));
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

    platform.listenForUserPresence(
      (added, modified, removed) {
        // Remove the user presence markings that have changed from the UI
        for (var userPresence in modified + removed) {
          if (userPresence.userId == signedInUser.userEmail) continue;
          var previousUserPresence = otherUserPresenceByUserId[userPresence.userId];
          if (previousUserPresence != null) {
            _view.conversationListPanelView.clearOtherUserPresence(userPresence.userId, previousUserPresence.conversationId);
            _view.otherLoggedInUsers.hideOtherUserPresence(userPresence.userId);
          }

          otherUserPresenceTimersByUserId[userPresence.userId]?.cancel();
        }

        for (var userPresence in removed) {
          otherUserPresenceByUserId.remove(userPresence.userId);
        }

        for (var userPresence in added + modified) {
          if (userPresence.userId == signedInUser.userEmail) continue;
          otherUserPresenceByUserId[userPresence.userId] = userPresence;
        }

        displayOtherUserPresenceIndicators(otherUserPresenceByUserId.values.toList());
      }
    );
  }


  void displayOtherUserPresenceIndicators(List<model.UserPresence> otherUsers) {
    var presenceAge = DateTime.now().toUtc().subtract(Duration(minutes: 10));
    var recencyAge = DateTime.now().toUtc().subtract(Duration(minutes: 2));

    for (var userPresence in otherUsers) {
      if (userPresence.conversationId == null) continue;

      var datetime = DateTime.parse(userPresence.timestamp).toUtc();
      bool shouldShow = datetime.isAfter(presenceAge);
      if (!shouldShow) continue;

      bool isRecent = datetime.isAfter(recencyAge);
      _view.conversationListPanelView.showOtherUserPresence(userPresence.userId, userPresence.conversationId, isRecent);
      _view.otherLoggedInUsers.showOtherUserPresence(userPresence.userId, isRecent);

      var isLessRecentTimerCallback = () {
        _view.conversationListPanelView.clearOtherUserPresence(userPresence.userId, userPresence.conversationId);
        _view.otherLoggedInUsers.hideOtherUserPresence(userPresence.userId);
      };
      var isRecentTimerCallback = () {
        _view.conversationListPanelView.showOtherUserPresence(userPresence.userId, userPresence.conversationId, false);
        _view.otherLoggedInUsers.showOtherUserPresence(userPresence.userId, false);
        otherUserPresenceTimersByUserId[userPresence.userId]?.cancel();
        otherUserPresenceTimersByUserId[userPresence.userId] = new Timer(datetime.difference(presenceAge), isLessRecentTimerCallback);
      };

      if (isRecent) {
        otherUserPresenceTimersByUserId[userPresence.userId]?.cancel();
        otherUserPresenceTimersByUserId[userPresence.userId] = new Timer(datetime.difference(recencyAge), isRecentTimerCallback);
      } else {
        otherUserPresenceTimersByUserId[userPresence.userId]?.cancel();
        otherUserPresenceTimersByUserId[userPresence.userId] = new Timer(datetime.difference(presenceAge), isLessRecentTimerCallback);
      }
    }
  }

  /// Sets user customization flags from the data map
  /// If a flag is not set in the data map, it defaults to the existing values
  void applyConfiguration(model.UserConfiguration newConfig) {
    var oldConfig = currentConfig;
    currentConfig = newConfig;
    if (oldConfig.repliesKeyboardShortcutsEnabled != newConfig.repliesKeyboardShortcutsEnabled) {
      _view.replyPanelView.showShortcuts(newConfig.repliesKeyboardShortcutsEnabled);
    }

    if (oldConfig.tagsKeyboardShortcutsEnabled != newConfig.tagsKeyboardShortcutsEnabled) {
      _view.tagPanelView.showShortcuts(newConfig.tagsKeyboardShortcutsEnabled);
    }

    if (oldConfig.sendMessagesEnabled != newConfig.sendMessagesEnabled) {
      _view.replyPanelView.showButtons(newConfig.sendMessagesEnabled);
    }

    if (oldConfig.sendCustomMessagesEnabled != newConfig.sendCustomMessagesEnabled) {
      _view.conversationPanelView.showCustomMessageBox(newConfig.sendCustomMessagesEnabled);
    }

    if (oldConfig.sendMultiMessageEnabled != newConfig.sendMultiMessageEnabled) {
      _view.conversationListPanelView.showCheckboxes(newConfig.sendMultiMessageEnabled);
      // Start off with no selected conversations
      command(UIAction.deselectAllConversations, null);
    }

    if (oldConfig.tagMessagesEnabled != newConfig.tagMessagesEnabled) {
      if (actionObjectState == UIActionObject.message) {
        _view.tagPanelView.showButtons(newConfig.tagMessagesEnabled);
      }
    }

    if (oldConfig.tagConversationsEnabled != newConfig.tagConversationsEnabled) {
      if (actionObjectState == UIActionObject.conversation) {
        _view.tagPanelView.showButtons(newConfig.tagConversationsEnabled);
      }
    }

    if (oldConfig.editTranslationsEnabled != newConfig.editTranslationsEnabled) {
      _view.conversationPanelView.enableEditableTranslations(newConfig.editTranslationsEnabled);
    }

    if (oldConfig.editNotesEnabled != newConfig.editNotesEnabled) {
      _view.notesPanelView.enableEditableNotes(newConfig.editNotesEnabled);
    }

    if (oldConfig.mandatoryExcludeTagIds != newConfig.mandatoryExcludeTagIds ||
        oldConfig.mandatoryIncludeTagIds != newConfig.mandatoryIncludeTagIds) {
          conversationFilter.updateUserConfig(newConfig);

          _populateSelectedFilterTags(conversationFilter.getFilters(TagFilterType.lastInboundTurn), TagFilterType.lastInboundTurn);
          _populateSelectedFilterTags(conversationFilter.getFilters(TagFilterType.include), TagFilterType.include);
          _populateSelectedFilterTags(conversationFilter.getFilters(TagFilterType.exclude), TagFilterType.exclude);

          updateFilteredAndSelectedConversationLists();
        }

    if (oldConfig.conversationalTurnsEnabled != newConfig.conversationalTurnsEnabled) {
      _view.conversationFilter[TagFilterType.lastInboundTurn].showFilter(newConfig.conversationalTurnsEnabled);
      if (oldConfig.conversationalTurnsEnabled != null && !newConfig.conversationalTurnsEnabled) {
        // only clear things up after we've received the config from the server
        conversationFilter.clearFilters(TagFilterType.lastInboundTurn);

        _view.urlView.setPageUrlFilterTags(TagFilterType.lastInboundTurn, conversationFilter.filterTagIdsManuallySet[TagFilterType.lastInboundTurn]);
      } else {
        _populateSelectedFilterTags(conversationFilter.getFilters(TagFilterType.lastInboundTurn), TagFilterType.lastInboundTurn);
      }

      // exclude filtering is temporary sharing the flag with last inbound turns
      _view.conversationFilter[TagFilterType.exclude].showFilter(newConfig.conversationalTurnsEnabled);
      if (oldConfig.conversationalTurnsEnabled != null && !newConfig.conversationalTurnsEnabled) {
        // only clear things up after we've received the config from the server
        conversationFilter.clearFilters(TagFilterType.exclude);

        _view.urlView.setPageUrlFilterTags(TagFilterType.exclude, conversationFilter.filterTagIdsManuallySet[TagFilterType.exclude]);
      } else {
        _populateSelectedFilterTags(conversationFilter.getFilters(TagFilterType.exclude), TagFilterType.exclude);
      }
    }

    if (oldConfig.tagsPanelVisibility != newConfig.tagsPanelVisibility ||
        oldConfig.editNotesEnabled != newConfig.editNotesEnabled ||
        oldConfig.repliesPanelVisibility != newConfig.repliesPanelVisibility) {
      _view.showPanels(newConfig.repliesPanelVisibility, newConfig.editNotesEnabled, newConfig.tagsPanelVisibility);
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
      _view.urlView.setPageUrlConversationId(null);
    }
    conversationListSubscription = null;
    if (conversationListRoot == ConversationListData.NONE) {
      _view.urlView.setPageUrlConversationList(null);
      _view.conversationListPanelView.totalConversations = 0;
      return;
    }
    _view.urlView.setPageUrlConversationList(conversationListRoot);
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

        _view.conversationListPanelView.totalConversations = conversations.length;

        updateMissingTagIds(conversations, tags, [TagFilterType.include, TagFilterType.exclude, TagFilterType.lastInboundTurn]);

        if (actionObjectState == UIActionObject.loadingConversations) {
          actionObjectState = null;
          _view.tagPanelView.selectedGroup = selectedTagGroup;
          _populateTagPanelView(tagsByGroup[selectedTagGroup]);
        }

        // TODO even though they are unlikely to happen, we should also handle the removals in the UI for consistency

        // Determine if we need to display the conversation from the url
        String urlConversationId = _view.urlView.getPageUrlConversationId();
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
              ..suggestedMessages = []
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

        displayOtherUserPresenceIndicators(otherUserPresenceByUserId.values.toList());

        if (activeConversation == null) return;

        // Update the active conversation view as needed
        if (updatedIds.contains(activeConversation.docId)) {
          updateViewForConversation(activeConversation, updateInPlace: true);
        }
      },
      conversationListRoot,
      showAndLogError);
  }

  SplayTreeSet<model.Conversation> emptyConversationsSet(UIConversationSort sortOrder) {
    switch (sortOrder) {
      case UIConversationSort.alphabeticalById:
        return SplayTreeSet(model.ConversationUtil.alphabeticalById);
      case UIConversationSort.mostRecentInMessageFirst:
      default:
        return SplayTreeSet(model.ConversationUtil.mostRecentInboundFirst);
    }
  }

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

  void command(action, [Data data]) {
    if (action is! UIAction) {
      super.command(action, data);
      return;
    }

    log.verbose('Executing UI command: $actionObjectState - $action - $data');
    log.verbose('Active conversation: ${activeConversation?.docId}');
    log.verbose('Selected conversations: ${selectedConversations?.map((c) => c.docId)?.toList()}');
    log.verbose('Filtered conversations: ${filteredConversations?.map((c) => c.docId)?.toList()}');

    // For most actions, a conversation needs to be active.
    // Early exist if it's not one of the actions valid without an active conversation.
    if (activeConversation == null &&
        action != UIAction.selectConversationList &&
        action != UIAction.addFilterTag && action != UIAction.removeFilterTag &&
        action != UIAction.updateSuggestedRepliesCategory &&
        action != UIAction.updateDisplayedTagsGroup &&
        action != UIAction.selectAllConversations && action != UIAction.deselectAllConversations &&
        action != UIAction.showSnackbar && action != UIAction.updateConversationIdFilter) {
      return;
    }

    if (action != UIAction.showSnackbar) { // not a user action
      lastUserActivity = new DateTime.now();
    }

    if (actionObjectState == UIActionObject.addTagInline) {
      subCommandForAddTagInline(action, data);
      return;
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
        if (!_view.sendingMultiMessagesUserConfirmation(selectedConversations.length)) {
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
        if (!_view.sendingMultiMessageGroupUserConfirmation(selectedReplies.length, selectedConversations.length)) {
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
          if (!_view.sendingManualMessageUserConfirmation(oneoffReply.text)) {
            log.verbose('User cancelled sending manual message reply: "${oneoffReply.text}"');
            return;
          }
          sendReply(oneoffReply, activeConversation);
          _view.conversationPanelView.clearNewMessageBox();
          return;
        }
        if (!_view.sendingManualMultiMessageUserConfirmation(oneoffReply.text, selectedConversations.length)) {
          log.verbose('User cancelled sending manual multi message reply: "${oneoffReply.text}"');
          return;
        }
        sendMultiReply(oneoffReply, selectedConversations);
        _view.conversationPanelView.clearNewMessageBox();
        break;

      case UIAction.confirmSuggestedMessages:
        List<model.SuggestedReply> repliesToSend = [];
        for (var suggestedMessage in activeConversation.suggestedMessages) {
          var reply = new model.SuggestedReply()
            ..text = suggestedMessage.text
            ..translation = suggestedMessage.translation;
          repliesToSend.add(reply);
        }
        sendReplyGroup(repliesToSend, activeConversation, wasSuggested: true);
        break;

      case UIAction.rejectSuggestedMessages:
        platform.rejectSuggestedMessages(addTagInlineConversation).catchError(showAndLogError);
        _view.conversationPanelView.setSuggestedMessages([]);
        break;

      case UIAction.addTag:
        TagData tagData = data;
        switch (actionObjectState) {
          case UIActionObject.conversation:
            model.Tag tag = tags.singleWhere((tag) => tag.tagId == tagData.tagId);
            if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
              setConversationTag(tag, selectedConversationSummary);
              break;
            }
            if (!_view.taggingMultiConversationsUserConfirmation(selectedConversations.length)) {
              return;
            }
            setMultiConversationTag(tag, selectedConversations);
            break;
          case UIActionObject.message:
            model.Tag tag = tags.singleWhere((tag) => tag.tagId == tagData.tagId);
            setMessageTag(tag, selectedMessage, activeConversation);
            break;
          case UIActionObject.loadingConversations:
            break;
          default:
            break;
        }
        updateFilteredAndSelectedConversationLists();
        break;
      case UIAction.addFilterTag:
        FilterTagData tagData = data;
        model.Tag tag = tagIdToTag(tagData.tagId, tagIdsToTags);
        model.Tag unifierTag = unifierTagForTag(tag, tagIdsToTags);
        var added = conversationFilter.addFilter(tagData.filterType, unifierTag);
        if (!added) return; // No change, nothing further to do
        _view.urlView.setPageUrlFilterTags(tagData.filterType, conversationFilter.filterTagIdsManuallySet[tagData.filterType]);
        _view.conversationFilter[tagData.filterType].addFilterTag(new FilterTagView(unifierTag.text, unifierTag.tagId, tagTypeToKKStyle(unifierTag.type), tagData.filterType));
        if (actionObjectState == UIActionObject.loadingConversations) return;
        updateFilteredAndSelectedConversationLists();
        updateViewForConversation(activeConversation, updateInPlace: true);
        break;
      case UIAction.removeConversationTag:
        ConversationTagData conversationTagData = data;
        model.Tag tag = tags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
        platform.removeConversationTag(activeConversation, tag.tagId).catchError(showAndLogError);
        _view.conversationPanelView.removeTag(tag.tagId);
        updateFilteredAndSelectedConversationLists();
        break;
      case UIAction.removeMessageTag:
        MessageTagData messageTagData = data;
        var message = activeConversation.messages.singleWhere((element) => element.id == messageTagData.messageId);
        platform.removeMessageTag(activeConversation, message, messageTagData.tagId).then(
          (_) {
            _view.conversationPanelView
              .messageViewWithId(messageTagData.messageId)
              .removeTag(messageTagData.tagId);
          }, onError: showAndLogError);
        break;

      case UIAction.confirmConversationTag:
        ConversationTagData conversationTagData = data;
        model.Tag tag = tags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
        platform.confirmConversationTag(activeConversation, tag.tagId).catchError(showAndLogError);
        break;

      case UIAction.confirmMessageTag:
        MessageTagData messageTagData = data;
        var message = activeConversation.messages.singleWhere((element) => element.id == messageTagData.messageId);
        platform.confirmMessageTag(activeConversation, message, messageTagData.tagId).catchError(showAndLogError);
        break;

      case UIAction.rejectConversationTag:
        ConversationTagData conversationTagData = data;
        model.Tag tag = tags.singleWhere((tag) => tag.tagId == conversationTagData.tagId);
        platform.rejectConversationTag(activeConversation, tag.tagId).catchError(showAndLogError);
        break;

      case UIAction.rejectMessageTag:
        MessageTagData messageTagData = data;
        var message = activeConversation.messages.singleWhere((element) => element.id == messageTagData.messageId);
        platform.rejectMessageTag(activeConversation, message, messageTagData.tagId).catchError(showAndLogError);
        break;

      case UIAction.removeFilterTag:
        FilterTagData tagData = data;
        model.Tag tag = tagIdToTag(tagData.tagId, tagIdsToTags);
        var changed = conversationFilter.removeFilter(tagData.filterType, tag);
        if (!changed) return; // No change, nothing further to do
        _view.urlView.setPageUrlFilterTags(tagData.filterType, conversationFilter.filterTagIdsManuallySet[tagData.filterType]);
        _view.conversationFilter[tagData.filterType].removeFilterTag(tag.tagId);
        if (actionObjectState == UIActionObject.loadingConversations) return;
        updateFilteredAndSelectedConversationLists();
        updateViewForConversation(activeConversation, updateInPlace: true);
        break;
      case UIAction.updateConversationIdFilter:
        ConversationIdFilterData filterData = data;
        conversationFilter.conversationIdFilter = filterData.idFilter;
        _view.urlView.setPageUrlFilterConversationId(filterData.idFilter.isEmpty ? null : filterData.idFilter);
        if (actionObjectState == UIActionObject.loadingConversations) return;
        updateFilteredAndSelectedConversationLists();
        break;
      case UIAction.selectConversationSummary:
        ConversationData conversationData = data;
        selectedConversationSummary = conversations.firstWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
        _view.conversationPanelView.selectConversationSummary();
        actionObjectState = UIActionObject.conversation;
        _view.tagPanelView.hideInstruction();

        selectedMessage = null;
        _view.conversationPanelView.deselectMessage();
        break;
      case UIAction.deselectConversationSummary:
        if (actionObjectState == UIActionObject.conversation) {
          selectedConversationSummary = null;
          _view.conversationPanelView.deselectConversationSummary();
          actionObjectState = null;

          if (selectedConversationSummary == null && selectedMessage == null) {
            _view.tagPanelView.showInstruction();
          }
        }
        break;
      case UIAction.selectMessage:
        MessageData messageData = data;
        selectedMessage = activeConversation.messages.singleWhere((element) => element.id == messageData.messageId);
        _view.conversationPanelView.selectMessage(activeConversation.messages.indexOf(selectedMessage));
        actionObjectState = UIActionObject.message;
        _view.tagPanelView.hideInstruction();

        selectedConversationSummary = null;
        _view.conversationPanelView.deselectConversationSummary();
        break;
      case UIAction.deselectMessage:
        if (actionObjectState == UIActionObject.message) {
          selectedMessage = null;
          _view.conversationPanelView.deselectMessage();
          actionObjectState = null;

          if(selectedConversationSummary == null && selectedMessage == null) {
            _view.tagPanelView.showInstruction();
          }
        }
        break;
      case UIAction.markConversationRead:
        // TODO(mariana): the logic of marking conversations read/unread needs rethinking, likely needs to be using tags
        // ConversationData conversationData = data;
        // model.Conversation conversation = conversations.singleWhere((c) => c.docId == conversationData.deidentifiedPhoneNumber);
        // _view.conversationListPanelView.markConversationRead(conversation.docId);
        // platform.updateUnread([conversation], false).catchError(showAndLogError);
        break;
      case UIAction.markConversationUnread:
        // TODO(mariana): the logic of marking conversations read/unread needs rethinking, likely needs to be using tags
        // if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
        //   _view.conversationListPanelView.markConversationUnread(activeConversation.docId);
        //   platform.updateUnread([activeConversation], true).catchError(showAndLogError);
        //   return;
        // }
        // var markedConversations = <model.Conversation>[];
        // for (var conversation in selectedConversations) {
        //   if (!conversation.unread) {
        //     markedConversations.add(conversation);
        //     _view.conversationListPanelView.markConversationUnread(conversation.docId);
        //   }
        // }
        // platform.updateUnread(markedConversations, true).catchError(showAndLogError);
        break;
      case UIAction.changeConversationSortOrder:
        conversationSortOrder = UIConversationSort.values[(UIConversationSort.values.indexOf(conversationSortOrder) + 1) % UIConversationSort.values.length];
        conversations = emptyConversationsSet(conversationSortOrder)
          ..addAll(conversations);
        filteredConversations = emptyConversationsSet(conversationSortOrder)
          ..addAll(filteredConversations);
        _view.conversationListPanelView.changeConversationSortOrder(conversationSortOrder);
        updateFilteredAndSelectedConversationLists();
        break;
      case UIAction.showConversation:
        ConversationData conversationData = data;
        actionObjectState = null;
        if (conversationData.deidentifiedPhoneNumber == activeConversation.docId) break;
        bool shouldRecomputeConversationList = !filteredConversations.contains(activeConversation);
        activeConversation = conversations.singleWhere((conversation) => conversation.docId == conversationData.deidentifiedPhoneNumber);
        if (shouldRecomputeConversationList) updateFilteredAndSelectedConversationLists();
        updateViewForConversation(activeConversation);
        break;
      case UIAction.selectConversationList:
        ConversationListData conversationListData = data;
        conversations = emptyConversationsSet(conversationSortOrder);
        filteredConversations = emptyConversationsSet(conversationSortOrder);
        selectedConversations.clear();
        activeConversation = null;
        actionObjectState = UIActionObject.loadingConversations;
        _view.conversationListPanelView.clearConversationList();
        _view.conversationPanelView.clear();
        _view.notesPanelView.noteText = '';
        activeConversation = null;
        if (conversationListData.conversationListRoot == ConversationListData.NONE) {
          _view.conversationListPanelView.showSelectConversationListMessage();
        } else {
          _view.conversationListPanelView.showLoadSpinner();
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
          var message = conversation.messages.singleWhere((element) => element.id == messageTranslation.messageId);
          SaveTextAction.textChange(
            "${conversation.docId}.message-${messageTranslation.messageId}.translation",
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
          _view.snackbarView.hideSnackbar();
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
            var selectedTag = tags.where((tag) => tag.shortcut == keyPressData.key);
            if (selectedTag.isEmpty) break;
            assert (selectedTag.length == 1);
            setConversationTag(selectedTag.first, activeConversation);
            if (!currentConfig.sendMultiMessageEnabled || selectedConversations.isEmpty) {
              setConversationTag(selectedTag.first, activeConversation);
              return;
            }
            if (!_view.taggingMultiConversationsUserConfirmation(selectedConversations.length)) {
              return;
            }
            setMultiConversationTag(selectedTag.first, selectedConversations);
            return;
          case UIActionObject.message:
            // Early exit if tagging messages is disabled
            if (!currentConfig.tagConversationsEnabled) return;
            var selectedTag = tags.where((tag) => tag.shortcut == keyPressData.key);
            if (selectedTag.isEmpty) break;
            assert (selectedTag.length == 1);
            setMessageTag(selectedTag.first, selectedMessage, activeConversation);
            return;
          case UIActionObject.loadingConversations:
            break;
          default:
            break;
        }
        // There is no matching shortcut in either replies or tags, ignore
        break;
      case UIAction.startAddNewTagInline:
        actionObjectState = UIActionObject.addTagInline;
        subCommandForAddTagInline(action, data);
        break;
      case UIAction.selectAllConversations:
        _view.conversationListPanelView.checkAllConversations();
        selectedConversations.clear();
        selectedConversations.addAll(filteredConversations);
        updateFilteredAndSelectedConversationLists();
        break;
      case UIAction.deselectAllConversations:
        _view.conversationListPanelView.uncheckSelectAllCheckbox();
        _view.conversationListPanelView.uncheckAllConversations();
        selectedConversations.clear();
        if (actionObjectState != UIActionObject.loadingConversations) {
          updateFilteredAndSelectedConversationLists();
        }
        break;
      case UIAction.updateSuggestedRepliesCategory:
        UpdateSuggestedRepliesCategoryData updateCategoryData = data;
        selectedSuggestedRepliesCategory = updateCategoryData.category;
        _populateReplyPanelView(suggestedRepliesByCategory[selectedSuggestedRepliesCategory]);
        break;
      case UIAction.updateDisplayedTagsGroup:
        UpdateTagsGroupData updateGroupData = data;
        selectedTagGroup = updateGroupData.group;
        _populateTagPanelView(tagsByGroup[selectedTagGroup]);
        break;

      case UIAction.showSnackbar:
        SnackbarData snackbarData = data;
        _view.snackbarView.showSnackbar(snackbarData.text, snackbarData.type);
        break;

      case UIAction.goToUser:
        OtherUserData userData = data;
        String conversationId = otherUserPresenceByUserId[userData.userId].conversationId;
        command(UIAction.showConversation, ConversationData(conversationId));
        break;

      default:
        break;
    }
  }

  model.Conversation addTagInlineConversation;
  model.Message addTagInlineMessage;
  model.Tag newTagInline;
  EditableTagView addTagInlineView;

  void subCommandForAddTagInline(UIAction action, [Data data]) {
    switch (action) {
      case UIAction.startAddNewTagInline:
        if (newTagInline != null) return; // another tag creation in progress

        MessageData messageData = data;
        newTagInline = new model.Tag()
          ..docId = model.generateTagId()
          ..filterable = true
          ..groups = ["${signedInUser.userName}'s tags"]
          ..isUnifier = false
          ..text = ''
          ..shortcut = ''
          ..visible = true
          ..type = model.TagType.normal;

        addTagInlineConversation = activeConversation;
        addTagInlineMessage = addTagInlineConversation.messages.singleWhere((element) => element.id == messageData.messageId);

        addTagInlineView = new EditableTagView(newTagInline.text, newTagInline.tagId, tagTypeToKKStyle(newTagInline.type));
        _view.conversationPanelView
            .messageViewWithId(messageData.messageId)
            .addTag(addTagInlineView);
        addTagInlineView.focus();
        break;
      case UIAction.saveNewTagInline:
        SaveTagData saveTagData = data;
        actionObjectState = UIActionObject.message;

        newTagInline..text = saveTagData.tagText;
        platform.addTag(newTagInline).then(
          (_) {
            _view.conversationPanelView
                .messageViewAtIndex(addTagInlineConversation.messages.indexOf(addTagInlineMessage))
                .removeTag(newTagInline.tagId);
            tags.add(newTagInline);

            setMessageTag(newTagInline, addTagInlineMessage, addTagInlineConversation);
            newTagInline = null;
            addTagInlineMessage = null;
            addTagInlineConversation = null;
          }, onError: showAndLogError);
        break;
      case UIAction.cancelAddNewTagInline:
        actionObjectState = UIActionObject.message;
        _view.conversationPanelView
            .messageViewAtIndex(addTagInlineConversation.messages.indexOf(addTagInlineMessage))
            .removeTag(newTagInline.tagId);
        newTagInline = null;
        addTagInlineMessage = null;
        addTagInlineConversation = null;
        break;
      default:
        break;
    }
  }

  void updateFilteredAndSelectedConversationLists() {
    filteredConversations = conversations.where((conversation) => conversationFilter.test(conversation)).toSet();
    if (!currentConfig.sendMultiMessageEnabled) {
      activeConversation = updateViewForConversations(conversationsInView);
      return;
    }
    // Update the conversation objects in [selectedConversations] in case any of them were replaced
    Set selectedConversationsIds = selectedConversations.map((c) => c.docId).toSet();
    selectedConversations = conversations.where((c) => selectedConversationsIds.contains(c.docId)).toList();

    // Show both filtered and selected conversations in the list,
    // but mark the selected conversations that don't meet the filter with a warning
    activeConversation = updateViewForConversations(conversationsInView);
    _view.conversationListPanelView.showCheckboxes(currentConfig.sendMultiMessageEnabled);
    conversationsInView.forEach((conversation) {
      if (selectedConversations.contains(conversation)) {
        _view.conversationListPanelView.checkConversation(conversation.docId);
      }
      if (filteredConversations.contains(conversation)) {
        _view.conversationListPanelView.clearWarning(conversation.docId);
      } else {
        _view.conversationListPanelView.showWarning(conversation.docId);
      }
    });
  }

  /// Shows the list of [conversations] and selects the first conversation
  /// where [updateList] is `true` if this list can be updated in place.
  /// Returns the first conversation in the list, or null if list is empty.
  model.Conversation updateViewForConversations(Set<model.Conversation> conversations) {
    // Update conversationListPanelView
    _populateConversationListPanelView(conversations);

    // Update conversationPanelView
    if (conversations.isEmpty) {
      if (activeConversation != null) {
        _view.conversationPanelView.showWarning('Conversation no longer meets filtering constraints');
        return activeConversation;
      }
      _view.conversationPanelView.clear();
      _view.notesPanelView.noteText = '';
      actionObjectState = null;
      return null;
    }

    if (activeConversation == null) {
      model.Conversation conversationToSelect = conversations.first;
      _selectConversationInView(conversationToSelect);
      _populateConversationPanelView(conversationToSelect);
      _view.notesPanelView.noteText = conversationToSelect.notes;
      actionObjectState = null;
      return conversationToSelect;
    }

    var matches = conversations.where((conversation) => conversation.docId == activeConversation.docId).toList();
    if (matches.length == 0) {
      _view.conversationPanelView.showWarning('Conversation no longer meets filtering constraints');
      return activeConversation;
    }

    if (matches.length > 1) {
      log.warning('Two conversations seem to have the same deidentified phone number: ${activeConversation.docId}');
    }
    _selectConversationInView(activeConversation);
    _view.conversationPanelView.clearWarning();
    return activeConversation;
  }

  void updateViewForConversation(model.Conversation conversation, {bool updateInPlace: false}) {
    userPositionReporter.reportPresence(signedInUser, conversation);
    if (conversation == null) return;
    // Replace the previous conversation in the conversation panel
    _populateConversationPanelView(conversation, updateInPlace: updateInPlace);
    _view.notesPanelView.noteText = conversation.notes;
    // Reselect message if selected
    if (actionObjectState == UIActionObject.message) {
      selectedMessage = conversation.messages.singleWhere((element) => element.id == selectedMessage.id);
      _view.conversationPanelView.selectMessage(conversation.messages.indexOf(selectedMessage));
    }
    _selectConversationInView(conversation);
    if (!filteredConversations.contains(conversation)) {
      // If it doesn't meet the filter, show warning
      _view.conversationPanelView.showWarning('Conversation no longer meets filtering constraints');
    }
  }

  void _selectConversationInView(model.Conversation conversation) {
    _view.urlView.setPageUrlConversationId(conversation.docId);
    if (conversationsInView.contains(conversation)) {
      // Select the conversation in the list of conversations
      _view.conversationListPanelView.selectConversation(conversation.docId);
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
    _view.conversationPanelView.addMessage(_generateMessageView(newMessage, conversation));
    log.verbose('Sending reply "${reply.text}" to conversation ${conversation.docId}');
    platform.sendMessage(conversation.docId, reply.text, onError: (error) {
      log.error('Reply "${reply.text}" failed to be sent to conversation ${conversation.docId}');
      log.error('Error: ${error}');
      command(UIAction.showSnackbar, new SnackbarData('Send Reply Failed', SnackbarNotificationType.error));
      newMessage.status = model.MessageStatus.failed;
      if (conversation.docId == activeConversation.docId) {
        int newMessageIndex = activeConversation.messages.indexOf(newMessage);
        _view.conversationPanelView.messageViewAtIndex(newMessageIndex).setStatus(newMessage.status);
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
      _view.conversationPanelView.addMessage(_generateMessageView(newMessage, activeConversation));
    }
    log.verbose('Sending reply "${reply.text}" to conversations ${conversationIds}');
    platform.sendMultiMessage(conversationIds, newMessage.text, onError: (error) {
      log.error('Reply "${reply.text}" failed to be sent to conversations ${conversationIds}');
      log.error('Error: ${error}');
      command(UIAction.showSnackbar, new SnackbarData('Send Multi Reply Failed', SnackbarNotificationType.error));
      newMessage.status = model.MessageStatus.failed;
      if (conversationIds.contains(activeConversation.docId)) {
        int newMessageIndex = activeConversation.messages.indexOf(newMessage);
        _view.conversationPanelView.messageViewAtIndex(newMessageIndex).setStatus(newMessage.status);
      }
    });
    log.verbose('Reply "${reply.text}" queued for sending to conversations ${conversationIds}');
  }

  void sendReplyGroup(List<model.SuggestedReply> replies, model.Conversation conversation, {bool wasSuggested = false}) {
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
      _view.conversationPanelView.addMessage(_generateMessageView(message, conversation));
    }

    log.verbose('Sending ${textReplies.length} replies "${repliesStr}" to conversation ${conversation.docId}');
    platform.sendMessages(conversation.docId, textReplies, wasSuggested: wasSuggested, onError: (error) {
      log.error('${textReplies.length} replies "${repliesStr}" failed to be sent to conversation ${conversation.docId}');
      log.error('Error: ${error}');
      command(UIAction.showSnackbar, new SnackbarData('Send Reply Failed', SnackbarNotificationType.error));
      for (var message in newMessages) {
        message.status = model.MessageStatus.failed;
        if (conversation.docId == activeConversation.docId) {
          int messageIndex = activeConversation.messages.indexOf(message);
          _view.conversationPanelView.messageViewAtIndex(messageIndex).setStatus(message.status);
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
        _view.conversationPanelView.addMessage(_generateMessageView(message, activeConversation));
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
          _view.conversationPanelView.messageViewAtIndex(messageIndex).setStatus(message.status);
        }
      }
    });
    log.verbose('${textReplies.length} replies "${repliesStr}" queued for sending to conversations ${conversationIds}');
  }

  void setConversationTag(model.Tag tag, model.Conversation conversation) {
    if (!conversation.tagIds.contains(tag.tagId)) {
      platform.addConversationTag(conversation, tag.tagId).catchError(showAndLogError);
      _view.conversationPanelView.addTags(new ConversationTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type)));
    }
  }

  void setMultiConversationTag(model.Tag tag, List<model.Conversation> conversations) {
    conversations.forEach((conversation) {
      if (!conversation.tagIds.contains(tag.tagId)) {
        platform.addConversationTag(conversation, tag.tagId).catchError(showAndLogError);
        if (conversation == activeConversation) {
          _view.conversationPanelView.addTags(new ConversationTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type)));
        }
      }
    });
  }

  void setMessageTag(model.Tag tag, model.Message message, model.Conversation conversation) {
    if (!message.tagIds.contains(tag.tagId)) {
      platform.addMessageTag(activeConversation, message, tag.tagId).then(
        (_) {
          var tagView = new MessageTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type));
          _view.conversationPanelView
            .messageViewAtIndex(conversation.messages.indexOf(message))
            .addTag(tagView);
          tagView.markPending(true);
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
      var tagsToRemove = convertTagIdsToTags(tagIdsToRemove, Map.fromEntries(tags.map((t) => MapEntry(t.tagId, t))));
      tags.removeWhere((tag) => tagsToRemove.contains(tag));
      var groupsToUpdate = <String>{};
      for (var tag in tagsToRemove) {
        if (tag.groups.isEmpty) {
          groupsToUpdate.add('');
          continue;
        }
        groupsToUpdate.addAll(tag.groups);
      }
      for (var group in groupsToUpdate) {
        var tagsToRemoveForGroup = tagsToRemove.where((t) => t.groups.contains(group)).toList();
        for (var filterType in filterTypes) {
          _removeTagsFromFilterMenu({group: tagsToRemoveForGroup}, filterType);
        }
      }
    }
    // add tags that are new
    var tagIdsToAdd = newTagIdsWithMissingInfo.difference(tagIdsWithMissingInfo);
    if (tagIdsToAdd.isEmpty) return;
    var tagsToAdd = convertTagIdsToTags(tagIdsToAdd, Map.fromEntries(tags.map((t) => MapEntry(t.tagId, t))));
    tags.addAll(tagsToAdd);
    var groupsToUpdate = <String>{};
    for (var tag in tagsToAdd) {
      if (tag.groups.isEmpty) {
        groupsToUpdate.add('');
        continue;
      }
      groupsToUpdate.addAll(tag.groups);
    }
    for (var group in groupsToUpdate) {
      var tagsToAddForGroup = tagsToAdd.where((t) => t.groups.contains(group)).toList();
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
}

Map<String, model.Tag> _notFoundTagIds = {};

UnmodifiableListView<model.Tag> convertTagIdsToTags(Iterable<String> tagIds, Map<String, model.Tag> allTags) {
  var tags = <model.Tag>[];
  if (tagIds == null) return UnmodifiableListView(tags);

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

// TODO(mariana): this should be picked up from the project configuration
const OUR_TURN_TAG_ID = 'tag-97a3da54';
bool isOurTurnInConversation(model.Conversation conversation) => conversation.tagIds.contains(OUR_TURN_TAG_ID);

typedef Future<dynamic> SaveText(String newText);

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
    _view.showNormalStatus('saving...');
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
      _view.showNormalStatus('saved');
      log.verbose('note saved: $_changeId');
    } catch (e, s) {
      _view.showWarningStatus('save failed');
      log.warning('save note failed: $_changeId\n  $e\n$s');
    }
  }
}

void showAndLogError(error, trace) {
  log.error("$error${trace != null ? "\n$trace" : ""}");
  String errMsg;
  if (error is PubSubException) {
    errMsg = "A network problem occurred: ${error.message}";
  } else if (error is FirebaseError) {
    errMsg = "An firestore error occured: ${error.code} [${error.message}]";
    _view.bannerView.showBanner("You don't have access to this dataset. Please contact your project administrator");
  } else if (error is Exception) {
    errMsg = "An internal error occurred: ${error.runtimeType}";
  }  else {
    errMsg = "$error";
  }
  controller.command(UIAction.showSnackbar, new SnackbarData(errMsg, SnackbarNotificationType.error));
}
