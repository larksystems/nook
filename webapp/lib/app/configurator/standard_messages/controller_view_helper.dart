part of controller;

void _addMessagesToView(Map<String, Map<String, List<model.SuggestedReply>>> messagesByGroupByCategory, {bool startEditingName = false}) {
  for (var category in messagesByGroupByCategory.keys.toList()) {
    if (_view.categories.queryItem(category) == null) {
      _view.addCategory(category, new StandardMessagesCategoryView(category, DivElement(), DivElement()));
      if (startEditingName) {
        _view.categoriesByName[category].expand();
        _view.categoriesByName[category].editableTitle.beginEdit(selectAllOnFocus: true);
      }
    }
    var categoryView = _view.categoriesByName[category];
    int groupIndex = 0;
    for (var group in messagesByGroupByCategory[category].keys.toList()..sort()) {
      if (categoryView.groups.queryItem(group) == null) {
        categoryView.addGroup(group, new StandardMessagesGroupView(category, group, DivElement(), DivElement()), groupIndex);
        if (startEditingName) {
          categoryView.groupsByName[group].expand();
          categoryView.groupsByName[group].editableTitle.beginEdit(selectAllOnFocus: true);
        }
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
        var messageView = new StandardMessageView(message.suggestedReplyId, message.text, message.translation);
        groupView.modifyMessage(message.suggestedReplyId, messageView);
        messageView.markAsUnsaved(true);
      }
    }
  }
}

void _updateUnsavedIndicators(Map<String, MessageCategory> categories, Set<String> unsavedMessageIds, Set<String> unsavedGroupIds, Set<String> unsavedCategoryIds) {
  for (var category in categories.keys) {
    var categoryView = _view.categoriesByName[category];
    categoryView.markAsUnsaved(unsavedCategoryIds.contains(category));

    for (var group in categories[category].groups.keys) {
      var groupView = categoryView.groupsByName[group];
      groupView.markAsUnsaved(unsavedGroupIds.contains(group));

      for (var message in categories[category].groups[group].messages.keys) {
        var messageView = groupView.messagesById[message];
        messageView.markAsUnsaved(unsavedMessageIds.contains(message));
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
