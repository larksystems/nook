part of controller;

// todo: renaming categories, groups are not updated
// todo: deleting messages doesnot remove empty categories

class MessagesDiffData {
  Set<String> unsavedCategoryIds;
  Set<String> unsavedGroupIds;
  Set<String> unsavedMessageTextIds;
  Set<String> unsavedMessageTranslationIds;

  List<model.SuggestedReply> editedMessages;
  List<model.SuggestedReply> deletedMessages;

  MessagesDiffData(this.unsavedCategoryIds, this.unsavedGroupIds, this.unsavedMessageTextIds, this.unsavedMessageTranslationIds, this.editedMessages, this.deletedMessages);
}

class StandardMessagesManager {
  static final StandardMessagesManager _singleton = StandardMessagesManager._internal();

  StandardMessagesManager._internal();

  factory StandardMessagesManager() => _singleton;

  int getNextCategoryIndex() {
    var lastIndex = localCategories.values.fold(0, (maxIndex, category) => maxIndex > category.categoryIndex ? maxIndex : category.categoryIndex);
    return lastIndex + 1;
  }

  int getNextGroupIndexInCategory(String categoryId) {
    var lastIndex = localCategories[categoryId].groups.values.fold(0, (maxIndex, group) => maxIndex > group.groupIndexInCategory ? maxIndex : group.groupIndexInCategory);
    return lastIndex + 1;
  }

  int getNextMessageIndexInGroup(String categoryId, String groupId) {
    var standardMessagesInGroup = localCategories[categoryId].groups[groupId].messages.values;
    var lastIndexInGroup = standardMessagesInGroup.fold(0, (maxIndex, r) => maxIndex > r.indexInGroup ? maxIndex : r.indexInGroup);
    return lastIndexInGroup + 1;
  }

  Map<String, MessageCategory> storageCategories = {};
  Map<String, MessageCategory> localCategories = {};

  MessagesDiffData get diffData {
    Set<String> unsavedCategoryIds = {};
    Set<String> unsavedGroupIds = {};
    Set<String> unsavedMessageTextIds = {};
    Set<String> unsavedMessageTranslationIds = {};

    List<model.SuggestedReply> editedMessages = [];
    List<model.SuggestedReply> deletedMessages = [];

    Map<String, model.SuggestedReply> storageMessages = {};
    Map<String, model.SuggestedReply> localMessages = {};

    for (var category in localCategories.values) {
      for (var message in category.messages) {
        localMessages[message.suggestedReplyId] = message;
      }
    }

    for (var category in storageCategories.values) {
      for (var message in category.messages) {
        storageMessages[message.suggestedReplyId] = message;
      }
    }

    Set<String> allMessageKeys = {...localMessages.keys, ...storageMessages.keys};
    for (var messageId in allMessageKeys) {
      var storageMessage = storageMessages[messageId];
      var localMessage = localMessages[messageId];

      if (localMessage == null) { // message deleted
        deletedMessages.add(storageMessage);
        unsavedMessageTextIds.add(storageMessage.suggestedReplyId);
        unsavedMessageTranslationIds.add(storageMessage.suggestedReplyId);
        unsavedGroupIds.add(storageMessage.groupId);
        unsavedCategoryIds.add(storageMessage.categoryId);
      } else if (storageMessage == null) { // message added
        editedMessages.add(localMessage);
        unsavedMessageTextIds.add(localMessage.suggestedReplyId);
        unsavedMessageTranslationIds.add(localMessage.suggestedReplyId);
        unsavedGroupIds.add(localMessage.groupId);
        unsavedCategoryIds.add(localMessage.categoryId);
      } else { // message edited
        var isMessageEdited = false;
        if (localMessage.categoryName != storageMessage.categoryName) { // renamed category
          unsavedCategoryIds.add(localMessage.categoryId);
          isMessageEdited = true;
        }
        if (localMessage.groupName != storageMessage.groupName) { // renamed group
          unsavedGroupIds.add(localMessage.groupId);
          unsavedCategoryIds.add(localMessage.categoryId);
          isMessageEdited = true;
        }
        if (localMessage.text != storageMessage.text || localMessage.translation != storageMessage.translation) { // message / translation changed.
          if (localMessage.text != storageMessage.text) {
            unsavedMessageTextIds.add(localMessage.suggestedReplyId);
          }
          if (localMessage.translation != storageMessage.translation) {
            unsavedMessageTranslationIds.add(localMessage.suggestedReplyId);
          }
          unsavedGroupIds.add(localMessage.groupId);
          unsavedCategoryIds.add(localMessage.categoryId);
          isMessageEdited = true;
        }

        // todo: moved across categories
        // todo: moved across groups
        // todo: rearranged within groups
        if (isMessageEdited) {
          editedMessages.add(localMessage);
        }
      }
    }

    return MessagesDiffData(unsavedCategoryIds, unsavedGroupIds, unsavedMessageTextIds, unsavedMessageTranslationIds, editedMessages, deletedMessages);
  }

  /// Returns the list of messages being managed.
  List<model.SuggestedReply> get standardMessagesInStorage => storageCategories.values.fold([], (result, category) => result..addAll(category.messages));
  List<model.SuggestedReply> get standardMessagesInLocal => localCategories.values.fold([], (result, category) => result..addAll(category.messages));

  model.SuggestedReply getStandardMessageById(String id) => standardMessagesInLocal.singleWhere((r) => r.suggestedReplyId == id);

  // methods for manipulating local data
  model.SuggestedReply _addStandardMessageInLocal(model.SuggestedReply standardMessage) {
    if (standardMessagesInLocal.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      _updateStandardMessageInLocal(standardMessage);
      return null;
    }
    localCategories.putIfAbsent(standardMessage.categoryId, () => new MessageCategory(standardMessage.categoryId, standardMessage.category, standardMessage.categoryIndex));
    localCategories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    localCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages[standardMessage.suggestedReplyId] = standardMessage;
    return standardMessage;
  }

  model.SuggestedReply _updateStandardMessageInLocal(model.SuggestedReply standardMessage) {
    var removed = _removeStandardMessageInLocal(standardMessage);
    var updated = _addStandardMessageInLocal(standardMessage);
    if (removed == null || updated == null) {
      throw "Standard message consistency error: The two-step update process has found an inconsistency for updating tag ${standardMessage.suggestedReplyId}";
    }
    return updated;
  }

  model.SuggestedReply _removeStandardMessageInLocal(model.SuggestedReply standardMessage) {
    // todo: this might not be relevant
    if (!standardMessagesInLocal.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      log.warning("Standard messages consistency error: Removing message that doesn't exist: ${standardMessage.suggestedReplyId}");
      return null;
    }
    var oldStandardMessage = standardMessagesInLocal.singleWhere((element) => element.suggestedReplyId == standardMessage.suggestedReplyId);
    localCategories[oldStandardMessage.categoryId].groups[oldStandardMessage.groupId].messages.remove(oldStandardMessage.suggestedReplyId);
    return standardMessage;
  }

  // methods for manipulating data from storage
  model.SuggestedReply _addStandardMessageInStorage(model.SuggestedReply standardMessage) {
    storageCategories.putIfAbsent(standardMessage.categoryId, () => MessageCategory(standardMessage.categoryId, standardMessage.categoryName, standardMessage.categoryIndex));
    storageCategories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    storageCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages.putIfAbsent(standardMessage.suggestedReplyId, () => standardMessage.clone());
    return standardMessage;
  }

  model.SuggestedReply _updateStandardMessageInStorage(model.SuggestedReply standardMessage) {
    storageCategories.putIfAbsent(standardMessage.categoryId, () => MessageCategory(standardMessage.categoryId, standardMessage.categoryName, standardMessage.categoryIndex));
    storageCategories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    storageCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages.putIfAbsent(standardMessage.suggestedReplyId, () => standardMessage.clone());
    storageCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages[standardMessage.suggestedReplyId] = standardMessage.clone();
    return standardMessage;
  }

  model.SuggestedReply _removeStandardMessageInStorage(model.SuggestedReply standardMessage) {
    if (!standardMessagesInLocal.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      log.warning("Standard messages consistency error: Removing message that doesn't exist: ${standardMessage.suggestedReplyId}");
      return null;
    }
    var oldStandardMessage = standardMessagesInStorage.singleWhere((element) => element.suggestedReplyId == standardMessage.suggestedReplyId);
    storageCategories[oldStandardMessage.categoryId].groups[oldStandardMessage.groupId].messages.remove(oldStandardMessage.suggestedReplyId);
    return standardMessage;
  }

  // methods to be called when updates are received from storage
  List<model.SuggestedReply> onAddStandardMessagesFromStorage(List<model.SuggestedReply> standardMessagesToAdd) {
    List<model.SuggestedReply> added = [];
    for (var standardMessage in standardMessagesToAdd) {
      var result = _addStandardMessageInLocal(standardMessage);
      _addStandardMessageInStorage(standardMessage);
      if (result != null) added.add(result);
    }
    return added;
  }

  List<model.SuggestedReply> onUpdateStandardMessagesFromStorage(List<model.SuggestedReply> standardMessagesToAdd) {
    List<model.SuggestedReply> added = [];
    for (var standardMessage in standardMessagesToAdd) {
      var localMessage = localCategories[standardMessage.categoryId]?.groups[standardMessage.groupId]?.messages[standardMessage.docId];
      var storageMessage = storageCategories[standardMessage.categoryId]?.groups[standardMessage.groupId]?.messages[standardMessage.docId];

      if (localMessage == null || storageMessage == null) {
        // todo: the message has been deleted from the UI or storage
      } else if (localMessage.categoryName != storageMessage.categoryName) {
        // todo: the category has been updated
      } else if (localMessage.groupName != storageMessage.groupName) {
        // todo: the group has been updated
      } else if (localMessage.text != storageMessage.text || localMessage.translation != storageMessage.translation) {
        // the message text has been updated
        if (localMessage.text != storageMessage.text) {
          _view.categoriesById[standardMessage.categoryId].groupsById[standardMessage.groupId].messagesById[standardMessage.docId].showAlternativeText(standardMessage.text);
        }
        // the message translation has been updated
        if (localMessage.translation != storageMessage.translation) {
          _view.categoriesById[standardMessage.categoryId].groupsById[standardMessage.groupId].messagesById[standardMessage.docId].showAlternativeTranslation(standardMessage.translation);
        }
      } else {
        var result = _updateStandardMessageInLocal(standardMessage);
        if (result != null) added.add(result);
      }
      _updateStandardMessageInStorage(standardMessage);
    }
    return added;
  }

  List<model.SuggestedReply> onRemoveStandardMessagesFromStorage(List<model.SuggestedReply> standardMessages) {
    List<model.SuggestedReply> removed = [];
    for (var standardMessage in standardMessages) {
      _removeStandardMessageInStorage(standardMessage);

      // todo: check if unedited
      var result = _removeStandardMessageInLocal(standardMessage);
      if (result != null) removed.add(result);
    }
    return removed;
  }

  // methods to be called when the user makes changes to the local configuration
  model.SuggestedReply createMessage(String categoryId, String categoryName, int categoryIndex, String groupId, String groupName, int groupIndexInCategory) {
    var newStandardMessage = model.SuggestedReply()
      ..docId = model.generateStandardMessageId()
      ..text = ''
      ..translation = ''
      ..shortcut = ''
      ..seqNumber = 0
      ..categoryId = categoryId
      ..category = categoryName
      ..groupId = localCategories[categoryId].groups[groupId].groupId
      ..groupName = groupName
      ..indexInGroup = getNextMessageIndexInGroup(categoryId, groupId)
      ..categoryIndex = categoryIndex
      ..groupIndexInCategory = groupIndexInCategory;
    _addStandardMessageInLocal(newStandardMessage);
    return newStandardMessage;
  }

  model.SuggestedReply modifyMessage(String messageId, String text, String translation) {
    var message = standardMessagesInLocal.singleWhere((element) => element.suggestedReplyId == messageId);
    if ((message.text != null && message.text == text) && (message.translation != null && message.translation == translation)) {
      return message;
    }

    if (text != null) {
      message.text = text;
    }
    if (translation != null) {
      message.translation = translation;
    }
    _updateStandardMessageInLocal(message);
    return message;
  }

  model.SuggestedReply deleteMessage(String messageId) {
    var message = standardMessagesInLocal.singleWhere((element) => element.suggestedReplyId == messageId);
    _removeStandardMessageInLocal(message);
    return message;
  }

  MessageGroup createStandardMessagesGroup(String categoryId, String category, {String groupId, String groupName}) {
    var newGroupId = groupId ?? model.generateStandardMessageGroupId();
    var newGroupIndex = getNextGroupIndexInCategory(categoryId);
    var newMessageGroup = new MessageGroup(newGroupId, groupName ?? "Message group $newGroupIndex", newGroupIndex);
    localCategories[categoryId].groups[newMessageGroup.groupId] = newMessageGroup;
    return newMessageGroup;
  }

  void renameStandardMessageGroup(String categoryId, String groupId, String newGroupName) {
    var group = localCategories[categoryId].groups[groupId];
    group.groupName = newGroupName;
    for (var standardMessage in group.messages.values) {
      standardMessage.groupName = newGroupName;
    }
  }

  void deleteStandardMessagesGroup(String categoryId, String groupId) {
    localCategories[categoryId].groups.remove(groupId);
  }

  /// Creates a new messages category and return it.
  /// If [categoryName] is given, it will use that name, otherwise it will generate a placeholder name.
  MessageCategory createStandardMessagesCategory([String categoryName]) {
    var newCategoryId = model.generateStandardMessageCategoryId();
    var newCategoryIndex = getNextCategoryIndex();
    var newCategoryName = categoryName ?? "Message category $newCategoryIndex";
    var newCategory = new MessageCategory(newCategoryId, newCategoryName, newCategoryIndex);
    localCategories[newCategoryId] = newCategory;
    return newCategory;
  }

  /// Renames a messages category and propagates the change to all the messages in that category.
  /// Also adds these messages to the list of messages that have been edited and need to be saved.
  void renameStandardMessageCategory(String categoryId, String newCategoryName) {
    var category = localCategories[categoryId];
    category.categoryName = newCategoryName;
    for (var standardMessage in category.messages) {
      standardMessage.category = newCategoryName;
    }
  }

  /// Deletes the messages category with the given [categoryName], and the messages in that category.
  /// Also adds these messages to the list of messages to be deleted and need to be saved.
  void deleteStandardMessagesCategory(String categoryId) {
    localCategories.remove(categoryId);
  }
}


class MessageCategory {
  String categoryId;
  String categoryName;
  int categoryIndex;
  Map<String, MessageGroup> groups = {};

  MessageCategory(this.categoryId, this.categoryName, this.categoryIndex);

  List<model.SuggestedReply> get messages => groups.values.fold([], (result, group) => result..addAll(group.messages.values));

  String toString() {
    return 'MessageGroup($categoryId, $categoryName, $groups)';
  }
}

class MessageGroup {
  String groupId;
  String groupName;
  int groupIndexInCategory;
  Map<String, model.SuggestedReply> messages = {};

  MessageGroup(this.groupId, this.groupName, this.groupIndexInCategory);

  @override
  String toString() {
    return 'MessageGroup($groupId, $groupName, ${messages.length})';
  }
}
