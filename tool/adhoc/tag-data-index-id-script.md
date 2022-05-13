# INSTRUCTIONS
Paste the following code in `webapp/lib/app/configurator/tags/controller.dart` > `saveConfiguration` function right below the `ignore: placeholder ...` comment.

```
Map<String, int> groupIndexMap = {};
Map<String, String> groupIdMap = {};

Set<String> groupNameSet = {};
tagManager.tags.forEach((tag) {
  tag.groups.forEach((groupName) {
    groupNameSet.add(groupName);
  });
});

List<String> groupNames = groupNameSet.toList();
groupNames.sort();

// known: groupIndices, groupIds are reset everytime
tagManager.tags.forEach((tag) {
  tag.groups.forEach((groupName) {
    groupIndexMap[groupName] = groupNames.indexOf(groupName);
    groupIdMap[groupName] = groupIdMap[groupName] ?? model.generateTagGroupId();
  });
  tag.groupIds = tag.groups.map((groupName) => groupIdMap[groupName]).toList();
  tag.groupNames = tag.groups;
  tag.groupIndices = tag.groups.map((groupName) => groupIndexMap[groupName]).toList();
});

platform.updateTags(tagManager.tags.toList()).then((value) {
  window.alert("Tags updated!");
});

return;
```