part of controller;

void _addMessagesToView(Map<String, MessageCategory> messagesByGroupByCategory, {bool startEditingName = false}) {
  for (var categoryId in messagesByGroupByCategory.keys.toList()) {
    if (_view.categories.queryItem(categoryId) == null) {
      var categoryName = messagesByGroupByCategory[categoryId].categoryName;
      _view.addCategory(categoryId, new StandardMessagesCategoryView(categoryId, categoryName, DivElement(), DivElement()));
      if (startEditingName) {
        _view.categoriesById[categoryId].expand();
        _view.categoriesById[categoryId].editableTitle.beginEdit(selectAllOnFocus: true);
      }
    }
    var categoryView = _view.categoriesById[categoryId];
    int groupIndex = 0;
    for (var groupId in messagesByGroupByCategory[categoryId].groups.keys.toList()..sort()) {
      if (categoryView.groups.queryItem(groupId) == null) {
        var categoryName = messagesByGroupByCategory[categoryId].categoryName;
        var groupName = messagesByGroupByCategory[categoryId].groups[groupId].groupName;
        categoryView.addGroup(groupId, new StandardMessagesGroupView(categoryId, categoryName, groupId, groupName, DivElement(), DivElement()), groupIndex);
        if (startEditingName) {
          categoryView.groupsById[groupId].expand();
          categoryView.groupsById[groupId].editableTitle.beginEdit(selectAllOnFocus: true);
        }
      }
      var groupView = categoryView.groupsById[groupId];
      for (var message in messagesByGroupByCategory[categoryId].groups[groupId].messages.values) {
        groupView.addMessage(message.suggestedReplyId, new StandardMessageView(message.suggestedReplyId, message.text, message.translation));
      }
      groupIndex++;
    }
  }
}

void _removeMessagesFromView(Map<String, MessageCategory> messagesByGroupByCategory) {
  for (var categoryId in messagesByGroupByCategory.keys.toList()) {
    var categoryView = _view.categoriesById[categoryId];
    for (var groupId in messagesByGroupByCategory[categoryId].groups.keys.toList()) {
      var groupView = categoryView.groupsById[groupId];
      for (var message in messagesByGroupByCategory[categoryId].groups[groupId].messages.values) {
        groupView.removeMessage(message.suggestedReplyId);
      }
    }
  }
}

void _modifyMessagesInView(Map<String, MessageCategory> messagesByGroupByCategory) {
  for (var categoryId in messagesByGroupByCategory.keys.toList()) {
    var categoryView = _view.categoriesById[categoryId];
    for (var groupId in messagesByGroupByCategory[categoryId].groups.keys.toList()) {
      var groupView = categoryView.groupsById[groupId];
      for (var message in messagesByGroupByCategory[categoryId].groups[groupId].messages.values) {
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

Map<String, MessageCategory> _groupMessagesIntoCategoriesAndGroups(List<model.SuggestedReply> messages) {
  Map<String, MessageCategory> result = {};
  for (model.SuggestedReply message in messages) {
    result.putIfAbsent(message.categoryId, () => MessageCategory(message.categoryId, message.category));
    result[message.categoryId].groups.putIfAbsent(message.groupId, () => MessageGroup(message.groupId, message.groupDescription));
    result[message.categoryId].groups[message.groupId].messages.putIfAbsent(message.docId, () => message);
  }
  // todo: bring back the sequence number
  for (String category in result.keys) {
    for (String group in result[category].groups.keys) {
      // TODO (mariana): once we've transitioned to using groups, we can remove the sequence number comparison
      result[category].groups[group].messages.values.toList().sort((message1, message2) => (message1.indexInGroup ?? message1.seqNumber).compareTo(message2.indexInGroup ?? message2.seqNumber));
    }
  }
  return result;
}
