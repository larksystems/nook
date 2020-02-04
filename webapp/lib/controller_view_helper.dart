part of controller;

const SEND_REPLY_BUTTON_TEXT = 'SEND';

const TAG_CONVERSATION_BUTTON_TEXT = 'TAG';
const TAG_MESSAGE_BUTTON_TEXT = 'TAG';

enum TagReceiver {
  Conversation,
  Message
}

// Functions to populate the views with model objects.

void _populateConversationListPanelView(Set<model.Conversation> conversations) {
  view.conversationListPanelView.clearConversationList();
  if (conversations.isNotEmpty) {
    view.conversationListPanelView.hideLoadSpinner();
    for (var conversation in conversations) {
      view.conversationListPanelView.addConversation(
          new view.ConversationSummary(
              conversation.deidentifiedPhoneNumber.value,
              conversation.messages.first.text,
              conversation.unread)
      );
    }
  }
}

void _populateConversationPanelView(model.Conversation conversation) {
  view.conversationPanelView.clear();
  view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.deidentifiedPhoneNumber.value
    ..deidentifiedPhoneNumberShort = conversation.deidentifiedPhoneNumber.shortValue
    ..demographicsInfo = conversation.demographicsInfo.values.join(', ');
  for (var tag in model.tagIdsToTags(conversation.tagIds, conversationTags)) {
    view.conversationPanelView.addTags(new view.ConversationTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
  }

  for (int i = 0; i < conversation.messages.length; i++) {
    var message = conversation.messages[i];
    List<view.TagView> tags = [];
    for (var tag in model.tagIdsToTags(message.tagIds, messageTags)) {
      tags.add(new view.MessageTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type)));
    }
    view.conversationPanelView.addMessage(
      new view.MessageView(
        message.text,
        message.datetime,
        conversation.deidentifiedPhoneNumber.value,
        i,
        translation: message.translation,
        incoming: message.direction == model.MessageDirection.In,
        tags: tags
      ));
  }
}

void _populateReplyPanelView(List<model.SuggestedReply> replies) {
  replies.sort((r1, r2) => r1.shortcut.compareTo(r2.shortcut));
  view.replyPanelView.clear();
  String buttonText = SEND_REPLY_BUTTON_TEXT;
  for (var reply in replies) {
    int replyIndex = replies.indexOf(reply);
    view.replyPanelView.addReply(new view.ReplyActionView(reply.text, reply.translation, reply.shortcut, replyIndex, buttonText));
  }
}

void _populateTagPanelView(List<model.Tag> tags, TagReceiver tagReceiver) {
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
    view.tagPanelView.addTag(new view.TagActionView(tag.text, tag.shortcut, tag.tagId, buttonText));
  }
}

void _populateFilterTagsMenu(List<model.Tag> tags, FilterType filterType) {
  view.ConversationFilterView conversationFilterView = filterType == FilterType.include ? view.conversationIncludeFilter : view.conversationExcludeFilter;
  conversationFilterView.clearMenuTags();
  for (var tag in tags) {
    conversationFilterView.addMenuTag(new view.FilterMenuTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), filterType));
  }
  conversationFilterView.addMenuTag(view.AfterDateFilterMenuTagView(filterType));
}

void _populateSelectedFilterTags(ConversationFilter conversationFilter) {
  view.conversationIncludeFilter.clearSelectedTags();
  for (var tag in conversationFilter.includeTags) {
    view.conversationIncludeFilter.addFilterTag(new view.FilterTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), FilterType.include));
  }

  view.conversationExcludeFilter.clearSelectedTags();
  for (var tag in conversationFilter.excludeTags) {
    view.conversationExcludeFilter.addFilterTag(new view.FilterTagView(tag.text, tag.tagId, tagTypeToStyle(tag.type), FilterType.exclude));
  }
}

view.TagStyle tagTypeToStyle(model.TagType tagType) {
  switch (tagType) {
    case model.TagType.Important:
      return view.TagStyle.Important;
    default:
      return view.TagStyle.None;
  }
}
