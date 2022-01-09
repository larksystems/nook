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

  void _updateLastStandardMessageSeqNo(int seqNo) {
    if (seqNo < _lastStandardMessageSeqNo) return;
    _lastStandardMessageSeqNo = seqNo;
  }

  void _updateLastStandardMessagesGroupSeqNo(String groupId) {
    var seqNo = int.parse(groupId.split('reply-group-').last);
    if (seqNo < _lastStandardMessagesGroupSeqNo) return;
    _lastStandardMessagesGroupSeqNo = seqNo;
  }

  int getNextIndexInGroup(String category, String groupId) {
    var standardMessagesInGroup = categories[category].groups[groupId].messages.values;
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
    categories.putIfAbsent(standardMessage.category, () => new MessageCategory(standardMessage.category));
    categories[standardMessage.category].groups.putIfAbsent(standardMessage.groupDescription, () => MessageGroup(standardMessage.groupId, standardMessage.groupDescription));
    categories[standardMessage.category].groups[standardMessage.groupDescription].messages[standardMessage.suggestedReplyId] = standardMessage;
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
    categories[oldStandardMessage.category].groups[oldStandardMessage.groupDescription].messages.remove(oldStandardMessage.suggestedReplyId);
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

  model.SuggestedReply createMessage(String category, String groupDescription) {
    var newStandardMessage = model.SuggestedReply()
      ..docId = model.generateStandardMessageId()
      ..text = ''
      ..translation = ''
      ..shortcut = ''
      ..seqNumber = lastStandardMessageSeqNo
      ..category = category
      ..groupId = categories[category].groups[groupDescription].groupId
      ..groupDescription = groupDescription
      ..indexInGroup = getNextIndexInGroup(category, groupDescription);
    addStandardMessage(newStandardMessage);
    editedMessages[newStandardMessage.suggestedReplyId] = newStandardMessage;
    return newStandardMessage;
  }

  model.SuggestedReply modifyMessage(String id, String text, String translation) {
    var message = standardMessages.singleWhere((element) => element.suggestedReplyId == id);
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

  model.SuggestedReply deleteMessage(String id) {
    var message = standardMessages.singleWhere((element) => element.suggestedReplyId == id);
    removeStandardMessage(message);
    editedMessages.remove(id);
    deletedMessages[id] = message;
    return message;
  }

  MessageGroup createStandardMessagesGroup(String category, {String groupId, String groupDescription}) {
    var newGroupId = groupId ?? model.generateStandardMessageGroupId();
    var newMessageGroup = new MessageGroup(newGroupId, groupDescription ?? "message group $nextStandardMessagesGroupSeqNo");
    categories[category].groups[newMessageGroup.groupDescription] = newMessageGroup;
    return newMessageGroup;
  }

  void renameStandardMessageGroup(String category, String groupDescription, String newGroupDescription) {
    var group = categories[category].groups.remove(groupDescription);
    group.groupDescription = newGroupDescription;
    for (var standardMessage in group.messages.values) {
      standardMessage.groupDescription = newGroupDescription;
      editedMessages[standardMessage.suggestedReplyId] = standardMessage;
    }
    categories[category].groups[newGroupDescription] = group;
  }

  void deleteStandardMessagesGroup(String category, String groupDescription) {
    var group = categories[category].groups.remove(groupDescription);
    deletedMessages.addAll(group.messages);
  }

  /// Creates a new messages category and returns its name.
  /// If [categoryName] is given, it will use that name, otherwise it will generate a placeholder name.
  String createStandardMessagesCategory([String categoryName]) {
    var newCategoryName = categoryName ?? "message category $nextStandardMessagesCategorySeqNo";
    var newCategory = new MessageCategory(newCategoryName);
    categories[newCategoryName] = newCategory;
    return newCategoryName;
  }

  /// Renames a messages category and propagates the change to all the messages in that category.
  /// Also adds these messages to the list of messages that have been edited and need to be saved.
  void renameStandardMessageCategory(String categoryName, String newCategoryName) {
    var category = categories.remove(categoryName);
    category.categoryName = newCategoryName;
    for (var standardMessage in category.messages) {
      standardMessage.category = newCategoryName;
      editedMessages[standardMessage.suggestedReplyId] = standardMessage;
    }
    categories[newCategoryName] = category;
  }

  /// Deletes the messages category with the given [categoryName], and the messages in that category.
  /// Also adds these messages to the list of messages to be deleted and need to be saved.
  void deleteStandardMessagesCategory(String categoryName) {
    var category = categories.remove(categoryName);
    deletedMessages.addEntries(category.messages.map((e) => MapEntry(e.suggestedReplyId, e)));
  }

  /// The messages that have been edited and need to be saved, stored as a `Map<tagId, Tag>`.
  Map<String, model.SuggestedReply> editedMessages = {};

  /// The messages that have been deleted and need to be saved, stored as a `Map<tagId, Tag>`.
  Map<String, model.SuggestedReply> deletedMessages = {};

  /// The message IDs that are arrived from editedMessages, deletedMessages
  Set<String> get unsavedMessageIds => editedMessages.entries.map((e) => e.value.docId);
  Set<String> get unsavedGroupIds => editedMessages.entries.map((e) => e.value.groupId);
  Set<String> get unsavedCategoryIds => editedMessages.entries.map((e) => e.value.category);

  /// Returns whether there's any edited or deleted messages to be saved.
  bool get hasUnsavedMessages => editedMessages.isNotEmpty || deletedMessages.isNotEmpty;
}


class MessageCategory {
  String categoryName;
  Map<String, MessageGroup> groups = {};

  MessageCategory(this.categoryName);

  List<model.SuggestedReply> get messages => groups.values.fold([], (result, group) => result..addAll(group.messages.values));

  String toString() {
    return 'MessageGroup($categoryName, $groups)';
  }
}

class MessageGroup {
  String groupId;
  String groupDescription;
  Map<String, model.SuggestedReply> messages = {};

  MessageGroup(this.groupId, this.groupDescription);

  @override
  String toString() {
    return 'MessageGroup($groupId, $groupDescription, ${messages.length})';
  }
}
