library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/configurator/controller.dart';
export 'package:nook/app/configurator/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:nook/platform/platform.dart';
import 'view.dart';

part 'controller_view_helper.dart';
part 'controller_tag_helper.dart';


Logger log = new Logger('controller.dart');

enum TagsConfigAction {
  // Handling tags
  addTag,
  addTagGroup,
  renameTag,
  moveTag,
  updateTagGroup,
  removeTag,
  removeTagGroup
}

class TagData extends Data {
  String id;

  /// Used when renaming a tag
  String text;

  /// Used when removing, or moving a tag
  String groupId;

  /// Used when moving a tag
  String newGroupId;
  TagData(this.id, {this.text, this.groupId, this.newGroupId});
}

class TagGroupData extends Data {
  String groupName;
  String newGroupName;
  TagGroupData(this.groupName, {this.newGroupName});
}

TagsConfiguratorController _controller;
TagsConfigurationPageView get _view => _controller.view;

class TagsConfiguratorController extends ConfiguratorController {
  TagManager tagManager = new TagManager();
  Map<String, model.Tag> editedTags = {};
  Map<String, model.Tag> removedTags = {};

  TagsConfiguratorController() : super() {
    _controller = this;
    view = new TagsConfigurationPageView(this);
    platform = new Platform(this);
  }

  void command(action, [Data data]) {
    if (action is! TagsConfigAction) {
      super.command(action, data);
      return;
    }
    log.verbose('command => $action : $data');
    switch (action) {
      case TagsConfigAction.addTag:
        TagData tagData = data;
        var newTag = new model.Tag()
          ..docId = model.generateTagId()
          ..filterable = true
          ..groups = [tagData.groupId]
          ..isUnifier = false
          ..text = ''
          ..shortcut = ''
          ..visible = true
          ..type = model.TagType.Normal;

        tagManager.addTag(newTag);

        _addTagsToView({
          tagData.groupId: [newTag]
        });
        editedTags[newTag.tagId] = newTag;
        break;

      case TagsConfigAction.renameTag:
        TagData tagData = data;
        model.Tag tag = tagManager.getTagById(tagData.id);
        tag.text = tagData.text;
        editedTags[tag.tagId] = tag;
        _modifyTagsInView(Map.fromEntries(tag.groups.map((g) => new MapEntry(g, [tag]))));
        break;

      case TagsConfigAction.moveTag:
        TagData tagData = data;
        model.Tag tag = tagManager.getTagById(tagData.id);
        tag.groups.remove(tagData.groupId);
        tag.groups.add(tagData.newGroupId);
        editedTags[tag.tagId] = tag;
        _removeTagsFromView({
          tagData.groupId: [tag]
        });
        _addTagsToView({
          tagData.newGroupId: [tag]
        });
        break;

      case TagsConfigAction.removeTag:
        TagData tagData = data;
        model.Tag tag = tagManager.getTagById(tagData.id);
        tag.groups.remove(tagData.groupId);
        _removeTagsFromView({
          tagData.groupId: [tag]
        });
        if (tag.groups.isEmpty) {
          editedTags.remove(tag.tagId);
          removedTags[tag.tagId] = tag;
        } else {
          editedTags[tag.tagId] = tag;
        }
        break;

      case TagsConfigAction.addTagGroup:
        var newGroupName = tagManager.nextTagGroupName;
        tagManager.namesOfEmptyGroups.add(newGroupName);
        _addTagsToView({newGroupName: []});
        break;
      case TagsConfigAction.updateTagGroup:
        TagGroupData groupData = data;
        List<model.Tag> tagsToEdit = tagManager.tags.where((r) => r.groups.contains(groupData.groupName)).toList();
        for (var tag in tagsToEdit) {
          tag.groups.remove(groupData.groupName);
          tag.groups.add(groupData.newGroupName);
          editedTags[tag.tagId] = tag;
        }
        var groupView = _view.groups[groupData.groupName];
        groupView.name = groupData.newGroupName;
        _view.groups.remove(groupData.groupName);
        _view.groups[groupData.newGroupName] = groupView;
        break;
      case TagsConfigAction.removeTagGroup:
        TagGroupData groupData = data;

        List<model.Tag> tagsToRemove = tagManager.tags.where((r) => r.groups.contains(groupData.groupName) && r.groups.length == 1).toList();
        removedTags.addEntries(tagsToRemove.map((e) => MapEntry(e.tagId, e)));

        List<model.Tag> tagsToEdit = tagManager.tags.where((r) => r.groups.contains(groupData.groupName) && r.groups.length > 1).toList();
        for (var tag in tagsToEdit) {
          tag.groups.remove(groupData.groupName);
          tag.groups.add(groupData.newGroupName);
          editedTags[tag.tagId] = tag;
        }
        _view.removeTagGroup(groupData.groupName);
        break;
      default:
    }
  }

  @override
  void setUpOnLogin() {
    platform.listenForTags((added, modified, removed) {
      tagManager.addTags(added);
      tagManager.updateTags(modified);
      tagManager.removeTags(removed);

      _addTagsToView(_groupTagsIntoCategories(added));
      _modifyTagsInView(_groupTagsIntoCategories(modified));
      _removeTagsFromView(_groupTagsIntoCategories(removed));
    });
  }

  @override
  void saveConfiguration() {
    _view.showSaveStatus('Saving...');
    bool otherPartSaved = false;

    platform.updateTags(editedTags.values.toList()).then((value) {
      editedTags.clear();
      if (otherPartSaved) {
        _view.showSaveStatus('Saved!');
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });

    platform.deleteTags(removedTags.values.toList()).then((value) {
      removedTags.clear();
      if (otherPartSaved) {
        _view.showSaveStatus('Saved!');
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });
  }
}
