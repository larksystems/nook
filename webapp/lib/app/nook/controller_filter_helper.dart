part of controller;

class ConversationFilter {
  Map<TagFilterType, Set<model.Tag>> filterTags;
  String conversationIdFilter;

  ConversationFilter() {
    filterTags = {
      TagFilterType.include: Set(),
      TagFilterType.exclude: Set(),
      TagFilterType.lastInboundTurn: Set()
    };
    conversationIdFilter = "";
  }

  ConversationFilter.fromUrl() {
    filterTags = {
      TagFilterType.include: _getTagsFromUrl(TagFilterType.include, controller.tagIdsToTags),
      TagFilterType.exclude: _getTagsFromUrl(TagFilterType.exclude, controller.tagIdsToTags),
      TagFilterType.lastInboundTurn: _getTagsFromUrl(TagFilterType.lastInboundTurn, controller.tagIdsToTags),
    };

    conversationIdFilter = _view.urlView.getPageUrlFilterConversationId() ?? "";
  }

  bool get isEmpty => filterTags[TagFilterType.include].isEmpty
                   && filterTags[TagFilterType.exclude].isEmpty
                   && filterTags[TagFilterType.lastInboundTurn].isEmpty
                   && conversationIdFilter == "";

  Map<TagFilterType, Set<String>> get filterTagIds => {
    TagFilterType.include: tagsToTagIds(filterTags[TagFilterType.include]).toSet(),
    TagFilterType.exclude: tagsToTagIds(filterTags[TagFilterType.exclude]).toSet(),
    TagFilterType.lastInboundTurn: tagsToTagIds(filterTags[TagFilterType.lastInboundTurn]).toSet()
  };

  bool test(model.Conversation conversation) {
    var tags = convertTagIdsToTags(conversation.tagIds, controller.tagIdsToTags);
    var unifierTags = tags.map((t) => unifierTagForTag(t, controller.tagIdsToTags));
    var unifierTagIds = tagsToTagIds(unifierTags).toSet();
    if (!unifierTagIds.containsAll(filterTagIds[TagFilterType.include])) return false;
    if (unifierTagIds.intersection(filterTagIds[TagFilterType.exclude]).isNotEmpty) return false;
    if (!unifierTagIds.containsAll(filterTagIds[TagFilterType.lastInboundTurn])) return false;

    if (!conversation.docId.startsWith(conversationIdFilter) && !conversation.shortDeidentifiedPhoneNumber.startsWith(conversationIdFilter)) return false;

    return true;
  }

  Set<model.Tag> _getTagsFromUrl(TagFilterType type, Map<String, model.Tag> tags) {
    Set<String> filterTagIds = _view.urlView.getPageUrlFilterTags(type);
    var filterTags = convertTagIdsToTags(filterTagIds, tags);
    var unifierFilterTags = filterTags.map((t) => unifierTagForTag(t, tags));
    // Reset the URL to make sure it uses the unifier tags
    // This will be unnecessary after we have moved everyone to using the new unifier tags
    _view.urlView.setPageUrlFilterTags(type, tagsToTagIds(filterTags).toSet());
    return unifierFilterTags.toSet();
  }
}
