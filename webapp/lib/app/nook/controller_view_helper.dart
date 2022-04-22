part of controller;

const SEND_REPLY_BUTTON_TEXT = 'SEND';
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
  _view.conversationPanelView.updateDateSeparators();
  _populateTurnlines(conversation.turnlines);
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
  var messageView = new MessageView(
      message.text,
      message.datetime.toLocal(),
      conversation.docId,
      message.id,
      translation: message.translation,
      incoming: message.direction == model.MessageDirection.In,
      tags: tags,
      status: message.status
    );
  messageView.enableEditableTranslations(controller.currentConfig.editTranslationsEnabled);
  return messageView;
}

AccordionItem _transformCategoryToAccordionItem(MessageCategory category) {
  var groupsContainer = DivElement();
  var viewItem = AccordionItem(category.categoryId, DivElement()..innerText = category.categoryName, groupsContainer, false);
  var groups = category.groups.values.toList()..sort((g1, g2) => g1.groupIndexInCategory.compareTo(g2.groupIndexInCategory));
  for (var group in groups) {
    List<ReplyActionView> messageViews = [];
    var groupMessages = group.standardMessages.toList()..sort((m1, m2) => m1.indexInGroup.compareTo(m2.indexInGroup));
    for (var standardMessage in groupMessages) {
      var messageView = ReplyActionView(standardMessage.text, standardMessage.translation, standardMessage.shortcut, standardMessage.docId, SEND_REPLY_BUTTON_TEXT);
      messageView.showShortcut(controller.currentConfig.repliesKeyboardShortcutsEnabled);
      messageView.showButtons(controller.currentConfig.sendMessagesEnabled);
      messageViews.add(messageView);
    }
    var groupView = ReplyActionGroupView(group.groupId, group.groupName, SEND_REPLY_BUTTON_TEXT, messageViews); 
    groupView.showButtons(controller.currentConfig.sendMessagesEnabled);
    groupsContainer.append(groupView.action);
  }
  return viewItem;
}

void _populateReplyPanelView(List<model.SuggestedReply> suggestedReplies, List<MessageCategory> panelCategoryItems) {
  Map<String, MessageCategory> groupedMessages = {};
  for (var reply in suggestedReplies) {
    groupedMessages[reply.categoryId] = groupedMessages[reply.categoryId] 
      ?? MessageCategory(reply.categoryId, reply.categoryName, reply.categoryIndex, {});
    groupedMessages[reply.categoryId].groups[reply.groupId] = groupedMessages[reply.categoryId].groups[reply.groupId]
      ?? MessageGroup(reply.categoryId, reply.groupId, reply.groupName,reply.groupIndexInCategory, []);
    groupedMessages[reply.categoryId].groups[reply.groupId].standardMessages.add(reply);
  }

  List<MessageCategory> newCategoryItems = groupedMessages.values.toList()
    ..sort((c1, c2) => c1.categoryIndex.compareTo(c2.categoryIndex));

  for (var newCategory in newCategoryItems) {
    var panelViewIndex = panelCategoryItems.indexWhere((element) => element.categoryId == newCategory.categoryId);
    // todo: categoryIndex might have changed, think about it when we merge the sorting feature
    if (panelViewIndex < 0) { // newly added category, add to model, view
      panelCategoryItems.add(newCategory);
      var viewItem = _transformCategoryToAccordionItem(newCategory);
      _view.standardMessagesPanelView.add(viewItem);
    } else { // updated category, update model, view
      var panelCategory = panelCategoryItems[panelViewIndex];
      if (!panelCategory.equals(newCategory)) {
        panelCategoryItems[panelViewIndex] = newCategory;
        var viewItem = _transformCategoryToAccordionItem(newCategory);
        _view.standardMessagesPanelView.update(viewItem);
      }
    }
  }

  for (var panelCategoryItem in panelCategoryItems) { 
    var newCategoryIndex = newCategoryItems.indexWhere((element) => element.categoryId == panelCategoryItem.categoryId);
    if (newCategoryIndex < 0) { // deleted category, remove from model, view
      panelCategoryItems.remove(panelCategoryItem); // question: is this recommended?
      _view.standardMessagesPanelView.remove(panelCategoryItem.categoryId);
    }
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
      tagViewsById[tag.docId] = TagView(tag.text, tag.text, selectable: true, shortcut: showShortcut ? tag.shortcut : "")
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
            var replyView = new ReplyActionView(reply.text, reply.translation, reply.shortcut, reply.suggestedReplyId, 'SEND');
            replyView.showShortcut(controller.currentConfig.replies_keyboard_shortcuts_enabled);
            replyView.showButtons(controller.currentConfig.sendMessagesEnabled);
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
    String groupId = controller.currentConfig.suggestedRepliesGroupsEnabled ?
        reply.groupId ?? reply.seqNumber.toString() :
        reply.seqNumber.toString();
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

class MessageGroup {
  String categoryId;
  String groupId;
  String groupName;
  int groupIndexInCategory;
  List<model.SuggestedReply> standardMessages;

  MessageGroup(this.categoryId, this.groupId, this.groupName, this.groupIndexInCategory, this.standardMessages);

  bool equals(MessageGroup other) {
    if (categoryId != other.categoryId || groupId != other.groupId || groupName != other.groupName || groupIndexInCategory != other.groupIndexInCategory) {
      return false;
    }

    if (standardMessages.length != other.standardMessages.length) {
      return false;
    }

    var currentMessagesList = standardMessages..sort((m1, m2) => m1.indexInGroup.compareTo(m2.indexInGroup));
    var otherMessagesList = other.standardMessages..sort((m1, m2) => m1.indexInGroup.compareTo(m2.indexInGroup));

    for (var i = 0; i < currentMessagesList.length; ++i) {
      if (!currentMessagesList[i].equals(otherMessagesList[i])) {
        return false;
      }
    }

    return true;
  }
}

class MessageCategory {
  String categoryId;
  String categoryName;
  int categoryIndex;
  Map<String, MessageGroup> groups;

  MessageCategory(this.categoryId, this.categoryName, this.categoryIndex, this.groups);

  bool equals(MessageCategory other) {
    if (categoryId != other.categoryId || categoryName != other.categoryName || categoryIndex != other.categoryIndex) {
      return false;
    }

    if (groups.length != other.groups.length) {
      return false;
    }

    var currentGroupsList = groups.values.toList()..sort((g1, g2) => g1.groupIndexInCategory.compareTo(g2.groupIndexInCategory));
    var otherGroupsList = other.groups.values.toList()..sort((g1, g2) => g1.groupIndexInCategory.compareTo(g2.groupIndexInCategory));

    for (var i = 0; i < currentGroupsList.length; ++i) {
      if (!currentGroupsList[i].equals(otherGroupsList[i])) {
        return false;
      }
    }

    return true;
  }
}
