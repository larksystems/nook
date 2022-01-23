part of controller;

void _addMessagesToView(Map<String, MessageCategory> messagesByGroupByCategory, {bool startEditingName = false}) {
  var categories = messagesByGroupByCategory.values.toList();
  categories.sort((c1, c2) => c1.categoryIndex.compareTo(c2.categoryIndex));
  List<String> categoryIds = categories.map((c) => c.categoryId).toList();
  for (var categoryId in categoryIds) {
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

    var groups = messagesByGroupByCategory[categoryId].groups.values.toList();
    groups.sort((g1, g2) => g1.groupIndexInCategory.compareTo(g2.groupIndexInCategory));
    List<String> groupIds = groups.map((g) => g.groupId).toList();
    for (var groupId in groupIds) {
      if (categoryView.groups.queryItem(groupId) == null) {
        var groupName = messagesByGroupByCategory[categoryId].groups[groupId].groupName;
        categoryView.addGroup(groupId, new StandardMessagesGroupView(categoryId, groupId, groupName, DivElement(), DivElement()), groupIndex);
        if (startEditingName) {
          categoryView.groupsById[groupId].expand();
          categoryView.groupsById[groupId].editableTitle.beginEdit(selectAllOnFocus: true);
        }
      }
      var groupView = categoryView.groupsById[groupId];
      
      var messages = messagesByGroupByCategory[categoryId].groups[groupId].messages.values.toList();
      messages.sort((m1, m2) => m1.indexInGroup.compareTo(m2.indexInGroup));
      for (var message in messages) {
        groupView.addMessage(message.suggestedReplyId, new StandardMessageView(message.suggestedReplyId, message.text, message.translation));
      }
      groupIndex++;
    }
  }
}

void _removeMessagesFromView(List<model.SuggestedReply> messages) {
  for (var message in messages) {
    var groupView = _view.categoriesById[message.categoryId].groupsById[message.groupId];
    groupView.removeMessage(message.suggestedReplyId);
  }
}

void _modifyMessagesInView(List<model.SuggestedReply> messages) {
  for (var message in messages) {
    var groupView = _view.categoriesById[message.categoryId].groupsById[message.groupId];
    var messageView = new StandardMessageView(message.suggestedReplyId, message.text, message.translation);
    groupView.modifyMessage(message.suggestedReplyId, messageView);
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
    result.putIfAbsent(message.categoryId, () => MessageCategory(message.categoryId, message.category, message.categoryIndex));
    result[message.categoryId].groups.putIfAbsent(message.groupId, () => MessageGroup(message.groupId, message.groupName, message.groupIndexInCategory));
    result[message.categoryId].groups[message.groupId].messages.putIfAbsent(message.docId, () => message);
  }
  for (String category in result.keys) {
    for (String group in result[category].groups.keys) {
      result[category].groups[group].messages.values.toList().sort((message1, message2) => (message1.indexInGroup).compareTo(message2.indexInGroup));
    }
  }
  return result;
}
