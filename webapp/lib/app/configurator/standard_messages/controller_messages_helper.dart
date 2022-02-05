part of controller;

// todo: renaming categories, groups are not updated
// todo: deleting messages doesnot remove empty categories

class MessagesDiffData {
  Set<String> unsavedCategoryIds;
  Set<String> unsavedGroupIds;
  Set<String> unsavedMessageIds;

  List<model.SuggestedReply> editedMessages;
  List<model.SuggestedReply> deletedMessages;

  MessagesDiffData(this.unsavedCategoryIds, this.unsavedGroupIds, this.unsavedMessageIds, this.editedMessages, this.deletedMessages);
}

class StandardMessagesManager {
  static final StandardMessagesManager _singleton = StandardMessagesManager._internal();

  StandardMessagesManager._internal();

  factory StandardMessagesManager() => _singleton;

  int getNextCategoryIndex() {
    var lastIndex = localCategories.values.fold(0, (previousValue, category) => previousValue > category.categoryIndex ? previousValue : category.categoryIndex);
    return lastIndex + 1;
  }

  int getNextGroupIndexInCategory(String categoryId) {
    var lastIndex = localCategories[categoryId].groups.values.fold(0, (previousValue, group) => previousValue > group.groupIndexInCategory ? previousValue : group.groupIndexInCategory);
    return lastIndex + 1;
  }

  int getNextMessageIndexInGroup(String categoryId, String groupId) {
    var standardMessagesInGroup = localCategories[categoryId].groups[groupId].messages.values;
    var lastIndexInGroup = standardMessagesInGroup.fold(0, (previousValue, r) => previousValue > r.indexInGroup ? previousValue : r.indexInGroup);
    return lastIndexInGroup + 1;
  }

  Map<String, MessageCategory> storageCategories = {};
  Map<String, MessageCategory> localCategories = {};

  MessagesDiffData get diffData {
    Set<String> unsavedCategoryIds = {};
    Set<String> unsavedGroupIds = {};
    Set<String> unsavedMessageIds = {};

    List<model.SuggestedReply> editedMessages = [];
    List<model.SuggestedReply> deletedMessages = [];

    Map<String, model.SuggestedReply> storageMessages = {};
    Map<String, model.SuggestedReply> localMessages = {};

    for (var category in localCategories.values) {
      category.messages.forEach((message) {
        localMessages[message.suggestedReplyId] = message;
      });
    }

    for (var category in storageCategories.values) {
      category.messages.forEach((message) {
        storageMessages[message.suggestedReplyId] = message;
      });
    }

    Set<String> allMessageKeys = Set()..addAll(localMessages.keys)..addAll(storageMessages.keys);
    for (var messageId in allMessageKeys) {
      var storageMessage = storageMessages[messageId];
      var localMessage = localMessages[messageId];

      if (localMessage == null) { // message deleted
        deletedMessages.add(storageMessage);
        unsavedMessageIds.add(storageMessage.suggestedReplyId);
        unsavedGroupIds.add(storageMessage.groupId);
        unsavedCategoryIds.add(storageMessage.categoryId);
      } else if (storageMessage == null) { // message added
        editedMessages.add(localMessage);
        unsavedMessageIds.add(localMessage.suggestedReplyId);
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
        if (localMessage.text != storageMessage.text || localMessage.translation != storageMessage.translation) { // message / translation changed. TODO: split the check
          unsavedMessageIds.add(localMessage.suggestedReplyId);
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

    return MessagesDiffData(unsavedCategoryIds, unsavedGroupIds, unsavedMessageIds, editedMessages, deletedMessages);
  }

  /// Returns the list of messages being managed.
  List<model.SuggestedReply> get standardMessagesInStorage => storageCategories.values.fold([], (result, category) => result..addAll(category.messages));
  List<model.SuggestedReply> get standardMessagesInLocal => localCategories.values.fold([], (result, category) => result..addAll(category.messages));

  model.SuggestedReply getStandardMessageById(String id) => standardMessagesInLocal.singleWhere((r) => r.suggestedReplyId == id);


  model.SuggestedReply addStandardMessageInLocal(model.SuggestedReply standardMessage) {
    if (standardMessagesInLocal.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      updateStandardMessageInLocal(standardMessage);
      return null;
    }
    localCategories.putIfAbsent(standardMessage.categoryId, () => new MessageCategory(standardMessage.categoryId, standardMessage.category, standardMessage.categoryIndex));
    localCategories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    localCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages[standardMessage.suggestedReplyId] = standardMessage;
    return standardMessage;
  }

  model.SuggestedReply onAddStandardMessageFromStorage(model.SuggestedReply standardMessage) {
    storageCategories.putIfAbsent(standardMessage.categoryId, () => MessageCategory(standardMessage.categoryId, standardMessage.categoryName, standardMessage.categoryIndex));
    storageCategories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    storageCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages.putIfAbsent(standardMessage.suggestedReplyId, () => standardMessage.clone());
    return standardMessage;
  }

  List<model.SuggestedReply> onAddStandardMessagesFromStorage(List<model.SuggestedReply> standardMessagesToAdd) {
    List<model.SuggestedReply> added = [];
    for (var standardMessage in standardMessagesToAdd) {
      var result = addStandardMessageInLocal(standardMessage);
      onAddStandardMessageFromStorage(standardMessage);
      if (result != null) added.add(result);
    }
    return added;
  }

  model.SuggestedReply updateStandardMessageInLocal(model.SuggestedReply standardMessage) {
    var removed = removeStandardMessageInLocal(standardMessage);
    var updated = addStandardMessageInLocal(standardMessage);
    if (removed == null || updated == null) {
      throw "Standard message consistency error: The two-step update process has found an inconsistency for updating tag ${standardMessage.suggestedReplyId}";
    }
    return updated;
  }

  model.SuggestedReply onUpdateStandardMessageFromStorage(model.SuggestedReply standardMessage) {
    storageCategories.putIfAbsent(standardMessage.categoryId, () => MessageCategory(standardMessage.categoryId, standardMessage.categoryName, standardMessage.categoryIndex));
    storageCategories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    storageCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages.putIfAbsent(standardMessage.suggestedReplyId, () => standardMessage.clone());
    storageCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages[standardMessage.suggestedReplyId] = standardMessage.clone();
    return standardMessage;
  }

  List<model.SuggestedReply> onUpdateStandardMessagesFromStorage(List<model.SuggestedReply> standardMessagesToAdd) {
    List<model.SuggestedReply> added = [];
    for (var standardMessage in standardMessagesToAdd) {
      onUpdateStandardMessageFromStorage(standardMessage);

      // todo: check if unedited
      var result = updateStandardMessageInLocal(standardMessage);
      if (result != null) added.add(result);
    }
    return added;
  }

  model.SuggestedReply removeStandardMessageInLocal(model.SuggestedReply standardMessage) {
    // todo: this might not be relevant
    if (!standardMessagesInLocal.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      log.warning("Standard messages consistency error: Removing message that doesn't exist: ${standardMessage.suggestedReplyId}");
      return null;
    }
    var oldStandardMessage = standardMessagesInLocal.singleWhere((element) => element.suggestedReplyId == standardMessage.suggestedReplyId);
    localCategories[oldStandardMessage.categoryId].groups[oldStandardMessage.groupId].messages.remove(oldStandardMessage.suggestedReplyId);
    return standardMessage;
  }

  model.SuggestedReply onRemoveStandardMessageFromStorage(model.SuggestedReply standardMessage) {
    if (!standardMessagesInLocal.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      log.warning("Standard messages consistency error: Removing message that doesn't exist: ${standardMessage.suggestedReplyId}");
      return null;
    }
    var oldStandardMessage = standardMessagesInStorage.singleWhere((element) => element.suggestedReplyId == standardMessage.suggestedReplyId);
    storageCategories[oldStandardMessage.categoryId].groups[oldStandardMessage.groupId].messages.remove(oldStandardMessage.suggestedReplyId);
    return standardMessage;
  }

  List<model.SuggestedReply> onRemoveStandardMessagesFromStorage(List<model.SuggestedReply> standardMessages) {
    List<model.SuggestedReply> removed = [];
    for (var standardMessage in standardMessages) {
      onRemoveStandardMessageFromStorage(standardMessage);

      // todo: check if unedited
      var result = removeStandardMessageInLocal(standardMessage);
      if (result != null) removed.add(result);
    }
    return removed;
  }

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
    addStandardMessageInLocal(newStandardMessage);
    return newStandardMessage;
  }

  model.SuggestedReply modifyMessage(String messageId, String text, String translation) {
    var message = standardMessagesInLocal.singleWhere((element) => element.suggestedReplyId == messageId);
    if ((message.text != null && message.text == text) || (message.translation != null && message.translation == translation)) {
      return message;
    }

    if (text != null) {
      message.text = text;
    }
    if (translation != null) {
      message.translation = translation;
    }
    updateStandardMessageInLocal(message);
    return message;
  }

  model.SuggestedReply deleteMessage(String messageId) {
    var message = standardMessagesInLocal.singleWhere((element) => element.suggestedReplyId == messageId);
    removeStandardMessageInLocal(message);
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
    var category = localCategories.remove(categoryId);
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
