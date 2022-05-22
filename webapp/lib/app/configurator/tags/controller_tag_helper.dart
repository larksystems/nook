part of controller;

class TagGroup {
  String groupId;
  String groupName;
  int groupIndex;
  List<model.Tag> tags = [];
  
  TagGroup(this.groupId, this.groupName, this.groupIndex);
}

class TagManager {
  static final TagManager _singleton = TagManager._internal();
  TagManager._internal();
  factory TagManager() => _singleton;

  // store for tags
  Map<String, model.Tag> localTagsById = {};
  Map<String, model.Tag> storageTagsById = {};

  Map<String, TagGroup> localGroupsById = {};
  Map<String, TagGroup> storageGroupsById = {};

  List<model.Tag> get tagsInLocal => localTagsById.values.toList();
  List<model.Tag> get tagsInStorage => storageTagsById.values.toList();

  Map<String, List<model.Tag>> get localTagsByGroupId {
    Map<String, List<model.Tag>> result = {};
    localGroupsById.forEach((groupId, tagGroup) => result[groupId] = tagGroup.tags);
    return result;
  }

  // local tag methods
  model.Tag createTagInLocal(String groupId) {
    var tag = model.Tag()
      ..docId = model.generateTagId()
      ..filterable = true
      ..groupIds = [groupId]
      ..groupIndices = [localGroupsById[groupId].groupIndex]
      ..groupNames = [localGroupsById[groupId].groupName]
      ..isUnifier = false
      ..text = ''
      ..shortcut = ''
      ..visible = true
      ..type = model.TagType.normal;
    addOrUpdateTagInLocal(tag);
    return tag;
  }

  List<model.Tag> addOrUpdateTagsInLocal(List<model.Tag> tags) {
    for (var tag in tags) {
      addOrUpdateTagInLocal(tag);
    }
    return tags;
  }

  model.Tag addOrUpdateTagInLocal(model.Tag tag) {
    localTagsById[tag.tagId] = tag;
    for(var i = 0; i < tag.groupIds.length; ++i) {
      localGroupsById[tag.groupIds[i]] = localGroupsById[tag.groupIds[i]] ?? TagGroup(tag.groupIds[i], tag.groupNames[i], tag.groupIndices[i]);
      localGroupsById[tag.groupIds[i]].tags.removeWhere((_tag) => _tag.tagId == tag.tagId);
      localGroupsById[tag.groupIds[i]].tags.add(tag);
    }
    _updateGroupDetailsInLocalTags();
    return tag;
  }

  model.Tag updateTagTextInLocal(String id, String newText) {
    localTagsById[id].text = newText;
    addEditedTag(id);
    return localTagsById[id];
  }

  model.Tag updateTagTypeInLocal(String id, model.TagType newType) {
    localTagsById[id].type = newType;
    addEditedTag(id);
    return localTagsById[id];
  }

  model.Tag moveTagAcrossLocalGroups(String tagId, String oldGroup, String newGroup) {
    var tag = localTagsById[tagId];
    tag.groupIds
      ..remove(oldGroup)
      ..add(newGroup);
    _updateGroupDetailsInLocalTags();
    return tag;
  }

  List<model.Tag> removeTagsInLocal(List<String> tagIds) {
    return tagIds.map((id) => removeTagInLocal(id)).toList();
  }

  model.Tag removeTagInLocal(String tagId) {
    addDeltedTag(tagId);
    var tagToRemove = localTagsById.remove(tagId);
    return tagToRemove;
  }

  // local group methods
  TagGroup createGroupInLocal(String name) {
    var id = model.generateTagGroupId();
    var group = TagGroup(id, name, _getNextGroupIndex());
    localGroupsById[id] = group;
    addEditedGroup(id);
    return group;
  }

  void renameGroupInLocal(String id, String name) {
    localGroupsById[id].groupName = name;
    addEditedGroup(id);
    _updateGroupDetailsInLocalTags();
  }

  void reorderGroupInLocal(String id, int index) {
    // todo: eb: test this when we have the functionality
    var groupIds = localGroupsById.values.map((tagGroup) => tagGroup.groupId).toList();
    groupIds.sort((groupIdA, groupIdB) => localGroupsById[groupIdA].groupIndex.compareTo(localGroupsById[groupIdB].groupIndex));
    groupIds.remove(id);
    groupIds.insert(index, id);
    _updateGroupDetailsInLocalTags();
  }

  void removeGroupAndTagsinLocal(String groupId) {
    localTagsById.forEach((_, tag) => tag.groupIds.remove(groupId));
    localTagsById.removeWhere((key, tag) {
      var groupsEmpty = tag.groupIds.isEmpty;
      if (groupsEmpty) {
        addDeltedTag(tag.tagId);
      }
      return groupsEmpty;
    });
    
    _updateGroupDetailsInLocalTags();
  }

  // storage methods
  List<model.Tag> addOrUpdateTagsInStorage(List<model.Tag> tags) {
    for (var tag in tags) {
      addOrUpdateTagInStorage(tag);
    }
    return tags;
  }

  model.Tag addOrUpdateTagInStorage(model.Tag tag) {
    storageTagsById[tag.tagId] = tag;
    for(var i = 0; i < tag.groupIds.length; ++i) {
      storageGroupsById[tag.groupIds[i]] = storageGroupsById[tag.groupIds[i]] ?? TagGroup(tag.groupIds[i], tag.groupNames[i], tag.groupIndices[i]);
      storageGroupsById[tag.groupIds[i]].tags.removeWhere((_tag) => _tag.tagId == tag.tagId);
      storageGroupsById[tag.groupIds[i]].tags.add(tag);
    }
    _updateGroupDetailsInStorageTags();
    // todo: clear edited tags, deleted tags, edited groups
    // todo: eb: check for diff as a next step
    addOrUpdateTagInLocal(tag);
    removeEditedTag(tag.tagId);
    return tag;
  }

  List<model.Tag> removeTagsFromStorage(List<String> tagIds) {
    return tagIds.map((id) => removeTagFromStorage(id)).toList();
  }

  model.Tag removeTagFromStorage(String tagId) {
    var removedTag = storageTagsById.remove(tagId);
    removeDeletedTag(tagId);
    return removedTag;
  }

  // tag helper methods
  int _getNextGroupIndex() {
    var lastIndex = localGroupsById.values
      .map((tagGroup) => tagGroup.groupIndex)
      .reduce(max);
    return lastIndex + 1;
  }

  void _updateGroupDetailsInLocalTags() {
    localTagsById.values.forEach((tag) {
      tag.groupNames = tag.groupIds.map((id) => localGroupsById[id].groupName).toList();
      tag.groupIndices = tag.groupIds.map((id) => localGroupsById[id].groupIndex).toList();
    });
  }

  void _updateGroupDetailsInStorageTags() {
    storageTagsById.values.forEach((tag) {
      tag.groupNames = tag.groupIds.map((id) => storageGroupsById[id].groupName).toList();
      tag.groupIndices = tag.groupIds.map((id) => storageGroupsById[id].groupIndex).toList();
    });
  }

  // edited tags, groups
  Set<String> _editedTagIds = {};
  Set<String> _deletedTagIds = {};
  Set<String> _editedGroupIds = {};

  bool get hasUnsavedTags => _editedTagIds.isNotEmpty || _deletedTagIds.isNotEmpty || _editedGroupIds.isNotEmpty;
  Set<String> get editedTagIds => _editedTagIds;
  Set<String> get deletedTagIds => _deletedTagIds;
  Set<String> get editedGroupIds => _editedGroupIds;

  List<model.Tag> get editedTags {
    var allEditedTagIds = Set.from(editedTagIds);
    editedGroupIds.forEach((groupId) {
      localGroupsById[groupId].tags.forEach((tag) {
        allEditedTagIds.add(tag.tagId);
      });
    });

    // todo: eb: remove deleted IDs here
    return allEditedTagIds.map((tagId) => localTagsById[tagId]).toList();
  }

  List<model.Tag> get deletedTags {
    List<model.Tag> tags = [];
    deletedTagIds.forEach((tagId) {
      tags.add(storageTagsById[tagId]);
    });
    return tags;
  }

  void addEditedTag(String tagId) {
    _editedTagIds.add(tagId);
  }

  void removeEditedTag(String tagId) {
    _editedTagIds.remove(tagId);
  }

  void removeAllEditedTags() {
    _editedTagIds.clear();
  }

  void addDeltedTag(String tagId) {
    _deletedTagIds.add(tagId);
  }

  void removeDeletedTag(String tagId) {
    _deletedTagIds.remove(tagId);
  }

  void removeAllDeletedTags() {
    _deletedTagIds.clear();
  }

  void addEditedGroup(String groupId) {
    _editedGroupIds.add(groupId);
  }

  void removeEditedGroup(String groupId) {
    _editedGroupIds.remove(groupId);
  }

  void removeAllEditedGroups() {
    _editedGroupIds.clear();
  } 
}
