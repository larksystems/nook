part of controller;

List<MenuItem> getMenuItems(model.Tag tag) {
  bool tagImportant = tag.type == model.TagType.important;
  var markAsImportant = DivElement()..innerText = tagImportant? "Mark tag as normal" : "Mark tag as important";
  var copyId = DivElement()..innerText = "Copy ID";
  return [
    MenuItem(markAsImportant, () {
      _view.appController.command(TagsConfigAction.updateTagType, new TagData(tag.tagId, groupId: tag.groupIds.first, newType: tagImportant ? model.TagType.normal : model.TagType.important));
    }),
    MenuItem(copyId, () {
      window.navigator.clipboard.writeText(tag.tagId);
      _view.snackbarView.showSnackbar("Tag ID copied!", SnackbarNotificationType.info);
    })
  ];
}

void _addTagsToView(Map<String, List<model.Tag>> tagsByCategory, Map<String, TagGroup> tagGroupById, {bool startEditing = false, bool startEditingName = false}) {
  var sortedCategoryIds = tagsByCategory.keys.toList()
    ..sort((id1, id2) => tagGroupById[id1].groupIndex.compareTo(tagGroupById[id2].groupIndex));
  for (var categoryId in sortedCategoryIds) {
    if (_view.groups.queryItem(categoryId) == null) {
      _view.addTagCategory(categoryId, new TagGroupView(categoryId, tagGroupById[categoryId].groupName, DivElement(), DivElement()));
    }
    Map<String, TagView> tagsById = {};
    for (var tag in tagsByCategory[categoryId]) {
      tagsById[tag.tagId] = new ConfigureTagView(tag.text, tag.docId, categoryId, _tagTypeToKKStyle(tag.type), getMenuItems(tag));
      if (startEditing) {
        tagsById[tag.tagId].beginEdit();
      }
    }
    var groupView = _view.groups.queryItem(categoryId) as TagGroupView;
    groupView.addTags(tagsById);
    if (startEditing) {
      tagsById[tagsByCategory[categoryId].last.tagId].focus();
      tagsById[tagsByCategory[categoryId].last.tagId].onCancel = () {
        _view.appController.command(TagsConfigAction.removeTag, new TagData(tagsByCategory[categoryId].last.tagId, groupId: categoryId));
      };
    }
    if (startEditingName) {
      groupView.editableTitle.beginEdit(selectAllOnFocus: true);
      groupView.expand();
    }
  }
}

void _removeTagsFromView(Map<String, List<model.Tag>> tagsByCategory) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    (_view.groups.queryItem(category) as TagGroupView).removeTags(tagsByCategory[category].map((t) => t.tagId).toList());
  }
}

void _modifyTagsInView(Map<String, List<model.Tag>> tagsByCategory, Map<String, TagGroup> tagGroupById) {
  for (var categoryId in tagsByCategory.keys) {
    Map<String, TagView> tagViewsById = {};
    for (var tag in tagsByCategory[categoryId]) {
      tagViewsById[tag.tagId] = new ConfigureTagView(tag.text, tag.docId, categoryId, _tagTypeToKKStyle(tag.type), getMenuItems(tag));
    }
    (_view.groups.queryItem(categoryId) as TagGroupView).modifyTags(tagViewsById);
  }
}

void _updateUnsavedIndicators(Map<String, List<model.Tag>> tagsByGroup, Set<String> unsavedTagIds, Set<String> unsavedGroupIds) {
  for (var category in tagsByGroup.keys) {
    var categoryView = (_view.groups.queryItem(category) as TagGroupView);
    categoryView.markAsUnsaved(unsavedGroupIds.contains(category));
    categoryView.tagViewsById.keys.forEach((key) {
      categoryView.tagViewsById[key].markAsUnsaved(unsavedTagIds.contains(key));
    });
  }
}

Map<String, List<model.Tag>> _groupTagsIntoCategories(List<model.Tag> tags) {
  Map<String, List<model.Tag>> result = {};
  for (model.Tag tag in tags) {
    if (tag.groupIds.isEmpty) {
      result.putIfAbsent("", () => []).add(tag);
      continue;
    }
    for (var group in tag.groupIds) {
      result.putIfAbsent(group, () => []).add(tag);
    }
  }
  // Sort tags alphabetically
  for (var tags in result.values) {
    tags.sort((t1, t2) => t1.text.compareTo(t2.text));
  }
  return result;
}

TagStyle _tagTypeToKKStyle(model.TagType tagType) {
  switch (tagType) {
    case model.TagType.important:
      return TagStyle.Important;
    default:
      if (tagType == model.NotFoundTagType.NotFound) {
        return TagStyle.Yellow;
      }
      return TagStyle.None;
  }
}

void _showDuplicateTagWarningModal(String groupId, String tagId, String text) {
  TagGroupView group = _view.groups.queryItem(groupId);
  group?.showDuplicateWarningModal(tagId, text);
}
