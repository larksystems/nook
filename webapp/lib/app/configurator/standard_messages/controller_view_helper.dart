part of controller;

void _populateStandardMessagesConfigPage(List<model.SuggestedReply> messages) {
  Map<String, List<model.SuggestedReply>> messagesByGroups = _groupMessagesIntoGroups(messages);
  _view.clear();
  for (var groupId in messagesByGroups.keys) {
    var messagesInGroup = messagesByGroups[groupId];
    if (messagesInGroup.isEmpty) continue;
    var groupDescription = messagesInGroup.first.groupDescription;
    StandardMessagesGroupView group = new StandardMessagesGroupView(groupId, groupDescription);
    for (var message in messagesInGroup) {
      var messageView = new StandardMessageView(message.docId, message.text, message.translation);
      group.addMessage(message.docId, messageView);
    }
    _view.addGroup(groupId, group);
  }
}

Map<String, List<model.SuggestedReply>> _groupMessagesIntoGroups(List<model.SuggestedReply> messages) {
  Map<String, List<model.SuggestedReply>> result = {};
  for (model.SuggestedReply message in messages) {
    if (!result.containsKey(message.groupId)) {
      result[message.groupId] = [];
    }
    result[message.groupId].add(message);
  }
  for (String groupId in result.keys) {
    // TODO (mariana): once we've transitioned to using groups, we can remove the sequence number comparison
    result[groupId].sort((message1, message2) => (message1.indexInGroup ?? message1.seqNumber).compareTo(message2.indexInGroup ?? message2.seqNumber));
  }
  return result;
}
