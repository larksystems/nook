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
    var lastIndex = categories.values.fold(0, (previousValue, category) => previousValue > category.categoryIndex ? previousValue : category.categoryIndex);
    return lastIndex + 1;
  }

  int getNextGroupIndexInCategory(String categoryId) {
    var lastIndex = categories[categoryId].groups.values.fold(0, (previousValue, group) => previousValue > group.groupIndexInCategory ? previousValue : group.groupIndexInCategory);
    return lastIndex + 1;
  }

  int getNextMessageIndexInGroup(String categoryId, String groupId) {
    var standardMessagesInGroup = categories[categoryId].groups[groupId].messages.values;
    var lastIndexInGroup = standardMessagesInGroup.fold(0, (previousValue, r) => previousValue > r.indexInGroup ? previousValue : r.indexInGroup);
    return lastIndexInGroup + 1;
  }

  Map<String, MessageCategory> fbCategories = {};
  Map<String, MessageCategory> categories = {};

  MessagesDiffData get diffData {
    Set<String> unsavedCategoryIds = {};
    Set<String> unsavedGroupIds = {};
    Set<String> unsavedMessageIds = {};

    List<model.SuggestedReply> editedMessages = [];
    List<model.SuggestedReply> deletedMessages = [];

    Map<String, model.SuggestedReply> fbMessages = {};
    Map<String, model.SuggestedReply> messages = {};

    for (var category in categories.values) {
      category.messages.forEach((message) {
        messages[message.suggestedReplyId] = message;
      });
    }

    for (var category in fbCategories.values) {
      category.messages.forEach((message) {
        fbMessages[message.suggestedReplyId] = message;
      });
    }

    Set<String> allMessageKeys = Set()..addAll(messages.keys)..addAll(fbMessages.keys);
    for (var messageId in allMessageKeys) {
      var fbMessage = fbMessages[messageId];
      var localMessage = messages[messageId];

      if (localMessage == null) { // message deleted
        deletedMessages.add(fbMessage);
        unsavedMessageIds.add(fbMessage.suggestedReplyId);
        unsavedGroupIds.add(fbMessage.groupId);
        unsavedCategoryIds.add(fbMessage.categoryId);
      } else if (fbMessage == null) { // message added
        editedMessages.add(localMessage);
        unsavedMessageIds.add(localMessage.suggestedReplyId);
        unsavedGroupIds.add(localMessage.groupId);
        unsavedCategoryIds.add(localMessage.categoryId);
      } else { // message edited
        var isMessageEdited = false;
        if (localMessage.categoryName != fbMessage.categoryName) { // renamed category
          unsavedCategoryIds.add(localMessage.categoryId);
          isMessageEdited = true;
        }
        if (localMessage.groupName != fbMessage.groupName) { // renamed group
          unsavedGroupIds.add(localMessage.groupId);
          unsavedCategoryIds.add(localMessage.categoryId);
          isMessageEdited = true;
        }
        if (localMessage.text != fbMessage.text || localMessage.translation != fbMessage.translation) { // message / translation changed. TODO: split the check
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
  List<model.SuggestedReply> get standardFbMessages => fbCategories.values.fold([], (result, category) => result..addAll(category.messages));
  List<model.SuggestedReply> get standardMessages => categories.values.fold([], (result, category) => result..addAll(category.messages));

  model.SuggestedReply getStandardMessageById(String id) => standardMessages.singleWhere((r) => r.suggestedReplyId == id);


  model.SuggestedReply addStandardMessage(model.SuggestedReply standardMessage) {
    if (standardMessages.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      updateStandardMessage(standardMessage);
      return null;
    }
    categories.putIfAbsent(standardMessage.categoryId, () => new MessageCategory(standardMessage.categoryId, standardMessage.category, standardMessage.categoryIndex));
    categories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    categories[standardMessage.categoryId].groups[standardMessage.groupId].messages[standardMessage.suggestedReplyId] = standardMessage;
    return standardMessage;
  }

  List<model.SuggestedReply> addStandardMessages(List<model.SuggestedReply> standardMessagesToAdd) {
    List<model.SuggestedReply> added = [];
    for (var standardMessage in standardMessagesToAdd) {
      var result = addStandardMessage(standardMessage);
      if (result != null) added.add(result);
    }
    return added;
  }

  model.SuggestedReply onAddStandardMessageFromFb(model.SuggestedReply standardMessage) {
    fbCategories.putIfAbsent(standardMessage.categoryId, () => MessageCategory(standardMessage.categoryId, standardMessage.categoryName, standardMessage.categoryIndex));
    fbCategories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    fbCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages.putIfAbsent(standardMessage.suggestedReplyId, () => standardMessage.clone());
    return standardMessage;
  }

  List<model.SuggestedReply> onAddStandardMessagesFromFb(List<model.SuggestedReply> standardMessagesToAdd) {
    List<model.SuggestedReply> added = [];
    for (var standardMessage in standardMessagesToAdd) {
      var result = addStandardMessage(standardMessage);
      onAddStandardMessageFromFb(standardMessage);
      if (result != null) added.add(result);
    }
    return added;
  }

  model.SuggestedReply updateStandardMessage(model.SuggestedReply standardMessage) {
    var removed = removeStandardMessage(standardMessage);
    var updated = addStandardMessage(standardMessage);
    if (removed == null || updated == null) {
      throw "Standard message consistency error: The two-step update process has found an inconsistency for updating tag ${standardMessage.suggestedReplyId}";
    }
    return updated;
  }

  List<model.SuggestedReply> updateStandardMessages(List<model.SuggestedReply> standardMessages) {
    List<model.SuggestedReply> updated = [];
    for (var standardMessage in standardMessages) {
      var result = updateStandardMessage(standardMessage);
      if (result != null) updated.add(result);
    }
    return updated;
  }

  model.SuggestedReply onUpdateStandardMessageFromFb(model.SuggestedReply standardMessage) {
    fbCategories.putIfAbsent(standardMessage.categoryId, () => MessageCategory(standardMessage.categoryId, standardMessage.categoryName, standardMessage.categoryIndex));
    fbCategories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupName, standardMessage.groupIndexInCategory));
    fbCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages.putIfAbsent(standardMessage.suggestedReplyId, () => standardMessage.clone());
    fbCategories[standardMessage.categoryId].groups[standardMessage.groupId].messages[standardMessage.suggestedReplyId] = standardMessage.clone();
    return standardMessage;
  }

  List<model.SuggestedReply> onUpdateStandardMessagesFromFb(List<model.SuggestedReply> standardMessagesToAdd) {
    List<model.SuggestedReply> added = [];
    for (var standardMessage in standardMessagesToAdd) {
      onUpdateStandardMessageFromFb(standardMessage);

      // todo: check if unedited
      var result = updateStandardMessage(standardMessage);
      if (result != null) added.add(result);
    }
    return added;
  }

  model.SuggestedReply removeStandardMessage(model.SuggestedReply standardMessage) {
    // todo: this might not be relevant
    if (!standardMessages.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      log.warning("Standard messages consistency error: Removing message that doesn't exist: ${standardMessage.suggestedReplyId}");
      return null;
    }
    var oldStandardMessage = standardMessages.singleWhere((element) => element.suggestedReplyId == standardMessage.suggestedReplyId);
    categories[oldStandardMessage.categoryId].groups[oldStandardMessage.groupId].messages.remove(oldStandardMessage.suggestedReplyId);
    return standardMessage;
  }

  List<model.SuggestedReply> removeStandardMessages(List<model.SuggestedReply> standardMessages) {
    List<model.SuggestedReply> removed = [];
    for (var standardMessage in standardMessages) {
      var result = removeStandardMessage(standardMessage);
      if (result != null) removed.add(result);
    }
    return removed;
  }

  model.SuggestedReply onRemoveStandardMessageFromFb(model.SuggestedReply standardMessage) {
    if (!standardMessages.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      log.warning("Standard messages consistency error: Removing message that doesn't exist: ${standardMessage.suggestedReplyId}");
      return null;
    }
    var oldStandardMessage = standardFbMessages.singleWhere((element) => element.suggestedReplyId == standardMessage.suggestedReplyId);
    fbCategories[oldStandardMessage.categoryId].groups[oldStandardMessage.groupId].messages.remove(oldStandardMessage.suggestedReplyId);
    return standardMessage;
  }

  List<model.SuggestedReply> onRemoveStandardMessagesFromFb(List<model.SuggestedReply> standardMessages) {
    List<model.SuggestedReply> removed = [];
    for (var standardMessage in standardMessages) {
      onRemoveStandardMessageFromFb(standardMessage);

      // todo: check if unedited
      var result = removeStandardMessage(standardMessage);
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
      ..groupId = categories[categoryId].groups[groupId].groupId
      ..groupName = groupName
      ..indexInGroup = getNextMessageIndexInGroup(categoryId, groupId)
      ..categoryIndex = categoryIndex
      ..groupIndexInCategory = groupIndexInCategory;
    addStandardMessage(newStandardMessage);
    return newStandardMessage;
  }

  model.SuggestedReply modifyMessage(String messageId, String text, String translation) {
    var message = standardMessages.singleWhere((element) => element.suggestedReplyId == messageId);
    if ((message.text != null && message.text == text) || (message.translation != null && message.translation == translation)) {
      return message;
    }

    if (text != null) {
      message.text = text;
    }
    if (translation != null) {
      message.translation = translation;
    }
    updateStandardMessage(message);
    return message;
  }

  model.SuggestedReply deleteMessage(String messageId) {
    var message = standardMessages.singleWhere((element) => element.suggestedReplyId == messageId);
    removeStandardMessage(message);
    return message;
  }

  MessageGroup createStandardMessagesGroup(String categoryId, String category, {String groupId, String groupName}) {
    var newGroupId = groupId ?? model.generateStandardMessageGroupId();
    var newGroupIndex = getNextGroupIndexInCategory(categoryId);
    var newMessageGroup = new MessageGroup(newGroupId, groupName ?? "Message group $newGroupIndex", newGroupIndex);
    categories[categoryId].groups[newMessageGroup.groupId] = newMessageGroup;
    return newMessageGroup;
  }

  void renameStandardMessageGroup(String categoryId, String groupId, String newGroupName) {
    var group = categories[categoryId].groups[groupId];
    group.groupName = newGroupName;
    for (var standardMessage in group.messages.values) {
      standardMessage.groupName = newGroupName;
    }
  }

  void deleteStandardMessagesGroup(String categoryId, String groupId) {
    var group = categories[categoryId].groups.remove(groupId);
  }

  /// Creates a new messages category and return it.
  /// If [categoryName] is given, it will use that name, otherwise it will generate a placeholder name.
  MessageCategory createStandardMessagesCategory([String categoryName]) {
    var newCategoryId = model.generateStandardMessageCategoryId();
    var newCategoryIndex = getNextCategoryIndex();
    var newCategoryName = categoryName ?? "Message category $newCategoryIndex";
    var newCategory = new MessageCategory(newCategoryId, newCategoryName, newCategoryIndex);
    categories[newCategoryId] = newCategory;
    return newCategory;
  }

  /// Renames a messages category and propagates the change to all the messages in that category.
  /// Also adds these messages to the list of messages that have been edited and need to be saved.
  void renameStandardMessageCategory(String categoryId, String newCategoryName) {
    var category = categories[categoryId];
    category.categoryName = newCategoryName;
    for (var standardMessage in category.messages) {
      standardMessage.category = newCategoryName;
    }
  }

  /// Deletes the messages category with the given [categoryName], and the messages in that category.
  /// Also adds these messages to the list of messages to be deleted and need to be saved.
  void deleteStandardMessagesCategory(String categoryId) {
    var category = categories.remove(categoryId);
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
