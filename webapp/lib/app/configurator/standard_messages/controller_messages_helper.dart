part of controller;


class StandardMessagesManager {
  static final StandardMessagesManager _singleton = StandardMessagesManager._internal();

  StandardMessagesManager._internal();

  factory StandardMessagesManager() => _singleton;

  int _lastStandardMessageSeqNo = 0;
  int _lastStandardMessagesGroupSeqNo = 0;

  int get lastStandardMessageSeqNo => _lastStandardMessageSeqNo;
  int get nextStandardMessageSeqNo => ++_lastStandardMessageSeqNo;

  int get lastStandardMessagesGroupSeqNo => _lastStandardMessagesGroupSeqNo;
  int get nextStandardMessagesGroupSeqNo => ++_lastStandardMessagesGroupSeqNo;

  String get nextStandardMessageId {
    var seqNo = nextStandardMessageSeqNo;
    String paddedSeqNo = seqNo.toString().padLeft(6, '0');
    return 'reply-${paddedSeqNo}';
  }

  String get nextStandardMessagesGroupId {
    var seqNo = nextStandardMessagesGroupSeqNo;
    String paddedSeqNo = seqNo.toString().padLeft(6, '0');
    return 'reply-group-${paddedSeqNo}';
  }

  void _updateLastStandardMessageSeqNo(int seqNo) {
    if (seqNo < _lastStandardMessageSeqNo) return;
    _lastStandardMessageSeqNo = seqNo;
  }

  void _updateLastStandardMessagesGroupSeqNo(String groupId) {
    var seqNo = int.parse(groupId.split('reply-group-').last);
    if (seqNo < _lastStandardMessagesGroupSeqNo) return;
    _lastStandardMessagesGroupSeqNo = seqNo;
  }


  List<model.SuggestedReply> _standardMessages = [];
  List<model.SuggestedReply> get standardMessages => _standardMessages;

  Map<String, List<model.SuggestedReply>> _standardMessagesByCategory = {};
  Map<String, List<model.SuggestedReply>> get standardMessagesByCategory => _standardMessagesByCategory;

  Map<String, String> emptyGroups = {};

  Map<String, String> get groups => Map.fromEntries(_standardMessages.map((e) => MapEntry(e.groupId, e.groupDescription)));

  List<String> get categories => _standardMessagesByCategory.keys.toList()..sort();

  int getNextIndexInGroup(String groupId) {
    var standardMessagesInGroup = _standardMessages.where((r) => r.groupId == groupId);
    var lastIndexInGroup = standardMessagesInGroup.fold(0, (previousValue, r) => previousValue > r.indexInGroup ? previousValue : r.indexInGroup);
    return lastIndexInGroup + 1;
  }

  model.SuggestedReply getStandardMessageById(String id) => _standardMessages.singleWhere((r) => r.suggestedReplyId == id);


  void addStandardMessage(model.SuggestedReply standardMessage) => addStandardMessages([standardMessage]);

  void addStandardMessages(List<model.SuggestedReply> standardMessages) {
    for (var standardMessage in standardMessages) {
      if (_standardMessages.where((element) => element.suggestedReplyId == standardMessage.suggestedReplyId).isNotEmpty) {
        updateStandardMessage(standardMessage);
        continue;
      }
      _standardMessages.add(standardMessage);
      _standardMessagesByCategory.putIfAbsent(standardMessage.category, () => []);
      _standardMessagesByCategory[standardMessage.category].add(standardMessage);
      _updateLastStandardMessageSeqNo(standardMessage.seqNumber);
      _updateLastStandardMessagesGroupSeqNo(standardMessage.groupId);
      var groupDescription = emptyGroups.remove(standardMessage.groupId);
      updateStandardMessagesGroupDescription(standardMessage.groupId, groupDescription ?? standardMessage.groupDescription);
    }
  }

  void updateStandardMessage(model.SuggestedReply standardMessages) => updateStandardMessages([standardMessages]);

  void updateStandardMessages(List<model.SuggestedReply> standardMessages) {
    for (var standardMessage in standardMessages) {
      var oldStandardMessage = _standardMessages.singleWhere((r) => r.suggestedReplyId == standardMessage.suggestedReplyId);
      var index = _standardMessages.indexOf(oldStandardMessage);
      _standardMessages.replaceRange(index, index + 1, [standardMessage]);
      index = _standardMessagesByCategory[standardMessage.category].indexOf(oldStandardMessage);
      _standardMessagesByCategory[standardMessage.category].replaceRange(index, index + 1, [standardMessage]);
    }
  }

  void updateStandardMessagesGroupDescription(String id, String newDescription) {
    if (emptyGroups.containsKey(id)) {
      emptyGroups[id] = newDescription;
      return;
    }
    for (var standardMessage in _standardMessages) {
      if (standardMessage.groupId != id) continue;
      standardMessage.groupDescription = newDescription;
    }
  }

  void removeStandardMessage(model.SuggestedReply standardMessage) => removeStandardMessages([standardMessage]);

  void removeStandardMessages(List<model.SuggestedReply> standardMessages) {
    var standardMessagesIds = new Set()..addAll(standardMessages.map((r) => r.suggestedReplyId));
    _standardMessages.removeWhere((standardMessage) => standardMessagesIds.contains(standardMessage.suggestedReplyId));
    for (var category in _standardMessagesByCategory.keys) {
      _standardMessagesByCategory[category].removeWhere((standardMessage) => standardMessagesIds.contains(standardMessage.suggestedReplyId));
    }
    for (var standardMessage in standardMessages) {
      if (!groups.containsKey(standardMessage.groupId)) {
        emptyGroups[standardMessage.groupId] = standardMessage.groupDescription;
      }
    }
    // Empty sublist if there are no messages to show
    if (_standardMessagesByCategory.isEmpty) {
      _standardMessagesByCategory[''] = [];
    }
  }

  void removeStandardMessagesGroup(String groupId) {
    List<model.SuggestedReply> standardMessagesToRemove = _standardMessages.where((r) => r.groupId == groupId).toList();
    removeStandardMessages(standardMessagesToRemove);
  }

}
