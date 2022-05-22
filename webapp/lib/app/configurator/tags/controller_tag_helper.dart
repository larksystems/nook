part of controller;

class TagGroup {
  String groupId;
  String groupName;
  int groupIndex;
  
  TagGroup(this.groupId, this.groupName, this.groupIndex);
}

class TagManager {
  static final TagManager _singleton = TagManager._internal();
  TagManager._internal();
  factory TagManager() => _singleton;

  Map<String, TagGroup> localTagGroupsById = {};
  Map<String, TagGroup> storageTagGroupsById = {};

  Map<String, model.Tag> localTagsById = {};
  Map<String, model.Tag> storageTagsById = {};

  Set<String> editedTagIds = {};
  Set<String> deletedTagIds = {};

  Set<String> editedGroupIds = {};

  List<model.Tag> get tagsInLocal => localTagsById.values.toList();
  List<model.Tag> get tagsInStorage => storageTagsById.values.toList();

  Map<String, List<model.Tag>> get localTagsByCategoryId {
    Map<String, List<model.Tag>> result = {};
    tagsInLocal.forEach((tag) {
      for (var categoryId in tag.groupIds) {
        result[categoryId] = result[categoryId] ?? [];
        result[categoryId].add(tag);
      }
    });
    return result;
  }
  Map<String, List<model.Tag>> get storageTagsByCategoryId {
    Map<String, List<model.Tag>> result = {};
    tagsInStorage.forEach((tag) {
      for (var categoryId in tag.groupIds) {
        result[categoryId] = result[categoryId] ?? [];
        result[categoryId].add(tag);
      }
    });
    return result;
  }

  bool get hasUnsavedTags => editedTagIds.isNotEmpty || deletedTagIds.isNotEmpty || editedGroupIds.isNotEmpty;

  int _getNextGroupIndex() {
    var lastIndex = localTagGroupsById.values
      .map((tagGroup) => tagGroup.groupIndex)
      .reduce(max);
    return lastIndex + 1;
  }

  void markAsEditedTag(String id) {
    editedTagIds.add(id);
  }

  void markAsDeletedTag(String id) {
    deletedTagIds.add(id);
  }

  model.Tag createTagInLocal(String groupId) {
    var tag = model.Tag()
      ..docId = model.generateTagId()
      ..filterable = true
      ..groupIds = [groupId]
      ..groupIndices = [localTagGroupsById[groupId].groupIndex]
      ..groupNames = [localTagGroupsById[groupId].groupName]
      ..isUnifier = false
      ..text = ''
      ..shortcut = ''
      ..visible = true
      ..type = model.TagType.normal;
    populateTagInLocal(tag);
    return tag;
  }

  List<model.Tag> populateTagsInLocal(List<model.Tag> tags) {
    for (var tag in tags) {
      populateTagInLocal(tag);
    }

    return tags;
  }

  model.Tag populateTagInLocal(model.Tag tag) {
    localTagsById[tag.tagId] = tag;
    for(var i = 0; i < tag.groupIds.length; ++i) {
      localTagGroupsById[tag.groupIds[i]] = TagGroup(tag.groupIds[i], tag.groupNames[i], tag.groupIndices[i]);
    }
    _updateGroupDetailsInLocalTags();
    return tag;
  }

  TagGroup createGroupInLocal(String name) {
    var id = model.generateTagGroupId();
    var group = TagGroup(id, name, _getNextGroupIndex());
    localTagGroupsById[id] = group;
    editedGroupIds.add(id);
    return group;
  }

  void renameGroupInLocal(String id, String name) {
    if (!localTagGroupsById.containsKey(id)) {
      log.warning("renameGroupInLocal: Unable to find group with id $id");
      return;
    }
    _updateGroupDetailsInLocalTags();
    localTagGroupsById[id].groupName = name;
    editedGroupIds.add(id);
    // todo: eb: add edited tags
  }

  void removeAllTagsFromGroupInLocal(String groupId) {
    if (!localTagGroupsById.containsKey(groupId)) {
      log.warning("removeAllTagsFromGroupInLocal: Unable to find group with id $groupId");
      return;
    }

    tagsInLocal.forEach((tag) {
      tag.groupIds.remove(groupId);
    });
    _updateGroupDetailsInLocalTags();
  }

  model.Tag updateTypeInLocal(String id, model.TagType newType) {
    localTagsById[id].type = newType;
    editedTagIds.add(id);
    return localTagsById[id];
  }

  model.Tag updateTextInLocal(String id, String newText) {
    localTagsById[id].text = newText;
    editedTagIds.add(id);
    return localTagsById[id];
  }

  void reorderGroupInLocal(String id, int index) {
    if (!localTagGroupsById.containsKey(id)) {
      log.warning("_renameGroupInLocal: Unable to find group with id $id");
      return;
    }
    var groupIds = localTagGroupsById.values.map((tagGroup) => tagGroup.groupId).toList();
    groupIds.sort((groupIdA, groupIdB) => localTagGroupsById[groupIdA].groupIndex.compareTo(localTagGroupsById[groupIdB].groupIndex));
    groupIds.remove(id);
    groupIds.insert(index, id);
    _updateGroupDetailsInLocalTags();
  }

  List<model.Tag> removeTagsInLocal(List<String> tagIds) {
    return tagIds.map((id) => removeTagInLocal(id)).toList();
  }

  model.Tag removeTagInLocal(String tagId) {
    deletedTagIds.add(tagId);
    var tagToRemove = localTagsById.remove(tagId);
    return tagToRemove;
  }

  model.Tag addTagToLocalGroup(model.Tag tag, String groupId) {
    localTagsById[tag.tagId] = tag;
    if (!tag.groupIds.contains(groupId)) {
      tag.groupIds.add(groupId);
    }
    _updateGroupDetailsInLocalTags();
    return tag;
  }

  model.Tag removeTagFromLocalGroup(String tagId, String groupId, {bool skipUpdate = false}) {
    var removed = localTagsById[tagId].groupIds.remove(groupId);
    if (!removed) {
      log.warning("_removeTagFromLocalGroup: Unable to find tag $tagId in group $groupId");
    }
    if (!skipUpdate) {
      _updateGroupDetailsInLocalTags();
    }
    return localTagsById[tagId];
  }

  void moveTagAcrossLocalGroup(String tagId, String fromGroupId, String toGroupId) {
    if (fromGroupId == toGroupId) return;
    if (!localTagsById.containsKey(tagId)) {
      log.warning("_moveTag: Unable to find tag $tagId");
    }
    localTagsById[tagId].groupIds.remove(fromGroupId);
    localTagsById[tagId].groupIds.add(toGroupId);
    _updateGroupDetailsInLocalTags();
  }

  List<model.Tag> populateTagsInStorage(List<model.Tag> tags) {
    for (var tag in tags) {
      populateTagInStorage(tag);
    }
    return tags;
  }

  model.Tag populateTagInStorage(model.Tag tag) {
    storageTagsById[tag.tagId] = tag;
    for(var i = 0; i < tag.groupIds.length; ++i) {
      storageTagGroupsById[tag.groupIds[i]] = TagGroup(tag.groupIds[i], tag.groupNames[i], tag.groupIndices[i]);
    }
    _updateGroupDetailsInStorageTags();
    // todo: eb: check for diff
    populateTagInLocal(tag);
    return tag;
  }

  List<model.Tag> removeTagsFromStorage(List<String> tagIds) {
    return tagIds.map((id) => removeTagFromStorage(id)).toList();
  }

  model.Tag removeTagFromStorage(String tagId) {
    var removedTag = storageTagsById.remove(tagId);
    return removedTag;
  }

  void _updateGroupDetailsInLocalTags() {
    localTagsById.removeWhere((key, tag) {
      if (tag.groupIds.isEmpty) {
        deletedTagIds.add(tag.tagId);
      }
      return tag.groupIds.isEmpty;
    });
    localTagsById.values.forEach((tag) {
      tag.groupNames = tag.groupIds.map((id) => localTagGroupsById[id].groupName).toList();
      tag.groupIndices = tag.groupIds.map((id) => localTagGroupsById[id].groupIndex).toList();
    });
  }

  void _updateGroupDetailsInStorageTags() {
    storageTagsById.values.forEach((tag) {
      tag.groupNames = tag.groupIds.map((id) => storageTagGroupsById[id].groupName).toList();
      tag.groupIndices = tag.groupIds.map((id) => storageTagGroupsById[id].groupIndex).toList();
    });
  }
}
