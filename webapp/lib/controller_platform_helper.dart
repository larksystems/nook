part of controller;

// Platform data structures to web model convertors

Future<List<model.Conversation>> _conversationsFromPlatformData(Future conversationsFuture) async {
  var conversations = await conversationsFuture;
  return conversations;
}

Future<List<model.SuggestedReply>> _suggestedRepliesFromPlatformData(Future suggestedRepliesFuture) async {
  var suggestedReplies = await suggestedRepliesFuture;
  return suggestedReplies;
}

Future<List<model.Tag>> _conversationTagsFromPlatformData(Future conversationTags) async {
  var tags = await conversationTags;
  return tags;
}

Future<List<model.Tag>> _messageTagsFromPlatformData(Future messageTags) async {
  var tags = await messageTags;
  return tags;
}

// Web model to platform data structures convertors

Map encodeConversationToPlatformData(model.Conversation conversation) {
  // TODO(mariana): implement encodeConversationToPlatformData
  return null;
}
