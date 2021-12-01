part of controller;

List<MenuItem> getMenuItems(model.Tag tag) {
  bool tagImportant = tag.type == model.TagType.important;
  var markAsImportant = DivElement()..innerText = tagImportant? "Mark tag as normal" : "Mark tag as important";
  var copyId = DivElement()..innerText = "Copy ID";
  return [
    MenuItem(markAsImportant, () {
      _view.appController.command(TagsConfigAction.updateTagType, new TagData(tag.tagId, newType: tagImportant ? model.TagType.normal : model.TagType.important));
    }),
    MenuItem(copyId, () {
      window.navigator.clipboard.writeText(tag.tagId);
      _view.snackbarView.showSnackbar("Tag ID copied!", SnackbarNotificationType.info);
    })
  ];
}

void _addTagsToView(Map<String, List<model.Tag>> tagsByCategory, {bool startEditing = false, bool startEditingName = false}) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    if (_view.groups.queryItem(category) == null) {
      _view.addTagCategory(category, new TagGroupView(category, category, DivElement(), DivElement()));
    }
    Map<String, TagView> tagsById = {};
    for (var tag in tagsByCategory[category]) {
      tagsById[tag.tagId] = new ConfigureTagView(tag.text, tag.docId, category, _tagTypeToKKStyle(tag.type), getMenuItems(tag));
      if (startEditing) {
        tagsById[tag.tagId].beginEdit();
      }
    }
    var groupView = _view.groups.queryItem(category) as TagGroupView;
    groupView.addTags(tagsById);
    if (startEditing) {
      tagsById[tagsByCategory[category].last.tagId].focus();
      tagsById[tagsByCategory[category].last.tagId].onCancel = () {
        _view.appController.command(TagsConfigAction.removeTag, new TagData(tagsByCategory[category].last.tagId, groupId: category));
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

void _modifyTagsInView(Map<String, List<model.Tag>> tagsByCategory) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    Map<String, TagView> tagViewsById = {};
    for (var tag in tagsByCategory[category]) {
      tagViewsById[tag.tagId] = new ConfigureTagView(tag.text, tag.docId, category, _tagTypeToKKStyle(tag.type), getMenuItems(tag));
    }
    (_view.groups.queryItem(category) as TagGroupView).modifyTags(tagViewsById);
  }
}

Map<String, List<model.Tag>> _groupTagsIntoCategories(List<model.Tag> tags) {
  Map<String, List<model.Tag>> result = {};
  for (model.Tag tag in tags) {
    if (tag.groups.isEmpty) {
      result.putIfAbsent("", () => []).add(tag);
      continue;
    }
    for (var group in tag.groups) {
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
