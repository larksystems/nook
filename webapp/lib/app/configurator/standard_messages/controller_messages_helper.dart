part of controller;


class StandardMessagesManager {
  static final StandardMessagesManager _singleton = StandardMessagesManager._internal();

  StandardMessagesManager._internal();

  factory StandardMessagesManager() => _singleton;

  int _lastStandardMessageSeqNo = 0;
  int _lastStandardMessagesGroupSeqNo = 0;
  int _lastStandardMessagesCategorySeqNo = 0;

  int get lastStandardMessageSeqNo => _lastStandardMessageSeqNo;
  int get nextStandardMessageSeqNo => ++_lastStandardMessageSeqNo;

  int get lastStandardMessagesGroupSeqNo => _lastStandardMessagesGroupSeqNo;
  int get nextStandardMessagesGroupSeqNo => ++_lastStandardMessagesGroupSeqNo;

  int get lastStandardMessagesCategorySeqNo => _lastStandardMessagesCategorySeqNo;
  int get nextStandardMessagesCategorySeqNo => ++_lastStandardMessagesCategorySeqNo;

  int getNextIndexInGroup(String categoryId, String groupId) {
    var standardMessagesInGroup = categories[categoryId].groups[groupId].messages.values;
    var lastIndexInGroup = standardMessagesInGroup.fold(0, (previousValue, r) => previousValue > r.indexInGroup ? previousValue : r.indexInGroup);
    return lastIndexInGroup + 1;
  }

  Map<String, MessageCategory> categories = {};

  /// Returns the list of messages being managed.
  List<model.SuggestedReply> get standardMessages => categories.values.fold([], (result, category) => result..addAll(category.messages));

  model.SuggestedReply getStandardMessageById(String id) => standardMessages.singleWhere((r) => r.suggestedReplyId == id);


  model.SuggestedReply addStandardMessage(model.SuggestedReply standardMessage) {
    if (standardMessages.any((element) => element.suggestedReplyId == standardMessage.suggestedReplyId)) {
      updateStandardMessage(standardMessage);
      return null;
    }
    categories.putIfAbsent(standardMessage.categoryId, () => new MessageCategory(standardMessage.categoryId, standardMessage.category));
    categories[standardMessage.categoryId].groups.putIfAbsent(standardMessage.groupId, () => MessageGroup(standardMessage.groupId, standardMessage.groupDescription));
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

  model.SuggestedReply removeStandardMessage(model.SuggestedReply standardMessage) {
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

  model.SuggestedReply createMessage(String categoryId, String categoryName, String groupId, String groupName) {
    var newStandardMessage = model.SuggestedReply()
      ..docId = model.generateStandardMessageId()
      ..text = ''
      ..translation = ''
      ..shortcut = ''
      ..seqNumber = lastStandardMessageSeqNo
      ..categoryId = categoryId
      ..category = categoryName
      ..groupId = categories[categoryId].groups[groupId].groupId
      ..groupDescription = groupName
      ..indexInGroup = getNextIndexInGroup(categoryId, groupId);
    addStandardMessage(newStandardMessage);
    editedMessages[newStandardMessage.suggestedReplyId] = newStandardMessage;
    return newStandardMessage;
  }

  model.SuggestedReply modifyMessage(String messageId, String text, String translation) {
    var message = standardMessages.singleWhere((element) => element.suggestedReplyId == messageId);
    if (text != null) {
      message.text = text;
    }
    if (translation != null) {
      message.translation = translation;
    }
    updateStandardMessage(message);
    editedMessages[message.suggestedReplyId] = message;
    return message;
  }

  model.SuggestedReply deleteMessage(String messageId) {
    var message = standardMessages.singleWhere((element) => element.suggestedReplyId == messageId);
    removeStandardMessage(message);
    editedMessages.remove(messageId);
    deletedMessages[messageId] = message;
    return message;
  }

  MessageGroup createStandardMessagesGroup(String categoryId, String category, {String groupId, String groupName}) {
    var newGroupId = groupId ?? model.generateStandardMessageGroupId();
    var newMessageGroup = new MessageGroup(newGroupId, groupName ?? "message group $nextStandardMessagesGroupSeqNo");
    categories[categoryId].groups[newMessageGroup.groupId] = newMessageGroup;
    return newMessageGroup;
  }

  void renameStandardMessageGroup(String categoryId, String groupId, String newGroupName) {
    var group = categories[categoryId].groups.remove(groupId); // todo: why remove?
    group.groupName = newGroupName;
    for (var standardMessage in group.messages.values) {
      standardMessage.groupDescription = newGroupName;
      editedMessages[standardMessage.suggestedReplyId] = standardMessage;
    }
    categories[categoryId].groups[groupId] = group;
  }

  void deleteStandardMessagesGroup(String categoryId, String category, String groupId, String groupDescription) {
    var group = categories[categoryId].groups.remove(groupId);
    deletedMessages.addAll(group.messages);
  }

  /// Creates a new messages category and return it.
  /// If [categoryName] is given, it will use that name, otherwise it will generate a placeholder name.
  MessageCategory createStandardMessagesCategory([String categoryName]) {
    var newCategoryName = categoryName ?? "message category $nextStandardMessagesCategorySeqNo";
    var newCategoryId = model.generateStandardMessageCategoryId();
    var newCategory = new MessageCategory(newCategoryId, newCategoryName);
    categories[newCategoryId] = newCategory;
    return newCategory;
  }

  /// Renames a messages category and propagates the change to all the messages in that category.
  /// Also adds these messages to the list of messages that have been edited and need to be saved.
  void renameStandardMessageCategory(String categoryId, String newCategoryName) {
    var category = categories.remove(categoryId);  // todo: why remove?
    category.categoryName = newCategoryName;
    for (var standardMessage in category.messages) {
      standardMessage.category = newCategoryName;
      editedMessages[standardMessage.suggestedReplyId] = standardMessage;
    }
    categories[categoryId] = category;
  }

  /// Deletes the messages category with the given [categoryName], and the messages in that category.
  /// Also adds these messages to the list of messages to be deleted and need to be saved.
  void deleteStandardMessagesCategory(String categoryId, String categoryName) {
    var category = categories.remove(categoryId);
    deletedMessages.addEntries(category.messages.map((e) => MapEntry(e.suggestedReplyId, e)));
  }

  /// The messages that have been edited and need to be saved, stored as a `Map<tagId, Tag>`.
  Map<String, model.SuggestedReply> editedMessages = {};

  /// The messages that have been deleted and need to be saved, stored as a `Map<tagId, Tag>`.
  Map<String, model.SuggestedReply> deletedMessages = {};

  /// The message IDs that are arrived from editedMessages, deletedMessages
  Set<String> get unsavedMessageIds => editedMessages.entries.map((e) => e.value.docId).toSet()..addAll(deletedMessages.entries.map((e) => e.value.docId).toSet());
  Set<String> get unsavedGroupIds => editedMessages.entries.map((e) => e.value.groupId).toSet()..addAll(deletedMessages.entries.map((e) => e.value.groupId).toSet());
  Set<String> get unsavedCategoryIds => editedMessages.entries.map((e) => e.value.categoryId).toSet()..addAll(deletedMessages.entries.map((e) => e.value.categoryId).toSet());

  /// Returns whether there's any edited or deleted messages to be saved.
  bool get hasUnsavedMessages => editedMessages.isNotEmpty || deletedMessages.isNotEmpty;
}


class MessageCategory {
  String categoryId;
  String categoryName;
  Map<String, MessageGroup> groups = {};

  MessageCategory(this.categoryId, this.categoryName);

  List<model.SuggestedReply> get messages => groups.values.fold([], (result, group) => result..addAll(group.messages.values));

  String toString() {
    return 'MessageGroup($categoryId, $categoryName, $groups)';
  }
}

class MessageGroup {
  String groupId;
  String groupName;
  Map<String, model.SuggestedReply> messages = {};

  MessageGroup(this.groupId, this.groupName);

  @override
  String toString() {
    return 'MessageGroup($groupId, $groupName, ${messages.length})';
  }
}
