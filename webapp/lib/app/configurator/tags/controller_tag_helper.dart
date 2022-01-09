part of controller;

class TagManager {
  static final TagManager _singleton = TagManager._internal();

  TagManager._internal();

  factory TagManager() => _singleton;

  /// Returns the set of tags being managed.
  Set<model.Tag> get tags => Set.from(_tags);
  Set<model.Tag> _tags = {};

  /// Returns the set of tags being managed, organised by group.
  Map<String, List<model.Tag>> get tagsByGroup => _tagsByGroup;
  Map<String, List<model.Tag>> _tagsByGroup = {};

  /// Returns an automatically generated name for a new tag group.
  /// The name is based on an internal sequence, and verified against existing tag group names.
  /// If the next group in the sequence already exists, it will recursively try to generate a new one.
  String get nextTagGroupName {
    var newTagGroupNameProposal = 'new tag group $nextGroupSeqNo';
    if (tagsByGroup.containsKey(newTagGroupNameProposal)) {
      return nextTagGroupName;
    }
    return newTagGroupNameProposal;
  }

  /// Returns a new number in the group numbering sequence. Starts the sequence at 1.
  int get nextGroupSeqNo => ++_lastGroupSeqNo;
  int _lastGroupSeqNo = 0;

  /// Returns the [Tag] with the given [id].
  model.Tag getTagById(String id) => _tags.singleWhere((t) => t.tagId == id);

  /// Adds the given [tag] to the list of tags being managed.
  /// Returns either the [tag] if it's a new tag, or [null] if it already exists and it's an update operation.
  model.Tag addTag(model.Tag tag) {
    var added = addTags([tag]);
    if (added.isNotEmpty) return added.first;
    return null;
  }

  /// Adds the given list of [tags] to the list of tags being managed.
  /// Returns a list confirming which tags have been added as new tags. This allows the caller to account for
  /// tags being added multiple times, e.g. created via the UI and then saved and confirmed by the platform.
  List<model.Tag> addTags(List<model.Tag> tags) {
    List<model.Tag> added = [];
    for (var tag in tags) {
      if (_tags.any((t) => t.tagId == tag.tagId)) {
        _tags.removeWhere((t) => t.tagId == tag.tagId);
        _tags.add(tag);
      } else {
        _tags.add(tag);
        added.add(tag);
      }

      if (tag.groups.isEmpty) {
        _tagsByGroup.putIfAbsent('', () => []).add(tag);
        continue;
      }
      for (var group in tag.groups) {
        _tagsByGroup.putIfAbsent(group, () => []).add(tag);
      }
    }
    return added;
  }

  /// Updates the given [tag] in the list of tags being managed.
  /// Returns either the [tag] if it has been updated successfully,
  /// or [null] if the tag doesn't exist in the list of managed tags and so nothing has been updated.
  model.Tag updateTag(model.Tag tag) {
    var updated = updateTags([tag]);
    if (updated.isNotEmpty) return updated.first;
    return null;
  }

  /// Updates the given list of [tags] to the list of tags being managed.
  /// Returns a list confirming which tags have been updated sucessfully.
  /// Tags which don't yet exist in the list of managed tags won't be added to the returned list.
  List<model.Tag> updateTags(List<model.Tag> tags) {
    var removed = removeTags(tags);
    var updated = addTags(removed);
    if (removed.length != updated.length) {
      throw "Tag consistency error: The two-step update process has an inconsistency between the tags to be updated";
    }
    return updated;
  }

  /// Removes the given [tag] from the list of tags being managed.
  /// Returns either the [tag] if it's been removed successfully, or [null] if the tag has already been removed.
  model.Tag removeTag(model.Tag tag) {
    var removed = removeTags([tag]);
    if (removed.isNotEmpty) return removed.first;
    return null;
  }

  /// Removes the given list of [tags] from the list of tags being managed.
  /// Returns a list confirming which tags have been removed successfully. This allows the caller to account for
  /// tags being removed multiple times, e.g. removed via the UI and then saved and confirmed by the platform.
  List<model.Tag> removeTags(List<model.Tag> tags) {
    List<model.Tag> removed = [];
    for (var tag in tags) {
      if (!_tags.any((t) => t.tagId == tag.tagId)) {
        log.warning("Tag consistency error: Removing tag that doesn't exist, ${tag.tagId}");
        continue;
      }

      var oldTag = _tags.singleWhere((t) => t.tagId == tag.tagId, orElse: () => null);
      _tags.remove(oldTag);
      removed.add(tag);

      if (oldTag.groups.isEmpty) {
        _tagsByGroup[''].remove(oldTag);
        continue;
      }
      for (var group in oldTag.groups) {
        _tagsByGroup[group].remove(oldTag);
      }
    }
    return removed;
  }

  /// Creates and returns a new tag in the given tag [group].
  /// Also adds the tag to the list of tags that have been edited and need to be saved.
  model.Tag createTag(String group) {
    var tag = new model.Tag()
      ..docId = model.generateTagId()
      ..filterable = true
      ..groups = [group]
      ..isUnifier = false
      ..text = ''
      ..shortcut = ''
      ..visible = true
      ..type = model.TagType.normal;
    addTag(tag);
    editedTags[tag.tagId] = tag;
    return tag;
  }

  /// Returns a copy of the original tag with the given [id], with the given new [text] and/or [group].
  /// Also adds the tag to the list of tags that have been edited and need to be saved.
  model.Tag modifyTag(String id, {String text, String group, model.TagType type}) {
    model.Tag tag = getTagById(id);
    model.Tag newTag = model.Tag.fromData(tag.toData())..docId = tag.tagId;
    if (text != null) {
      newTag.text = text;
    }
    if (group != null) {
      newTag.groups = [group];
    }
    if (type != null) {
      newTag.type = type;
    }
    updateTag(newTag);
    editedTags[newTag.tagId] = newTag;
    return newTag;
  }

  /// Deletes the tag with the given [id] from the managed list.
  /// Also adds the tag to the list of tags to be deleted and need to be saved.
  model.Tag deleteTag(String id) {
    model.Tag tag = getTagById(id);
    removeTag(tag);
    editedTags.remove(tag.tagId);
    deletedTags[tag.tagId] = tag;
    return tag;
  }

  /// Creates a new tag group and returns its name.
  /// If [groupName] is given, it will use that name, otherwise it will generate a placeholder name.
  String createTagGroup([String groupName]) {
    var newGroupName = groupName ?? nextTagGroupName;
    _tagsByGroup[newGroupName] = [];
    return newGroupName;
  }

  /// Renames a tag group and propagates the change to all tags in the group.
  /// Adds the modified tags to the list of tags that have been edited and need to be saved.
  void renameTagGroup(String groupName, String newGroupName) {
    createTagGroup(newGroupName);
    var tagsToModify = _tagsByGroup[groupName].toList();
    for (var tag in tagsToModify) {
      modifyTag(tag.tagId, group: newGroupName);
    }
    _tagsByGroup.remove(groupName);
  }

  /// Deletes the tag group with the given [groupName] and the tags in that group from the managed list of tags.
  /// Also adds these tags to the list of tags to be deleted and need to be saved.
  void deleteTagGroup(String groupName) {
    var tagsToDelete = _tagsByGroup[groupName].toList();
    for (var tag in tagsToDelete) {
      deleteTag(tag.tagId);
    }
    _tagsByGroup.remove(groupName);
  }

  /// The tags that have been edited and need to be saved, stored as a `Map<tagId, Tag>`.
  Map<String, model.Tag> editedTags = {};

  /// The tags that have been deleted and need to be saved, stored as a `Map<tagId, Tag>`.
  Map<String, model.Tag> deletedTags = {};

  /// When a tag is moved across groups, we need to remember the origin group
  Set<String> movedFromGroupIds = {};

  /// Getters for unsaved tag Ids, group Ids derived from editedTags, deletedTags
  Set<String> get unsavedTagIds => Set.from(List.from(editedTags.keys)..addAll(deletedTags.keys));
  Set<String> get unsavedGroupIds {
    window.console.error(movedFromGroupIds);
    var editedTagGroups = editedTags.values.map((tag) => tag.groups).expand((e) => e); //.toList();
    var deletedTagGroups = deletedTags.values.map((tag) => tag.groups).expand((e) => e); //.toList();
    Set<String> setString = Set.from(List.from(editedTagGroups)..addAll(deletedTagGroups))..addAll(movedFromGroupIds);
    window.console.error(setString);
    return setString;
  }

  /// Returns whether there's any edited or deleted tags to be saved.
  bool get hasUnsavedTags => editedTags.isNotEmpty || deletedTags.isNotEmpty || movedFromGroupIds.isNotEmpty;
}
