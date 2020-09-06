part of controller;

const SEND_REPLY_BUTTON_TEXT = 'SEND';

const TAG_CONVERSATION_BUTTON_TEXT = 'TAG';
const TAG_MESSAGE_BUTTON_TEXT = 'TAG';

const SMS_MAX_LENGTH = 160;

enum TagReceiver {
  Conversation,
  Message
}

enum SnackbarNotificationType {
  info,
  success,
  warning,
  error
}

// Functions to populate the views with model objects.

void _populateConversationListPanelView(Set<model.Conversation> conversations, bool updateList) {
  view.conversationListPanelView.hideLoadSpinner();
  view.conversationListPanelView.hideSelectConversationListMessage();
  if (conversations.isEmpty || !updateList) {
    view.conversationListPanelView.clearConversationList();
  }
  view.conversationListPanelView.updateConversationList(conversations);
}

void _populateConversationPanelView(model.Conversation conversation, {bool updateInPlace: false}) {
  if (updateInPlace) {
    _updateConversationPanelView(conversation);
    return;
  }
  view.conversationPanelView.clear();
  view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.docId
    ..deidentifiedPhoneNumberShort = conversation.shortDeidentifiedPhoneNumber
    ..demographicsInfo = conversation.demographicsInfo.values.join(', ');
  for (var tag in tagIdsToTags(conversation.tagIds, conversationTagIdsToTags)) {
    view.conversationPanelView.addTags(new view.ConversationTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
  }

  for (var message in conversation.messages) {
    view.MessageView messageView = _generateMessageView(message, conversation);
    view.conversationPanelView.addMessage(messageView);
  }
}

void _updateConversationPanelView(model.Conversation conversation) {
  view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.docId
    ..deidentifiedPhoneNumberShort = conversation.shortDeidentifiedPhoneNumber
    ..demographicsInfo = conversation.demographicsInfo.values.join(', ');
  view.conversationPanelView.removeTags();
  for (var tag in tagIdsToTags(conversation.tagIds, conversationTagIdsToTags)) {
    view.conversationPanelView.addTags(new view.ConversationTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
  }

  view.conversationPanelView.padOrTrimMessageViews(conversation.messages.length);
  for (int i = 0; i < conversation.messages.length; i++) {
    view.MessageView messageView = _generateMessageView(conversation.messages[i], conversation);
    view.conversationPanelView.updateMessage(messageView, i);
  }
}

view.MessageView _generateMessageView(model.Message message, model.Conversation conversation) {
  List<view.TagView> tags = [];
  for (var tag in tagIdsToTags(message.tagIds, messageTagIdsToTags)) {
    tags.add(new view.MessageTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
  }
  var messageView = new view.MessageView(
      message.text,
      message.datetime,
      conversation.docId,
      conversation.messages.indexOf(message),
      translation: message.translation,
      incoming: message.direction == model.MessageDirection.In,
      tags: tags,
      status: message.status
    );
  messageView.enableEditableTranslations(currentConfig.editTranslationsEnabled);
  return messageView;
}

void _populateReplyPanelView(List<model.SuggestedReply> replies) {
  replies.sort((r1, r2) {
    if (r1.seqNumber == null && r2.seqNumber == null) {
      return r1.shortcut.compareTo(r2.shortcut);
    }
    var seqNo1 = r1.seqNumber == null ? double.nan : r1.seqNumber;
    var seqNo2 = r2.seqNumber == null ? double.nan : r2.seqNumber;
    return seqNo1.compareTo(seqNo2);
  });
  view.replyPanelView.clear();
  String buttonText = SEND_REPLY_BUTTON_TEXT;
  for (var reply in replies) {
    int replyIndex = replies.indexOf(reply);
    var replyView = new view.ReplyActionView(reply.text, reply.translation, reply.shortcut, replyIndex, buttonText);
    replyView.showShortcut(currentConfig.repliesKeyboardShortcutsEnabled);
    replyView.showButtons(currentConfig.sendMessagesEnabled);
    view.replyPanelView.addReply(replyView);
  }
}

void _populateTagPanelView(List<model.Tag> tags, TagReceiver tagReceiver) {
  tags = _filterDemogsTagsIfNeeded(tags);
  view.tagPanelView.clear();
  String buttonText = '';
  switch (tagReceiver) {
    case TagReceiver.Conversation:
      buttonText = TAG_CONVERSATION_BUTTON_TEXT;
      break;
    case TagReceiver.Message:
      buttonText = TAG_MESSAGE_BUTTON_TEXT;
      break;
  }

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
    var tagView = new view.TagActionView(tag.text, tag.shortcut, tag.tagId, buttonText);
    tagView.showShortcut(currentConfig.tagsKeyboardShortcutsEnabled);
    switch (tagReceiver) {
      case TagReceiver.Conversation:
        tagView.showButtons(currentConfig.tagConversationsEnabled);
        break;
      case TagReceiver.Message:
        tagView.showButtons(currentConfig.tagMessagesEnabled);
        break;
    }
    view.tagPanelView.addTag(tagView);
  }
}

void _removeTagsFromFilterMenu(Map<String, List<model.Tag>> tagsByCategory, TagFilterType filterType) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    for (var tag in tagsByCategory[category]) {
      view.conversationFilter[filterType].removeMenuTag(new view.FilterMenuTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), filterType), category);
    }
  }
}

void _addTagsToFilterMenu(Map<String, List<model.Tag>> tagsByCategory, TagFilterType filterType) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    for (var tag in tagsByCategory[category]) {
      view.conversationFilter[filterType].addMenuTag(new view.FilterMenuTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), filterType), category);
    }
  }
}

void _modifyTagsInFilterMenu(Map<String, List<model.Tag>> tagsByCategory, TagFilterType filterType) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    for (var tag in tagsByCategory[category]) {
      view.conversationFilter[filterType].modifyMenuTag(new view.FilterMenuTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), filterType), category);
    }
  }
}

void _addDateTagToFilterMenu(TagFilterType filterType) {
  view.conversationFilter[filterType].addMenuTag(view.AfterDateFilterMenuTagView(filterType), "Date");
}

void _populateSelectedFilterTags(Set<model.Tag> tags, TagFilterType filterType) {
  view.conversationFilter[filterType].clearSelectedTags();
  for (var tag in tags) {
    view.conversationFilter[filterType].addFilterTag(new view.FilterTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), filterType));
  }
}

void _populateSelectedAfterDateFilterTag(DateTime afterDateFilter, TagFilterType filterType) {
  view.conversationFilter[filterType].removeFilterTag(view.AFTER_DATE_TAG_ID);
  if (afterDateFilter != null) {
    view.conversationFilter[filterType].addFilterTag(new view.AfterDateFilterTagView(afterDateFilter, filterType));
  }
}

view.TagStyle tagTypeToStyle(model.TagType tagType) {
  switch (tagType) {
    case model.TagType.Important:
      return view.TagStyle.Important;
    default:
      if (tagType == model.NotFoundTagType.NotFound) {
        return view.TagStyle.Yellow;
      }
      return view.TagStyle.None;
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
    tags.sort((t1, t2) => t1.text.compareTo(t2.text));
  }
  return result;
}
