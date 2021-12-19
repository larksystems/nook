library controller;

import 'dart:html';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/snackbar/snackbar.dart';
import 'package:nook/app/configurator/controller.dart';
export 'package:nook/app/configurator/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:katikati_ui_lib/components/tag/tag.dart';
import 'package:katikati_ui_lib/components/menu/menu.dart';
import 'package:nook/platform/platform.dart';
import 'view.dart';

part 'controller_view_helper.dart';
part 'controller_tag_helper.dart';


Logger log = new Logger('controller.dart');

enum TagsConfigAction {
  addTag,
  addTagGroup,
  requestRenameTag,
  renameTag,
  moveTag,
  updateTagGroup,
  removeTag,
  removeTagGroup,
  updateTagType
}

class TagData extends Data {
  String id;

  /// Used when renaming a tag
  String text;

  /// Used when removing or moving a tag
  String groupId;

  /// Used when moving a tag
  String newGroupId;

  model.TagType newType;

  TagData(this.id, {this.text, this.groupId, this.newGroupId, this.newType});

  @override
  String toString() {
    return 'TagData($id, {$text, $groupId, $newGroupId})';
  }
}

class TagGroupData extends Data {
  // Used when renaming or removing a tag group
  String groupName;

  // Used when renaming a tag group
  String newGroupName;

  TagGroupData(this.groupName, {this.newGroupName});

  @override
  String toString() {
    return 'TagData($groupName, {$newGroupName})';
  }
}

TagsConfiguratorController _controller;
TagsConfigurationPageView get _view => _controller.view;

class TagsConfiguratorController extends ConfiguratorController {
  TagManager tagManager = new TagManager();
  Set<String> unsavedTagIds = {};
  Set<String> unsavedGroupIds = {};

  TagsConfiguratorController() : super() {
    _controller = this;
  }

  @override
  void init() {
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
        var tag = tagManager.createTag(tagData.groupId);
        _addTagsToView({
          tagData.groupId: [tag]
        }, startEditing: true);
        break;
      
      case TagsConfigAction.requestRenameTag:
        TagData requestRenameTagData = data;
        var tagText = requestRenameTagData.text.toLowerCase().trim();
        var presentTagTexts = tagManager._tags.map((tag) => tag.text.toLowerCase().trim()).toList();
        
        if (presentTagTexts.contains(tagText)) {
          _showDuplicateTagWarningModal(requestRenameTagData.groupId, requestRenameTagData.id, requestRenameTagData.text);
        } else {
          unsavedTagIds.add(requestRenameTagData.id);
          unsavedGroupIds.add(requestRenameTagData.groupId);
          command(TagsConfigAction.renameTag, TagData(requestRenameTagData.id, text: requestRenameTagData.text));
        }
        break;

      case TagsConfigAction.renameTag:
        TagData tagData = data;
        var tag = tagManager.modifyTag(tagData.id, text: tagData.text);
        unsavedTagIds.add(tagData.id);
        unsavedGroupIds.add(tagData.groupId);
        _modifyTagsInView(Map.fromEntries(tag.groups.map((g) => new MapEntry(g, [tag]))), unsavedTagIds, unsavedGroupIds);
        break;

      case TagsConfigAction.moveTag:
        TagData tagData = data;
        model.Tag tag = tagManager.modifyTag(tagData.id, group: tagData.newGroupId);
        unsavedTagIds.add(tagData.id);
        unsavedGroupIds.add(tagData.groupId);
        // update the view by removing the tag and then adding it
        _removeTagsFromView({ tagData.groupId: [tag] }, unsavedTagIds, unsavedGroupIds);
        _addTagsToView({
          tagData.newGroupId: [tag]
        });
        break;

      case TagsConfigAction.removeTag:
        TagData tagData = data;
        unsavedGroupIds.add(tagData.groupId);
        model.Tag tag = tagManager.deleteTag(tagData.id);
        _removeTagsFromView({ tagData.groupId: [tag] }, unsavedTagIds, unsavedGroupIds);
        break;

      case TagsConfigAction.addTagGroup:
        var newGroupName = tagManager.createTagGroup();
        _addTagsToView({newGroupName: []}, startEditingName: true);
        break;

      case TagsConfigAction.updateTagGroup:
        TagGroupData groupData = data;
        tagManager.renameTagGroup(groupData.groupName, groupData.newGroupName);
        var groupView = _view.groups.queryItem(groupData.groupName);
        groupView.id = groupData.newGroupName;
        unsavedGroupIds.add(groupView.id);
        _view.groups.updateItem(groupData.newGroupName, groupView);
        _view.groups.items.forEach((element) {
          if (element.id == groupView.id) {
            (element as TagGroupView).markAsUnsaved(true);
          }
        });
        break;

      case TagsConfigAction.removeTagGroup:
        TagGroupData groupData = data;
        unsavedGroupIds.add(groupData.groupName);
        tagManager.deleteTagGroup(groupData.groupName);
        _view.removeTagGroup(groupData.groupName);
        break;

      case TagsConfigAction.updateTagType:
        TagData tagData = data;
        var tag = tagManager.modifyTag(tagData.id, type: tagData.newType);
        unsavedTagIds.add(tagData.id);
        unsavedGroupIds.add(tagData.groupId);
        _modifyTagsInView(Map.fromEntries(tag.groups.map((g) => new MapEntry(g, [tag]))), unsavedTagIds, unsavedGroupIds);
        break;

      default:
    }

    _view.unsavedChanges = tagManager.hasUnsavedTags;
  }

  @override
  void setUpOnLogin() {
    platform.listenForTags((added, modified, removed) {
      var tagsAdded = tagManager.addTags(added);
      var tagsModified = tagManager.updateTags(modified);
      var tagsRemoved = tagManager.removeTags(removed);

      _addTagsToView(_groupTagsIntoCategories(tagsAdded));
      _modifyTagsInView(_groupTagsIntoCategories(tagsModified), unsavedTagIds, unsavedGroupIds);
      _removeTagsFromView(_groupTagsIntoCategories(tagsRemoved), unsavedTagIds, unsavedGroupIds);
    });
  }

  @override
  void saveConfiguration() {
    _view.showSaveStatus('Saving...');
    bool otherPartSaved = false;

    platform.updateTags(tagManager.editedTags.values.toList()).then((value) {
      tagManager.editedTags.clear();
      if (otherPartSaved) {
        _view.showSaveStatus('Saved!');
        _view.unsavedChanges = false;
        unsavedTagIds = {};
        unsavedGroupIds = {};
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });

    platform.deleteTags(tagManager.deletedTags.values.toList()).then((value) {
      tagManager.deletedTags.clear();
      if (otherPartSaved) {
        _view.showSaveStatus('Saved!');
        _view.unsavedChanges = false;
        unsavedTagIds = {};
        unsavedGroupIds = {};
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });
  }
}
