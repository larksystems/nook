part of controller;

void _addMessagesToView(Map<String, Map<String, List<model.SuggestedReply>>> messagesByGroupByCategory, {bool startEditingName = false}) {
  for (var categoryId in messagesByGroupByCategory.keys.toList()) {
    if (_view.categories.queryItem(categoryId) == null) {
      _view.addCategory(categoryId, new StandardMessagesCategoryView(categoryId, "asd", DivElement(), DivElement())); // todo: implication of this?
      if (startEditingName) {
        _view.categoriesById[categoryId].expand();
        _view.categoriesById[categoryId].editableTitle.beginEdit(selectAllOnFocus: true);
      }
    }
    var categoryView = _view.categoriesById[categoryId];
    int groupIndex = 0;
    for (var groupId in messagesByGroupByCategory[categoryId].keys.toList()..sort()) {
      if (categoryView.groups.queryItem(groupId) == null) {
        categoryView.addGroup(groupId, new StandardMessagesGroupView(categoryId, 'asd', groupId, 'dsa', DivElement(), DivElement()), groupIndex); // todo: implication of this?
        if (startEditingName) {
          categoryView.groupsById[groupId].expand();
          categoryView.groupsById[groupId].editableTitle.beginEdit(selectAllOnFocus: true);
        }
      }
      var groupView = categoryView.groupsById[groupId];
      for (var message in messagesByGroupByCategory[categoryId][groupId]) {
        groupView.addMessage(message.suggestedReplyId, new StandardMessageView(message.suggestedReplyId, message.text, message.translation));
      }
      groupIndex++;
    }
  }
}

void _removeMessagesFromView(Map<String, Map<String, List<model.SuggestedReply>>> messagesByGroupByCategory) {
  for (var categoryId in messagesByGroupByCategory.keys.toList()) {
    var categoryView = _view.categoriesById[categoryId];
    for (var groupId in messagesByGroupByCategory[categoryId].keys.toList()) {
      var groupView = categoryView.groupsById[groupId];
      for (var message in messagesByGroupByCategory[categoryId][groupId]) {
        groupView.removeMessage(message.suggestedReplyId);
      }
    }
  }
}

void _modifyMessagesInView(Map<String, Map<String, List<model.SuggestedReply>>> messagesByGroupByCategory) {
  for (var categoryId in messagesByGroupByCategory.keys.toList()) {
    var categoryView = _view.categoriesById[categoryId];
    for (var groupId in messagesByGroupByCategory[categoryId].keys.toList()) {
      var groupView = categoryView.groupsById[groupId];
      for (var message in messagesByGroupByCategory[categoryId][groupId]) {
        var messageView = new StandardMessageView(message.suggestedReplyId, message.text, message.translation);
        groupView.modifyMessage(message.suggestedReplyId, messageView);
      }
    }
  }
}

void _updateUnsavedIndicators(Map<String, MessageCategory> categories, Set<String> unsavedMessageIds, Set<String> unsavedGroupIds, Set<String> unsavedCategoryIds) {
  for (var categoryId in categories.keys) {
    var categoryView = _view.categoriesById[categoryId];
    categoryView.markAsUnsaved(unsavedCategoryIds.contains(categoryId));

    for (var groupId in categories[categoryId].groups.keys) {
      var groupView = categoryView.groupsById[groupId];
      groupView.markAsUnsaved(unsavedGroupIds.contains(groupId));

      for (var messageId in categories[categoryId].groups[groupId].messages.keys) {
        var messageView = groupView.messagesById[messageId];
        messageView.markAsUnsaved(unsavedMessageIds.contains(messageId));
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
