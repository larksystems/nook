part of controller;

class ConversationFilter {
  Map<TagFilterType, Set<model.Tag>> _filterTags;
  model.UserConfiguration userConfig;
  String conversationIdFilter;

  Set<model.Tag> getFilters(TagFilterType type) {
    return _filterTags[type].toSet();
  }

  bool addFilter(TagFilterType type, model.Tag tag) {
    var previous = _filterTags[type].toSet();
    _filterTags[type].add(tag);
    _applyMandatoryFilters();
    var updated = _filterTags[type];
    // Dart doesn't seem to have a set equality test, test for same lengths and same elements
    bool isChanged = !(updated.length == previous.length && updated.every((e) => previous.contains(e)));
    return isChanged;
  }

  bool removeFilter(TagFilterType type, model.Tag tag) {
    var previous = _filterTags[type].toSet();
    _filterTags[type].remove(tag);
    _applyMandatoryFilters();
    var updated = _filterTags[type];
    // Dart doesn't seem to have a set equality test, test for same lengths and same elements
    bool isChanged = !(updated.length == previous.length && updated.every((e) => previous.contains(e)));
    return isChanged;
  }

  void clearFilters(TagFilterType type) {
    _filterTags[type].clear();
    _applyMandatoryFilters();
  }

  void updateUserConfig(model.UserConfiguration userConfig) {
    _removeMandatoryFilters();
    this.userConfig = userConfig;
    _applyMandatoryFilters();
  }

  ConversationFilter(model.UserConfiguration userConfig) {
    _filterTags = {TagFilterType.include: Set(), TagFilterType.exclude: Set(), TagFilterType.lastInboundTurn: Set()};

    updateUserConfig(userConfig);
    _applyMandatoryFilters();
    conversationIdFilter = "";
  }

  ConversationFilter.fromUrl(model.UserConfiguration userConfig) {
    _filterTags = {
      TagFilterType.include: _getTagsFromUrl(TagFilterType.include, controller.tagIdsToTags),
      TagFilterType.exclude: _getTagsFromUrl(TagFilterType.exclude, controller.tagIdsToTags),
      TagFilterType.lastInboundTurn: _getTagsFromUrl(TagFilterType.lastInboundTurn, controller.tagIdsToTags),
    };
    updateUserConfig(userConfig);
    _applyMandatoryFilters();

    conversationIdFilter = _view.urlManager.conversationIdFilter ?? "";
  }

  bool get isEmpty =>
      _filterTags[TagFilterType.include].isEmpty &&
      _filterTags[TagFilterType.exclude].isEmpty &&
      _filterTags[TagFilterType.lastInboundTurn].isEmpty &&
      conversationIdFilter == "";

  Map<TagFilterType, Set<String>> get filterTagIdsAll => {
        TagFilterType.include: tagsToTagIds(_filterTags[TagFilterType.include]).toSet(),
        TagFilterType.exclude: tagsToTagIds(_filterTags[TagFilterType.exclude]).toSet(),
        TagFilterType.lastInboundTurn: tagsToTagIds(_filterTags[TagFilterType.lastInboundTurn]).toSet()
      };

  Map<TagFilterType, Set<String>> get filterTagIdsManuallySet => {
        TagFilterType.include: tagsToTagIds(_filterTags[TagFilterType.include]).toSet()..removeWhere((tagId) => userConfig.mandatoryIncludeTagIds.contains(tagId)),
        TagFilterType.exclude: tagsToTagIds(_filterTags[TagFilterType.exclude]).toSet()..removeWhere((tagId) => userConfig.mandatoryExcludeTagIds.contains(tagId)),
        TagFilterType.lastInboundTurn: tagsToTagIds(_filterTags[TagFilterType.lastInboundTurn]).toSet()
      };

  bool test(model.Conversation conversation) {
    var tags = convertTagIdsToTags(conversation.tagIds, controller.tagIdsToTags);
    var unifierTags = tags.map((t) => unifierTagForTag(t, controller.tagIdsToTags));
    var unifierTagIds = tagsToTagIds(unifierTags).toSet();
    if (!unifierTagIds.containsAll(filterTagIdsAll[TagFilterType.include])) return false;
    if (unifierTagIds.intersection(filterTagIdsAll[TagFilterType.exclude]).isNotEmpty) return false;
    if (!unifierTagIds.containsAll(filterTagIdsAll[TagFilterType.lastInboundTurn])) return false;

    if (!conversation.docId.startsWith(conversationIdFilter) && !conversation.shortDeidentifiedPhoneNumber.startsWith(conversationIdFilter)) return false;

    return true;
  }

  bool testMandatoryFilters(model.Conversation conversation) {
    var tags = convertTagIdsToTags(conversation.tagIds, controller.tagIdsToTags);
    var unifierTags = tags.map((t) => unifierTagForTag(t, controller.tagIdsToTags));
    var unifierTagIds = tagsToTagIds(unifierTags).toSet();
    if (!unifierTagIds.containsAll(userConfig.mandatoryIncludeTagIds)) return false;
    if (unifierTagIds.intersection(userConfig.mandatoryExcludeTagIds).isNotEmpty) return false;
    return true;
  }

  // This must be called after every change to the filters
  void _applyMandatoryFilters() {
    if (userConfig.mandatoryExcludeTagIds != null)
      _filterTags[TagFilterType.exclude].addAll(convertTagIdsToTags(userConfig.mandatoryExcludeTagIds, controller.tagIdsToTags));

    if (userConfig.mandatoryIncludeTagIds != null)
      _filterTags[TagFilterType.include].addAll(convertTagIdsToTags(userConfig.mandatoryIncludeTagIds, controller.tagIdsToTags));
  }

  void _removeMandatoryFilters() {
    if (userConfig != null && userConfig.mandatoryExcludeTagIds != null) {
      var urlTags = _getTagsFromUrl(TagFilterType.exclude, controller.tagIdsToTags);
      _filterTags[TagFilterType.exclude].removeWhere((tag) => userConfig.mandatoryExcludeTagIds.contains(tag.tagId) && !urlTags.any((urlTag) => urlTag.tagId == tag.tagId));
    }

    if (userConfig != null && userConfig.mandatoryIncludeTagIds != null) {
      var urlTags = _getTagsFromUrl(TagFilterType.include, controller.tagIdsToTags);
      _filterTags[TagFilterType.include].removeWhere((tag) => userConfig.mandatoryIncludeTagIds.contains(tag.tagId) && !urlTags.any((urlTag) => urlTag.tagId == tag.tagId));
    }
  }

  Set<model.Tag> _getTagsFromUrl(TagFilterType type, Map<String, model.Tag> tags) {
    Set<String> filterTagIds = _view.urlManager.tagsFilter[type];
    var filterTags = convertTagIdsToTags(filterTagIds, tags);
    var unifierFilterTags = filterTags.map((t) => unifierTagForTag(t, tags));
    // Reset the URL to make sure it uses the unifier tags
    // This will be unnecessary after we have moved everyone to using the new unifier tags
    _view.urlManager.tagsFilter[type] = tagsToTagIds(filterTags).toSet();
    return unifierFilterTags.toSet();
  }
}
