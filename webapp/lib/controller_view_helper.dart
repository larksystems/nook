part of controller;

const SEND_REPLY_BUTTON_TEXT = 'SEND message';

const TAG_CONVERSATION_BUTTON_TEXT = 'TAG conversation';
const TAG_MESSAGE_BUTTON_TEXT = 'TAG message';

enum TagReceiver {
  Conversation,
  Message
}

// Functions to populate the views with model objects.

void _populateConversationPanelView(model.Conversation conversation) {
  view.conversationPanelView.clear();
  view.conversationPanelView
    ..deidentifiedPhoneNumber = conversation.deidentifiedPhoneNumber.shortValue
    ..demographicsInfo = conversation.demographicsInfo.values.join(', ');
  for (var tag in conversation.tags) {
    view.conversationPanelView.addTags(new view.TagView(tag.text, tag.tagId));
  }

  for (int i = 0; i < conversation.messages.length; i++) {
    var message = conversation.messages[i];
    List<view.TagView> tags = [];
    for (var tag in message.tags) {
      tags.add(new view.TagView(tag.text, tag.tagId));
    }
    view.conversationPanelView.addMessage(
      new view.MessageView(
        message.text,
        conversation.deidentifiedPhoneNumber.value,
        i,
        translation: message.translation,
        incoming: message.direction == model.MessageDirection.In,
        tags: tags
      ));
  }
}

void _populateReplyPanelView(List<model.SuggestedReply> replies) {
  view.replyPanelView.clear();
  List<String> shortcuts = '1234567890'.split('');
  for (var reply in replies) {
    shortcuts.remove(reply.shortcut);
  }
  String buttonText = SEND_REPLY_BUTTON_TEXT;
  for (var reply in replies) {
    String shortcut = reply.shortcut != null ? reply.shortcut : shortcuts.removeAt(0);
    int replyIndex = replies.indexOf(reply);
    view.replyPanelView.addReply(new view.ReplyActionView(reply.text, shortcut, replyIndex, buttonText));
  }
}

void _populateTagPanelView(List<model.Tag> tags, TagReceiver tagReceiver) {
  view.tagPanelView.clear();
  List<String> shortcuts = 'abcdefghijklmnopqrstuvwxyz'.split('');
  for (var tag in tags) {
    shortcuts.remove(tag.shortcut);
  }
  String buttonText = '';
  switch (tagReceiver) {
    case TagReceiver.Conversation:
      buttonText = TAG_CONVERSATION_BUTTON_TEXT;
      break;
    case TagReceiver.Message:
      buttonText = TAG_MESSAGE_BUTTON_TEXT;
      break;
  }
  for (var tag in tags) {
    String shortcut = tag.shortcut != null ? tag.shortcut : shortcuts.removeAt(0);
    view.tagPanelView.addTag(new view.TagActionView(tag.text, shortcut, tag.tagId, buttonText));
  }
}
