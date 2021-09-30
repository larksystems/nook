part of controller;

void _addMessagesToView(Map<String, Map<String, List<model.SuggestedReply>>> messagesByGroupByCategory) {
  for (var category in messagesByGroupByCategory.keys.toList()) {
    if (_view.categories.queryItem(category) == null) {
      _view.addCategory(category, new StandardMessagesCategoryView(category, DivElement(), DivElement()));
    }
    var categoryView = _view.categoriesByName[category];
    int groupIndex = 0;
    for (var group in messagesByGroupByCategory[category].keys.toList()..sort()) {
      if (categoryView.groups.queryItem(group) == null) {
        categoryView.addGroup(group, new StandardMessagesGroupView(category, group, DivElement(), DivElement()), groupIndex);
      }
      var groupView = categoryView.groupsByName[group];
      for (var message in messagesByGroupByCategory[category][group]) {
        groupView.addMessage(message.suggestedReplyId, new StandardMessageView(message.suggestedReplyId, message.text, message.translation));
      }
      groupIndex++;
    }
  }
}

void _removeMessagesFromView(Map<String, Map<String, List<model.SuggestedReply>>> messagesByGroupByCategory) {
  for (var category in messagesByGroupByCategory.keys.toList()) {
    var categoryView = _view.categoriesByName[category];
    for (var group in messagesByGroupByCategory[category].keys.toList()) {
      var groupView = categoryView.groupsByName[group];
      for (var message in messagesByGroupByCategory[category][group]) {
        groupView.removeMessage(message.suggestedReplyId);
      }
    }
  }
}

void _modifyMessagesInView(Map<String, Map<String, List<model.SuggestedReply>>> messagesByGroupByCategory) {
  for (var category in messagesByGroupByCategory.keys.toList()) {
    var categoryView = _view.categoriesByName[category];
    for (var group in messagesByGroupByCategory[category].keys.toList()) {
      var groupView = categoryView.groupsByName[group];
      for (var message in messagesByGroupByCategory[category][group]) {
        groupView.modifyMessage(message.suggestedReplyId, new StandardMessageView(message.suggestedReplyId, message.text, message.translation));
      }
    }
  }
}

Map<String, Map<String, List<model.SuggestedReply>>> _groupMessagesIntoCategoriesAndGroups(List<model.SuggestedReply> messages) {
  Map<String, Map<String, List<model.SuggestedReply>>> result = {};
  for (model.SuggestedReply message in messages) {
    result.putIfAbsent(message.category, () => {});
    result[message.category].putIfAbsent(message.groupDescription, () => []);
    result[message.category][message.groupDescription].add(message);
  }
  for (String category in result.keys) {
    for (String group in result[category].keys) {
      // TODO (mariana): once we've transitioned to using groups, we can remove the sequence number comparison
      result[category][group].sort((message1, message2) => (message1.indexInGroup ?? message1.seqNumber).compareTo(message2.indexInGroup ?? message2.seqNumber));
    }
  }
  return result;
}
