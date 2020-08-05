part of controller;

enum TagFilterType {
  include,
  exclude,
  lastInboundTurn
}

class ConversationFilter {
  Map<TagFilterType, List<model.Tag>> filterTags;
  Map<TagFilterType, DateTime> afterDateFilter;

  ConversationFilter() {
    filterTags = {
      TagFilterType.include: [],
      TagFilterType.exclude: [],
      TagFilterType.lastInboundTurn: []
    };
    afterDateFilter = {
      TagFilterType.include: null,
      TagFilterType.exclude: null,
    };
  }

  ConversationFilter.fromUrl() {
    filterTags = {};
    afterDateFilter = {};

    // include filter
    List<String> filterTagIds = view.urlView.getPageUrlFilterTags(TagFilterType.include);
    print(filterTagIds);
    filterTags[TagFilterType.include] = tagIdsToTags(filterTagIds, conversationTags).toList();

    // exclude filter
    filterTagIds = view.urlView.getPageUrlFilterTags(TagFilterType.exclude);
    print(filterTagIds);
    filterTags[TagFilterType.exclude] = tagIdsToTags(filterTagIds, conversationTags).toList();

    // last inbound tags
    filterTagIds = view.urlView.getPageUrlFilterTags(TagFilterType.lastInboundTurn);
    print(filterTagIds);
    filterTags[TagFilterType.lastInboundTurn] = tagIdsToTags(filterTagIds, messageTags).toList();

    // after date filter
    afterDateFilter[TagFilterType.include] = view.urlView.getPageUrlFilterAfterDate(TagFilterType.include);
    afterDateFilter[TagFilterType.exclude] = view.urlView.getPageUrlFilterAfterDate(TagFilterType.exclude);
  }

  bool get isEmpty => filterTags[TagFilterType.include].isEmpty
                   && filterTags[TagFilterType.exclude].isEmpty
                   && filterTags[TagFilterType.lastInboundTurn].isEmpty
                   && afterDateFilter[TagFilterType.include] == null
                   && afterDateFilter[TagFilterType.exclude] == null;

  Set<String> get includeFilterTagIds => filterTags[TagFilterType.include].map<String>((tag) => tag.tagId).toSet();
  Set<String> get excludeFilterTagIds => filterTags[TagFilterType.exclude].map<String>((tag) => tag.tagId).toSet();
  Set<String> get lastInboundTurnFilterTagIds => filterTags[TagFilterType.lastInboundTurn].map<String>((tag) => tag.tagId).toSet();
  Map<TagFilterType, Set<String>> get filterTagIds => {
    TagFilterType.include: includeFilterTagIds,
    TagFilterType.exclude: excludeFilterTagIds,
    TagFilterType.lastInboundTurn: lastInboundTurnFilterTagIds
  };

  bool test(model.Conversation conversation) {
    // Filter by the last (most recent) message
    // TODO consider an option to filter by the first message
    if (afterDateFilter[TagFilterType.include] != null && conversation.messages.last.datetime.isBefore(afterDateFilter[TagFilterType.include])) return false;
    if (afterDateFilter[TagFilterType.exclude] != null && conversation.messages.last.datetime.isAfter(afterDateFilter[TagFilterType.exclude])) return false;

    if (!conversation.tagIds.containsAll(includeFilterTagIds)) return false;
    if (conversation.tagIds.intersection(excludeFilterTagIds).isNotEmpty) return false;
    if (!conversation.lastInboundTurnTagIds.containsAll(lastInboundTurnFilterTagIds)) return false;

    return true;
  }
}
