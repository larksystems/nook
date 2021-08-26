part of controller;

class ConversationFilter {
  Map<TagFilterType, Set<model.Tag>> _filterTags;
  model.UserConfiguration userConfig;
  String conversationIdFilter;

  Set<model.Tag> getFilters(TagFilterType typ) {
    return _filterTags[typ].toSet();
  }

  bool addFilter(TagFilterType typ, model.Tag tag) {
    var previous = _filterTags[typ].toSet();
    _filterTags[typ].add(tag);
    _applyMandatoryFilters();
    var updated = _filterTags[typ];
    // Dart doesn't seem to have a set equality test, test for same lengths and same elements
    bool isChanged = !(updated.length == previous.length &&
        updated.every((e) => previous.contains(e)));
    return isChanged;
  }

  bool removeFilter(TagFilterType typ, model.Tag tag) {
    var previous = _filterTags[typ].toSet();
    _filterTags[typ].remove(tag);
    _applyMandatoryFilters();
    var updated = _filterTags[typ];
    // Dart doesn't seem to have a set equality test, test for same lengths and same elements
    bool isChanged = !(updated.length == previous.length &&
        updated.every((e) => previous.contains(e)));
    return isChanged;
  }

  void clearFilters(TagFilterType typ) {
    _filterTags[typ].clear();
    _applyMandatoryFilters();
  }

  void updateUserConfig(model.UserConfiguration userConfig) {
    this.userConfig = userConfig;
    _applyMandatoryFilters();
  }

  ConversationFilter(model.UserConfiguration userConfig) {
    _filterTags = {
      TagFilterType.include: Set(),
      TagFilterType.exclude: Set(),
      TagFilterType.lastInboundTurn: Set()
    };

    updateUserConfig(userConfig);
    _applyMandatoryFilters();
    conversationIdFilter = "";
  }

  ConversationFilter.fromUrl(model.UserConfiguration userConfig) {
    _filterTags = {
      TagFilterType.include:
          _getTagsFromUrl(TagFilterType.include, controller.tagIdsToTags),
      TagFilterType.exclude:
          _getTagsFromUrl(TagFilterType.exclude, controller.tagIdsToTags),
      TagFilterType.lastInboundTurn: _getTagsFromUrl(
          TagFilterType.lastInboundTurn, controller.tagIdsToTags),
    };
    updateUserConfig(userConfig);
    _applyMandatoryFilters();

    conversationIdFilter = _view.urlView.getPageUrlFilterConversationId() ?? "";
  }

  bool get isEmpty =>
      _filterTags[TagFilterType.include].isEmpty &&
      _filterTags[TagFilterType.exclude].isEmpty &&
      _filterTags[TagFilterType.lastInboundTurn].isEmpty &&
      conversationIdFilter == "";

  Map<TagFilterType, Set<String>> get filterTagIds => {
        TagFilterType.include:
            tagsToTagIds(_filterTags[TagFilterType.include]).toSet(),
        TagFilterType.exclude:
            tagsToTagIds(_filterTags[TagFilterType.exclude]).toSet(),
        TagFilterType.lastInboundTurn:
            tagsToTagIds(_filterTags[TagFilterType.lastInboundTurn]).toSet()
      };

  bool test(model.Conversation conversation) {
    var tags =
        convertTagIdsToTags(conversation.tagIds, controller.tagIdsToTags);
    var unifierTags =
        tags.map((t) => unifierTagForTag(t, controller.tagIdsToTags));
    var unifierTagIds = tagsToTagIds(unifierTags).toSet();
    if (!unifierTagIds.containsAll(filterTagIds[TagFilterType.include]))
      return false;
    if (unifierTagIds
        .intersection(filterTagIds[TagFilterType.exclude])
        .isNotEmpty) return false;
    if (!unifierTagIds.containsAll(filterTagIds[TagFilterType.lastInboundTurn]))
      return false;

    if (!conversation.docId.startsWith(conversationIdFilter) &&
        !conversation.shortDeidentifiedPhoneNumber
            .startsWith(conversationIdFilter)) return false;

    return true;
  }

  // This must be called after every change to the filters
  void _applyMandatoryFilters() {
    if (userConfig != null)
      _filterTags[TagFilterType.exclude].addAll(convertTagIdsToTags(
          userConfig.mandatoryExcludeTagIds, controller.tagIdsToTags));

    if (userConfig.mandatoryIncludeTagIds != null)
      _filterTags[TagFilterType.include].addAll(convertTagIdsToTags(
          userConfig.mandatoryIncludeTagIds, controller.tagIdsToTags));
  }

  Set<model.Tag> _getTagsFromUrl(
      TagFilterType type, Map<String, model.Tag> tags) {
    Set<String> filterTagIds = _view.urlView.getPageUrlFilterTags(type);
    var filterTags = convertTagIdsToTags(filterTagIds, tags);
    var unifierFilterTags = filterTags.map((t) => unifierTagForTag(t, tags));
    // Reset the URL to make sure it uses the unifier tags
    // This will be unnecessary after we have moved everyone to using the new unifier tags
    _view.urlView.setPageUrlFilterTags(type, tagsToTagIds(filterTags).toSet());
    return unifierFilterTags.toSet();
  }
}
