part of controller;

class ConversationFilter {
  Map<TagFilterType, Set<model.Tag>> filterTags;
  Map<TagFilterType, DateTime> afterDateFilter;
  String conversationIdFilter;

  ConversationFilter() {
    filterTags = {
      TagFilterType.include: Set(),
      TagFilterType.exclude: Set(),
      TagFilterType.lastInboundTurn: Set()
    };
    afterDateFilter = {
      TagFilterType.include: null,
      TagFilterType.exclude: null,
    };
    conversationIdFilter = "";
  }

  ConversationFilter.fromUrl() {
    filterTags = {
      TagFilterType.include: _getTagsFromUrl(TagFilterType.include, controller.conversationTagIdsToTags),
      TagFilterType.exclude: _getTagsFromUrl(TagFilterType.exclude, controller.conversationTagIdsToTags),
      TagFilterType.lastInboundTurn: _getTagsFromUrl(TagFilterType.lastInboundTurn, controller.messageTagIdsToTags),
    };

    afterDateFilter = {
      TagFilterType.include: _view.urlView.getPageUrlFilterAfterDate(TagFilterType.include, onError: (Exception e){
        var message = e is FormatException ? e.message : "Unknown format";
        _view.appController
            .command(UIAction.showSnackbar, new SnackbarData("Invalid date/time format for filter in URL: ${message}", SnackbarNotificationType.error));
      }),
      TagFilterType.exclude: _view.urlView.getPageUrlFilterAfterDate(TagFilterType.exclude),
    };

    conversationIdFilter = _view.urlView.getPageUrlFilterConversationId() ?? "";
  }

  bool get isEmpty => filterTags[TagFilterType.include].isEmpty
                   && filterTags[TagFilterType.exclude].isEmpty
                   && filterTags[TagFilterType.lastInboundTurn].isEmpty
                   && afterDateFilter[TagFilterType.include] == null
                   && afterDateFilter[TagFilterType.exclude] == null
                   && conversationIdFilter == "";

  Map<TagFilterType, Set<String>> get filterTagIds => {
    TagFilterType.include: tagsToTagIds(filterTags[TagFilterType.include]).toSet(),
    TagFilterType.exclude: tagsToTagIds(filterTags[TagFilterType.exclude]).toSet(),
    TagFilterType.lastInboundTurn: tagsToTagIds(filterTags[TagFilterType.lastInboundTurn]).toSet()
  };

  bool test(model.Conversation conversation) {
    // Filter by the last (most recent) message
    // TODO consider an option to filter by the first message
    if (afterDateFilter[TagFilterType.include] != null && conversation.messages.last.datetime.isBefore(afterDateFilter[TagFilterType.include])) return false;
    if (afterDateFilter[TagFilterType.exclude] != null && conversation.messages.last.datetime.isAfter(afterDateFilter[TagFilterType.exclude])) return false;

    var tags = tagIdsToTags(conversation.tagIds, controller.conversationTagIdsToTags);
    var unifierTags = tags.map((t) => unifierTagForTag(t, controller.conversationTagIdsToTags));
    var unifierTagIds = tagsToTagIds(unifierTags).toSet();
    if (!unifierTagIds.containsAll(filterTagIds[TagFilterType.include])) return false;
    if (unifierTagIds.intersection(filterTagIds[TagFilterType.exclude]).isNotEmpty) return false;

    tags = tagIdsToTags(conversation.lastInboundTurnTagIds, controller.messageTagIdsToTags);
    unifierTags = tags.map((t) => unifierTagForTag(t, controller.messageTagIdsToTags));
    unifierTagIds = tagsToTagIds(unifierTags).toSet();
    if (!unifierTagIds.containsAll(filterTagIds[TagFilterType.lastInboundTurn])) return false;

    if (!conversation.docId.startsWith(conversationIdFilter) && !conversation.shortDeidentifiedPhoneNumber.startsWith(conversationIdFilter)) return false;

    return true;
  }

  Set<model.Tag> _getTagsFromUrl(TagFilterType type, Map<String, model.Tag> tags) {
    Set<String> filterTagIds = _view.urlView.getPageUrlFilterTags(type);
    var filterTags = tagIdsToTags(filterTagIds, tags);
    var unifierFilterTags = filterTags.map((t) => unifierTagForTag(t, tags));
    // Reset the URL to make sure it uses the unifier tags
    // This will be unnecessary after we have moved everyone to using the new unifier tags
    _view.urlView.setPageUrlFilterTags(type, tagsToTagIds(filterTags).toSet());
    return unifierFilterTags.toSet();
  }
}
