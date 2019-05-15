import 'mock_data.dart' as data;
import 'model.dart';

List<Conversation> loadConversations() {
  return data.conversations;
}

List<Tag> loadConversationTags() {
  return data.conversationTags;
}

List<Tag> loadMessageTags() {
  return data.messageTags;
}

List<SuggestedReply> loadSuggestedReplies() {
  return data.suggestedReplies;
}

void updateConversation(Conversation conversation) {
  // TODO(mariana): implement saving the updated conversation
}
