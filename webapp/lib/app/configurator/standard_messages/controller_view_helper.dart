part of controller;

void _addMessagesToView(Map<String, MessageCategory> messagesByGroupByCategory, {bool startEditingName = false}) {
  var categories = messagesByGroupByCategory.values.toList();
  // todo: remove ?? check when we have the guarantee that the categoryIndex is always present
  categories.sort((c1, c2) => (c1.categoryIndex ?? 0).compareTo(c2.categoryIndex ?? 0));
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

    var groups = messagesByGroupByCategory[categoryId].groups.values.toList();
    // todo: remove ?? check when we have the guarantee that the groupIndex is always present
    groups.sort((g1, g2) => (g1.groupIndexInCategory ?? 0).compareTo(g2.groupIndexInCategory ?? 0));
    List<String> groupIds = groups.map((g) => g.groupId).toList();
    for (var groupId in groupIds) {
      if (categoryView.groups.queryItem(groupId) == null) {
        var group = messagesByGroupByCategory[categoryId].groups[groupId];
        categoryView.addGroup(groupId, new StandardMessagesGroupView(categoryId, groupId, group.groupName, DivElement(), DivElement()), group.groupIndexInCategory);
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
    var categoryView = _view.categoriesById[message.categoryId];
    var groupView = categoryView.groupsById[message.groupId];
    var messageView = groupView.messagesById[message.docId];
    messageView.updateText(message.text);
    messageView.updateTranslation(message.translation);
    groupView.modifyMessage(message.suggestedReplyId, messageView);
    
    categoryView.updateName(message.categoryName);
    groupView.updateName(message.groupName);
  }
}

void _updateUnsavedIndicators(Map<String, MessageCategory> categories, Set<String> unsavedMessageTextIds, Set<String> unsavedMessageTranslationIds, Set<String> renamedGroupIds, Set<String> unsavedGroupIds, Set<String> renamedCategoryIds, Set<String> unsavedCategoryIds) {
  for (var categoryId in categories.keys) {
    var categoryView = _view.categoriesById[categoryId];
    categoryView.markAsUnsaved(unsavedCategoryIds.contains(categoryId));
    categoryView.showReset(renamedCategoryIds.contains(categoryId));
    if (!unsavedCategoryIds.contains(categoryId)) {
      categoryView.hideAlternative();
    }

    for (var groupId in categories[categoryId].groups.keys) {
      var groupView = categoryView.groupsById[groupId];
      groupView.markAsUnsaved(unsavedGroupIds.contains(groupId));
      groupView.showReset(renamedGroupIds.contains(groupId));
      if (!unsavedGroupIds.contains(groupId)) {
        groupView.hideAlternative();
      }

      for (var messageId in categories[categoryId].groups[groupId].messages.keys) {
        var messageView = groupView.messagesById[messageId];
        messageView.markTextAsUnsaved(unsavedMessageTextIds.contains(messageId));
        messageView.showResetForText(unsavedMessageTextIds.contains(messageId));
        messageView.markTranslationAsUnsaved(unsavedMessageTranslationIds.contains(messageId));
        messageView.showResetForTranslation(unsavedMessageTranslationIds.contains(messageId));

        if (!unsavedMessageTextIds.contains(messageId)) {
          messageView.hideAlternativeText();
        }
        if (!unsavedMessageTranslationIds.contains(messageId)) {
          messageView.hideAlternativeTranslation();
        }
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
