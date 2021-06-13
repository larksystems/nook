part of controller;

void _addTagsToView(Map<String, List<model.Tag>> tagsByCategory, {bool editable = false}) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    if (!_view.groups.containsKey(category)) {
      _view.addTagCategory(category, new TagGroupView(category));
    }
    Map<String, kk.TagView> tagsById = {};
    for (var tag in tagsByCategory[category]) {
      tagsById[tag.tagId] = new ConfigureTagView(tag.text, tag.docId, category, _tagTypeToKKStyle(tag.type));
      if (editable) {
        tagsById[tag.tagId].makeEditable();
      }
    }
    _view.groups[category].addTags(tagsById);
    if (editable) {
      tagsById[tagsByCategory[category].last.tagId].focusEditText();
      tagsById[tagsByCategory[category].last.tagId].onCancel = () {
        _view.appController.command(TagsConfigAction.removeTag, new TagData(tagsByCategory[category].last.tagId, groupId: category));
      };
    }
  }
}

void _removeTagsFromView(Map<String, List<model.Tag>> tagsByCategory) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    _view.groups[category].removeTags(tagsByCategory[category].map((t) => t.tagId).toList());
  }
}

void _modifyTagsInView(Map<String, List<model.Tag>> tagsByCategory) {
  for (var category in tagsByCategory.keys.toList()..sort()) {
    Map<String, kk.TagView> tagViewsById = {};
    for (var tag in tagsByCategory[category]) {
      tagViewsById[tag.tagId] = new ConfigureTagView(tag.text, tag.docId, category, _tagTypeToKKStyle(tag.type));
    }
    _view.groups[category].modifyTags(tagViewsById);
  }
}

Map<String, List<model.Tag>> _groupTagsIntoCategories(List<model.Tag> tags) {
  Map<String, List<model.Tag>> result = {};
  for (model.Tag tag in tags) {
    if (tag.groups.isEmpty) {
      if (tag.group.isEmpty) {
        result.putIfAbsent("", () => []).add(tag);
        continue;
      }
      result.putIfAbsent(tag.group, () => []).add(tag);
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

kk.TagStyle _tagTypeToKKStyle(model.TagType tagType) {
  switch (tagType) {
    case model.TagType.Important:
      return kk.TagStyle.Important;
    default:
      if (tagType == model.NotFoundTagType.NotFound) {
        return kk.TagStyle.Yellow;
      }
      return kk.TagStyle.None;
  }
}
