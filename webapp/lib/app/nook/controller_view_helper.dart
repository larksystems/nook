part of controller;

const EDIT_REPLY_BUTTON_TEXT = 'EDIT';
const SEND_REPLY_BUTTON_TEXT = 'SEND';
const SEND_ALL_BUTTON_TEXT = 'SEND all';
const SEND_CUSTOM_REPLY_BUTTON_TEXT = 'SEND custom message';
const SEND_SUGGESTED_REPLY_BUTTON_TEXT = 'SEND suggested messages';
const DELETE_SUGGESTED_REPLY_BUTTON_TEXT = 'DELETE suggested messages';

const TAG_CONVERSATION_BUTTON_TEXT = 'TAG';

// Functions to populate the views with model objects.

void _populateConversationListPanelView(Set<model.Conversation> conversations, UIConversationSort sortOrder) {
  _view.conversationListPanelView.hideLoadSpinner();
  _view.conversationListPanelView.hideSelectConversationListMessage();
  _view.conversationListPanelView.updateConversationList(conversations, sortOrder);
}

void _populateConversationPanelView(model.Conversation conversation, {bool updateInPlace: false}) {
  if (updateInPlace) {
    _updateConversationPanelView(conversation);
    return;
  }

  var demogInfo = conversation.demographicsInfo.values.toList();
  if (controller.uuidToPhoneNumberMapping.containsKey(conversation.docId)) {
    demogInfo.insert(0, controller.uuidToPhoneNumberMapping[conversation.docId]);
  }

  _view.conversationPanelView.clear();
  _view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.docId
    ..deidentifiedPhoneNumberShort = conversation.shortDeidentifiedPhoneNumber
    ..demographicsInfo = demogInfo.join(', ');
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
  _view.conversationPanelView.updateDateSeparators();
  _populateTurnlines(conversation.turnlines);
}

void _updateConversationPanelView(model.Conversation conversation) {
  var demogInfo = conversation.demographicsInfo.values.toList();
  if (controller.uuidToPhoneNumberMapping.containsKey(conversation.docId)) {
    demogInfo.insert(0, controller.uuidToPhoneNumberMapping[conversation.docId]);
  }

  _view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.docId
    ..deidentifiedPhoneNumberShort = conversation.shortDeidentifiedPhoneNumber
    ..demographicsInfo = demogInfo.join(', ');
  _view.conversationPanelView.removeTags();
  for (var tag in convertTagIdsToTags(conversation.tagIds, controller.tagIdsToTags)) {
    _view.conversationPanelView.addTags(new ConversationTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type)));
  }
  for (var tag in convertTagIdsToTags(conversation.suggestedTagIds, controller.tagIdsToTags)) {
    _view.conversationPanelView.addTags(new SuggestedConversationTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type)));
  }

  _view.conversationPanelView.padOrTrimMessageViews(conversation.messages.length);
  for (int i = 0; i < conversation.messages.length; i++) {
    var message = conversation.messages[i];
    // Update message inline when adding a tag inline
    if (controller.actionObjectState == UIActionObject.addTagInline && message.id == controller.addTagInlineMessage.id) {
      var messageView = _view.conversationPanelView.messageViewWithId(message.id);
      messageView
        ..text = message.text
        ..translation = message.translation
        ..datetime = message.datetime.toLocal();
      for (var tagId in message.tagIds) {
        messageView.removeTag(tagId);
      }
      var tags = _generateMessageTagViews(message);
      for (int j = 0; j < tags.length; j++) {
        messageView.addTag(tags[j], j);
      }
      continue;
    }
    MessageView messageView = _generateMessageView(message, conversation);
    _view.conversationPanelView.updateMessage(messageView, i);
  }

  List<SuggestedMessageView> suggestedMessages = [];
  for (var message in conversation.suggestedMessages) {
    suggestedMessages.add(new SuggestedMessageView(message.text, translation: message.translation));
  }
  _view.conversationPanelView.setSuggestedMessages(suggestedMessages);
  _view.conversationPanelView.updateDateSeparators();
  _populateTurnlines(conversation.turnlines);
}

List<TagView> _generateMessageTagViews(model.Message message) {
  List<TagView> tags = [];
  for (var tag in convertTagIdsToTags(message.tagIds, controller.tagIdsToTags)) {
    bool shouldHighlightTag = controller.conversationFilter.filterTagIdsManuallySet[TagFilterType.include].contains(tag.tagId);
    shouldHighlightTag = shouldHighlightTag || controller.conversationFilter.filterTagIdsManuallySet[TagFilterType.lastInboundTurn].contains(tag.tagId);
    tags.add(new MessageTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type), actionsBeforeTagText: message.direction == model.MessageDirection.Out, highlight: shouldHighlightTag));
  }
  for (var tag in convertTagIdsToTags(message.suggestedTagIds, controller.tagIdsToTags)) {
    bool shouldHighlightTag = controller.conversationFilter.filterTagIdsManuallySet[TagFilterType.include].contains(tag.tagId);
    shouldHighlightTag = shouldHighlightTag || controller.conversationFilter.filterTagIdsManuallySet[TagFilterType.lastInboundTurn].contains(tag.tagId);
    tags.add(new SuggestedMessageTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type), actionsBeforeTagText: message.direction == model.MessageDirection.Out, highlight: shouldHighlightTag));
  }
  return tags;
}

MessageView _generateMessageView(model.Message message, model.Conversation conversation) {
  List<TagView> tags = _generateMessageTagViews(message);
  MessageView messageView;
  if (isImagePath(message.text)) {
    messageView = ImageMessageView(
      '',
      message.datetime.toLocal(),
      conversation.docId,
      message.id,
      incoming: message.direction == model.MessageDirection.In,
      tags: tags,
      status: message.status);
    controller.getImageUrl(message.text).then((value) => messageView.text = value);
  } else {
    messageView = new MessageView(
      message.text,
      message.datetime.toLocal(),
      conversation.docId,
      message.id,
      translation: message.translation,
      incoming: message.direction == model.MessageDirection.In,
      tags: tags,
      status: message.status
    );
  }
  messageView.enableEditableTranslations(controller.currentConfig.editTranslationsEnabled);
  return messageView;
}

void _removeFromReplyPanelView(List<String> suggestedReplyIds) {
  for (var replyId in suggestedReplyIds) {
    _view.replyPanelView.remove(replyId);
  }
}

void _populateReplyPanelView(List<model.SuggestedReply> suggestedReplies) {
  Map<String, int> categoryIndexById = {};
  Map<String, String> categoryNameById = {};
  Map<String, int> groupIndexById = {};
  Map<String, String> groupNameById = {};
  suggestedReplies.forEach((reply) {
    categoryIndexById[reply.categoryId] = reply.categoryIndex;
    categoryNameById[reply.categoryId] = reply.categoryName;
    groupIndexById[reply.groupId] = reply.groupIndexInCategory;
    groupNameById[reply.groupId] = reply.groupName;
  });

  var suggestedRepliesByCategoryId = _groupRepliesIntoCategories(suggestedReplies);
  var sortedSuggestedReplyCategoryIds = suggestedRepliesByCategoryId.keys.toList();
  sortedSuggestedReplyCategoryIds.sort((id1, id2) => (categoryIndexById[id1] ?? 0).compareTo(categoryIndexById[id2] ?? 0));

  for (var categoryId in sortedSuggestedReplyCategoryIds) {
    List<ReplyActionGroupView> replyGroupViews = [];
    var suggestedRepliesInCategory = suggestedRepliesByCategoryId[categoryId];
    var suggestedRepliesByGroupId = _groupRepliesIntoGroups(suggestedRepliesInCategory);
    var sortedSuggestedReplyGroupIds = suggestedRepliesByGroupId.keys.toList();
    sortedSuggestedReplyGroupIds.sort((id1, id2) => (groupIndexById[id1] ?? 0).compareTo(groupIndexById[id2] ?? 0));

    for (var groupId in sortedSuggestedReplyGroupIds) {
      List<ReplyActionView> views = [];
      var suggestedRepliesInGroup = suggestedRepliesByGroupId[groupId];
      suggestedRepliesInGroup.sort((r1, r2) => r1.indexInGroup.compareTo(r2.indexInGroup));

      for (var reply in suggestedRepliesInGroup) {
        var replyView = new ReplyActionView(reply.text, reply.translation, reply.shortcut, reply.suggestedReplyId, SEND_REPLY_BUTTON_TEXT, EDIT_REPLY_BUTTON_TEXT);
        replyView.fadeText(controller.activeConversation?.messages?.where((element) => element.text == reply.text)?.isNotEmpty ?? false);
        replyView.showShortcut(controller.currentConfig.repliesKeyboardShortcutsEnabled);
        replyView.showSendButtons(controller.currentConfig.sendMessagesEnabled);
        replyView.showEditButtons(controller.currentConfig.sendMessagesEnabled);
        views.add(replyView);
      }

      var replyGroupView = new ReplyActionGroupView(categoryId, categoryNameById[categoryId], groupId, groupNameById[groupId],  SEND_ALL_BUTTON_TEXT, views);
      replyGroupView.showSendButtons(controller.currentConfig.suggestedRepliesGroupsEnabled);
      replyGroupView.showEditButtons(controller.currentConfig.suggestedRepliesGroupsEnabled);
      replyGroupViews.add(replyGroupView);
    }

    _view.replyPanelView.update(replyGroupViews);
  }
}

void _populateTagPanelView(Map<String, List<model.Tag>> tagsByGroup, bool showShortcut, Set<String> mandatoryExcludeTagIds) {
  _view.tagPanelView.clear();

  var groupNames = (tagsByGroup?.keys ?? []).toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  for (String tagGroupName in groupNames) {
    var tagGroupView = TagGroupView(tagGroupName, tagGroupName, DivElement(), DivElement());
    var tags = tagsByGroup[tagGroupName];
    Map<String, TagView> tagViewsById = {};
    for (model.Tag tag in tags) {
      tagViewsById[tag.docId] = TagView(tag.text, tag.text, selectable: true, shortcut: showShortcut ? tag.shortcut : "", tagStyle: tagTypeToKKStyle(tag.type))
        ..onSelect = () => _view.appController.command(UIAction.addTag, new TagData(tag.tagId));
      if (mandatoryExcludeTagIds != null && mandatoryExcludeTagIds.contains(tag.tagId)) {
        var questionIcon = SpanElement()..className = "fas fa-info";
        var tooltip = Tooltip(questionIcon, "Once you've added this tag, you won't be able to see the conversation anymore due to access restrictions on this tag.", position: TooltipPosition.bottom);
        tooltip.renderElement.classes.add('tag-tooltip');
        tagViewsById[tag.docId].renderElement.append(tooltip.renderElement);
      }
    }
    tagGroupView.addTags(tagViewsById);
    _view.tagPanelView.addTagGroup(tagGroupView);
  }
}

void _removeTagsFromFilterMenu(Map<String, List<model.Tag>> tagsByCategory, TagFilterType filterType) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    for (var tag in tagsByCategory[category]) {
      _view.conversationFilter[filterType].removeMenuTag(new FilterMenuTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type), filterType), category);
    }
  }
}

void _addTagsToFilterMenu(Map<String, List<model.Tag>> tagsByCategory, TagFilterType filterType) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    for (var tag in tagsByCategory[category]) {
      _view.conversationFilter[filterType].addMenuTag(new FilterMenuTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type), filterType), category);
    }
  }
}

void _populateSelectedFilterTags(Set<model.Tag> tags, TagFilterType filterType) {
  _view.conversationFilter[filterType].clearSelectedTags();
  for (var tag in tags) {
    var filterRemovable = _isFilterTagRemovable(tag.tagId, filterType);
    var filterTagViewToAdd = new FilterTagView(tag.text, tag.tagId, tagTypeToKKStyle(tag.type), filterType, deletable: filterRemovable);
    _view.conversationFilter[filterType].addFilterTag(filterTagViewToAdd);
    if (!filterRemovable) {
      var tooltip = HelpIndicatorTooltip("This tag cannot be removed from the filter. Please contact your admin if you have any questions.", TooltipPosition.top);
      filterTagViewToAdd.renderElement.append(tooltip.renderElement);
    }
  }
}

bool _isFilterTagRemovable(String tagId, TagFilterType filterType) {
  switch (filterType) {
    case TagFilterType.include:
      return !(controller.currentConfig.mandatoryIncludeTagIds ?? Set<String>()).contains(tagId);
    case TagFilterType.exclude:
      return !(controller.currentConfig.mandatoryExcludeTagIds ?? Set<String>()).contains(tagId);
    default:
      return true;
  }
}

void _populateTurnlines(List<model.Turnline> turnlines) {
  List<Turnline> turnlineViews = [];
  model.TurnlineStep previousStep;
  for (var turnline in turnlines) {
    var turnlineView = Turnline(turnline.title);
    for (var step in turnline.steps) {
      var stepView = TurnlineStep(step.title, step.done, step.verified);
      List<TagView> tags = [];
      if (step.tagGroupName != null && controller.tagsByGroup.containsKey(step.tagGroupName)) {
        for (var tag in controller.tagsByGroup[step.tagGroupName]) {
          var tagView = new TagView(tag.text, tag.tagId);
          tagView.onSelect = () => _view.appController.command(UIAction.addTag, new TagData(tag.tagId));
          tags.add(tagView);
        }
      }
      stepView.setTags(tags);

      List<DivElement> messages = [];
      if (step.standardMessagesGroupId != null) {
        Map<String, List<model.SuggestedReply>> repliesByGroups = _groupRepliesIntoGroups(controller.suggestedReplies);
        if (repliesByGroups.containsKey(step.standardMessagesGroupId)) {
          var replies = repliesByGroups[step.standardMessagesGroupId];
          for (var reply in replies) {
            var replyView = new ReplyActionView(reply.text, reply.translation, reply.shortcut, reply.suggestedReplyId, SEND_REPLY_BUTTON_TEXT, EDIT_REPLY_BUTTON_TEXT);
            replyView.showShortcut(controller.currentConfig.replies_keyboard_shortcuts_enabled);
            replyView.showSendButtons(controller.currentConfig.sendMessagesEnabled);
            replyView.showEditButtons(controller.currentConfig.sendMessagesEnabled);
            messages.add(replyView.action);
          }
        }
      }
      stepView.setMessages(messages);

      turnlineView.addStep(stepView);
      if ((previousStep?.done == null || previousStep.done)  && !step.done) {
        stepView.open();
      }
      previousStep = step;
    }
    turnlineViews.add(turnlineView);
  }
  _view.turnlinePanelView.turnlines = turnlineViews;
  if (turnlineViews.isNotEmpty) reflowTurnlinesCascade(turnlineViews.first);
}

// This is temporary method until we remove the kk namespace, tag
TagStyle tagTypeToKKStyle(model.TagType tagType) {
  switch (tagType) {
    case model.TagType.important:
      return TagStyle.Important;
    default:
      if (tagType == model.NotFoundTagType.NotFound) {
        return TagStyle.Yellow;
      }
      return TagStyle.None;
  }
}

Map<String, List<model.SuggestedReply>> _groupRepliesIntoCategories(List<model.SuggestedReply> replies) {
  Map<String, List<model.SuggestedReply>> result = {};
  for (model.SuggestedReply reply in replies) {
    String categoryId = reply.categoryId ?? '';
    if (!result.containsKey(categoryId)) {
      result[categoryId] = [];
    }
    result[categoryId].add(reply);
  }
  return result;
}

Map<String, List<model.SuggestedReply>> _groupRepliesIntoGroups(List<model.SuggestedReply> replies) {
  Map<String, List<model.SuggestedReply>> result = {};
  for (model.SuggestedReply reply in replies) {
    // TODO (mariana): once we've transitioned to using groups, we can remove the sequence number fix
    String groupId = reply.groupId ?? '';
    result.putIfAbsent(reply.groupId, () => []);
    result[groupId].add(reply);
  }
  return result;
}

Map<String, List<model.Tag>> _groupTagsIntoCategories(List<model.Tag> tags) {
  Map<String, List<model.Tag>> result = {};
  for (model.Tag tag in tags) {
    if (tag.groups.isEmpty) {
      result.putIfAbsent("", () => []).add(tag);
      continue;
    }
    for (var group in tag.groups) {
      result.putIfAbsent(group, () => []).add(tag);
    }
  }
  // Sort tags alphabetically
  for (var tags in result.values) {
    tags.sort((t1, t2) => t1.text.toLowerCase().compareTo(t2.text.toLowerCase()));
  }
  return result;
}
