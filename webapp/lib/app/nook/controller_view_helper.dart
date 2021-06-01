part of controller;

const SEND_REPLY_BUTTON_TEXT = 'SEND';
const SEND_CUSTOM_REPLY_BUTTON_TEXT = 'SEND custom message';
const SEND_SUGGESTED_REPLY_BUTTON_TEXT = 'SEND suggested messages';
const DELETE_SUGGESTED_REPLY_BUTTON_TEXT = 'DELETE suggested messages';

const TAG_CONVERSATION_BUTTON_TEXT = 'TAG';

const SMS_MAX_LENGTH = 160;

// Functions to populate the views with model objects.

void _populateConversationListPanelView(Set<model.Conversation> conversations, bool updateList) {
  _view.conversationListPanelView.hideLoadSpinner();
  _view.conversationListPanelView.hideSelectConversationListMessage();
  if (conversations.isEmpty || !updateList) {
    _view.conversationListPanelView.clearConversationList();
  }
  _view.conversationListPanelView.updateConversationList(conversations);
}

void _populateConversationPanelView(model.Conversation conversation, {bool updateInPlace: false}) {
  if (updateInPlace) {
    _updateConversationPanelView(conversation);
    return;
  }
  _view.conversationPanelView.clear();
  _view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.docId
    ..deidentifiedPhoneNumberShort = conversation.shortDeidentifiedPhoneNumber
    ..demographicsInfo = conversation.demographicsInfo.values.join(', ');
  for (var tag in convertTagIdsToTags(conversation.tagIds, controller.tagIdsToTags)) {
    _view.conversationPanelView.addTags(new ConversationTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type)));
  }
  for (var tag in convertTagIdsToTags(conversation.suggestedTagIds, controller.tagIdsToTags)) {
    _view.conversationPanelView.addTags(new SuggestedConversationTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type)));
  }

  for (var message in conversation.messages) {
    MessageView messageView = _generateMessageView(message, conversation);
    _view.conversationPanelView.addMessage(messageView);
  }

  List<SuggestedMessageView> suggestedMessages = [];
  for (var message in conversation.suggestedMessages) {
    suggestedMessages.add(new SuggestedMessageView(message.text, translation: message.translation));
  }
  _view.conversationPanelView.setSuggestedMessages(suggestedMessages);
}

void _updateConversationPanelView(model.Conversation conversation) {
  _view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.docId
    ..deidentifiedPhoneNumberShort = conversation.shortDeidentifiedPhoneNumber
    ..demographicsInfo = conversation.demographicsInfo.values.join(', ');
  _view.conversationPanelView.removeTags();
  for (var tag in convertTagIdsToTags(conversation.tagIds, controller.tagIdsToTags)) {
    _view.conversationPanelView.addTags(new ConversationTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type)));
  }
  for (var tag in convertTagIdsToTags(conversation.suggestedTagIds, controller.tagIdsToTags)) {
    _view.conversationPanelView.addTags(new SuggestedConversationTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type)));
  }

  _view.conversationPanelView.padOrTrimMessageViews(conversation.messages.length);
  for (int i = 0; i < conversation.messages.length; i++) {
    MessageView messageView = _generateMessageView(conversation.messages[i], conversation);
    _view.conversationPanelView.updateMessage(messageView, i);
  }

  List<SuggestedMessageView> suggestedMessages = [];
  for (var message in conversation.suggestedMessages) {
    suggestedMessages.add(new SuggestedMessageView(message.text, translation: message.translation));
  }
  _view.conversationPanelView.setSuggestedMessages(suggestedMessages);
}

MessageView _generateMessageView(model.Message message, model.Conversation conversation) {
  List<TagView> tags = [];
  for (var tag in convertTagIdsToTags(message.tagIds, controller.tagIdsToTags)) {
    bool shouldHighlightTag = controller.conversationFilter.filterTagIds[TagFilterType.include].contains(tag.tagId);
    shouldHighlightTag = shouldHighlightTag || controller.conversationFilter.filterTagIds[TagFilterType.lastInboundTurn].contains(tag.tagId);
    tags.add(new MessageTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), shouldHighlightTag));
  }
  for (var tag in convertTagIdsToTags(message.suggestedTagIds, controller.tagIdsToTags)) {
    bool shouldHighlightTag = controller.conversationFilter.filterTagIds[TagFilterType.include].contains(tag.tagId);
    shouldHighlightTag = shouldHighlightTag || controller.conversationFilter.filterTagIds[TagFilterType.lastInboundTurn].contains(tag.tagId);
    tags.add(new SuggestedMessageTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), shouldHighlightTag));
  }
  var messageView = new MessageView(message.text, message.datetime, conversation.docId, conversation.messages.indexOf(message),
      translation: message.translation, incoming: message.direction == model.MessageDirection.In, tags: tags, status: message.status);
  messageView.enableEditableTranslations(controller.currentConfig.editTranslationsEnabled);
  return messageView;
}

void _populateReplyPanelView(List<model.SuggestedReply> replies) {
  Map<String, List<model.SuggestedReply>> repliesByGroups = _groupRepliesIntoGroups(replies);
  _view.replyPanelView.clear();
  String buttonText = SEND_REPLY_BUTTON_TEXT;
  for (var groupId in repliesByGroups.keys) {
    var repliesInGroup = repliesByGroups[groupId];
    List<ReplyActionView> views = [];
    var groupDescription = "";
    for (var reply in repliesInGroup) {
      groupDescription = reply.groupDescription;
      int replyIndex = replies.indexOf(reply);
      var replyView = new ReplyActionView(reply.text, reply.translation, reply.shortcut, replyIndex, buttonText);
      replyView.showShortcut(controller.currentConfig.repliesKeyboardShortcutsEnabled);
      replyView.showButtons(controller.currentConfig.sendMessagesEnabled);
      views.add(replyView);
    }
    if (views.length == 1) {
      _view.replyPanelView.addReply(views.first);
      continue;
    }
    var replyGroupView = new ReplyActionGroupView(groupId, groupDescription, buttonText + " all", views);
    _view.replyPanelView.addReply(replyGroupView);
  }
}

void _populateTagPanelView(List<model.Tag> tags) {
  _view.tagPanelView.clear();

  // Important tags first, then sort by text string
  tags.sort((t1, t2) {
    switch (t1.type) {
      case model.TagType.Important:
        if (t2.type == model.TagType.Important) {
          return t1.text.compareTo(t2.text);
        } else {
          return -1;
        }
        break;
      default:
        if (t2.type == model.TagType.Important) {
          return 1;
        } else {
          return t1.text.compareTo(t2.text);
        }
    }
  });

  for (var tag in tags) {
    var tagView = new TagActionView(tag.text, tag.shortcut, tag.tagId, TAG_CONVERSATION_BUTTON_TEXT);
    tagView.showShortcut(controller.currentConfig.tagsKeyboardShortcutsEnabled);
    tagView.showButtons(controller.currentConfig.tagConversationsEnabled);
    _view.tagPanelView.addTag(tagView);
  }
}

void _removeTagsFromFilterMenu(Map<String, List<model.Tag>> tagsByCategory, TagFilterType filterType) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    for (var tag in tagsByCategory[category]) {
      _view.conversationFilter[filterType].removeMenuTag(new FilterMenuTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), filterType), category);
    }
  }
}

void _addTagsToFilterMenu(Map<String, List<model.Tag>> tagsByCategory, TagFilterType filterType) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    for (var tag in tagsByCategory[category]) {
      _view.conversationFilter[filterType].addMenuTag(new FilterMenuTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), filterType), category);
    }
  }
}

void _addDateTagToFilterMenu(TagFilterType filterType) {
  _view.conversationFilter[filterType].addMenuTag(AfterDateFilterMenuTagView(filterType), "Date");
}

void _populateSelectedFilterTags(Set<model.Tag> tags, TagFilterType filterType) {
  _view.conversationFilter[filterType].clearSelectedTags();
  for (var tag in tags) {
    _view.conversationFilter[filterType].addFilterTag(new FilterTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type), filterType));
  }
}

void _populateSelectedAfterDateFilterTag(DateTime afterDateFilter, TagFilterType filterType) {
  _view.conversationFilter[filterType].removeFilterTag(AFTER_DATE_TAG_ID);
  if (afterDateFilter != null) {
    _view.conversationFilter[filterType].addFilterTag(new AfterDateFilterTagView(afterDateFilter, filterType));
  }
}

TagStyle tagTypeToStyle(model.TagType tagType) {
  switch (tagType) {
    case model.TagType.Important:
      return TagStyle.Important;
    default:
      if (tagType == model.NotFoundTagType.NotFound) {
        return TagStyle.Yellow;
      }
      return TagStyle.None;
  }
}

kk.TagStyle tagTypeToKKStyle(model.TagType tagType) {
  switch (tagType) {
    case model.TagType.Important:
      return kk.TagStyle.Important;
    default:
      if (tagType == model.NotFoundTagType.NotFound) {
        return kk.TagStyle.Yellow;
      }
      return kk.TagStyle.None;
  }
}

Map<String, List<model.SuggestedReply>> _groupRepliesIntoCategories(List<model.SuggestedReply> replies) {
  Map<String, List<model.SuggestedReply>> result = {};
  for (model.SuggestedReply reply in replies) {
    String category = reply.category ?? '';
    if (!result.containsKey(category)) {
      result[category] = [];
    }
    result[category].add(reply);
  }
  return result;
}

Map<String, List<model.SuggestedReply>> _groupRepliesIntoGroups(List<model.SuggestedReply> replies) {
  Map<String, List<model.SuggestedReply>> result = {};
  for (model.SuggestedReply reply in replies) {
    // TODO (mariana): once we've transitioned to using groups, we can remove the sequence number fix
    String groupId = controller.currentConfig.suggestedRepliesGroupsEnabled ? reply.groupId ?? reply.seqNumber.toString() : reply.seqNumber.toString();
    if (!result.containsKey(groupId)) {
      result[groupId] = [];
    }
    result[groupId].add(reply);
  }
  for (String groupId in result.keys) {
    // TODO (mariana): once we've transitioned to using groups, we can remove the sequence number comparison
    result[groupId].sort((reply1, reply2) => (reply1.indexInGroup ?? reply1.seqNumber).compareTo(reply2.indexInGroup ?? reply2.seqNumber));
  }
  return result;
}

Map<String, List<model.Tag>> _groupTagsIntoCategories(List<model.Tag> tags) {
  Map<String, List<model.Tag>> result = {};
  for (model.Tag tag in tags) {
    if (tag.groups.isEmpty) {
      if (tag.group.isEmpty) {
        result.putIfAbsent("", () => []).add(tag);
        continue;
      }
      result.putIfAbsent(tag.group, () => []).add(tag);
      continue;
    }
    for (var group in tag.groups) {
      result.putIfAbsent(group, () => []).add(tag);
    }
  }
  // Sort tags alphabetically
  for (var tags in result.values) {
    tags.sort((t1, t2) => t1.text.compareTo(t2.text));
  }
  return result;
}
