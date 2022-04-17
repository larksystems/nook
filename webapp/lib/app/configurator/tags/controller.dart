library controller;

import 'dart:html';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/snackbar/snackbar.dart';
import 'package:nook/app/configurator/controller.dart';
export 'package:nook/app/configurator/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:katikati_ui_lib/components/tag/tag.dart';
import 'package:katikati_ui_lib/components/menu/menu.dart';
import 'package:nook/app/nook/controller.dart';
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

  TagsConfiguratorController() : super() {
    _controller = this;
  }

  @override
  void init() {
    defaultUserConfig = model.UserConfigurationUtil.baseUserConfiguration;
    currentUserConfig = currentConfig = model.UserConfigurationUtil.emptyUserConfiguration;

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
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Adding a new tag is disabled', SnackbarNotificationType.warning));
          return;
        }

        var tag = tagManager.createTag(tagData.groupId);
        _addTagsToView({
          tagData.groupId: [tag]
        }, startEditing: true);
        break;

      case TagsConfigAction.requestRenameTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Renaming a tag is disabled', SnackbarNotificationType.warning));
          // Reshow the tag as the view edits it anyway
          _modifyTagsInView(Map.fromEntries(tagManager.getTagById(tagData.id).groups.map((g) => new MapEntry(g, [tagManager.getTagById(tagData.id)]))));
          return;
        }

        var tagText = tagData.text.toLowerCase().trim();
        var presentTagTexts = tagManager._tags.map((tag) => tag.text.toLowerCase().trim()).toList();

        if (presentTagTexts.contains(tagText)) {
          _showDuplicateTagWarningModal(tagData.groupId, tagData.id, tagData.text);
        } else {
          command(TagsConfigAction.renameTag, TagData(tagData.id, text: tagData.text));
        }
        break;

      case TagsConfigAction.renameTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Renaming a tag is disabled', SnackbarNotificationType.warning));
          // Reshow the tag as the view edits it anyway
          _modifyTagsInView(Map.fromEntries(tagManager.getTagById(tagData.id).groups.map((g) => new MapEntry(g, [tagManager.getTagById(tagData.id)]))));
          return;
        }

        var tag = tagManager.modifyTag(tagData.id, text: tagData.text);
        _modifyTagsInView(Map.fromEntries(tag.groups.map((g) => new MapEntry(g, [tag]))));
        _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
        break;

      case TagsConfigAction.moveTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Moving a tag is disabled', SnackbarNotificationType.warning));
          // Reshow the tag as the view edits it anyway
          _modifyTagsInView(Map.fromEntries(tagManager.getTagById(tagData.id).groups.map((g) => new MapEntry(g, [tagManager.getTagById(tagData.id)]))));
          return;
        }

        model.Tag tag = tagManager.modifyTag(tagData.id, group: tagData.newGroupId);
        // update the view by removing the tag and then adding it
        _removeTagsFromView({
          tagData.groupId: [tag]
        });
        _addTagsToView({
          tagData.newGroupId: [tag]
        });
        tagManager.movedFromGroupIds.add(tagData.groupId);
        _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
        break;

      case TagsConfigAction.removeTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Deleting a tag is disabled', SnackbarNotificationType.warning));
          return;
        }

        model.Tag tag = tagManager.deleteTag(tagData.id);
        _removeTagsFromView({
          tagData.groupId: [tag]
        });
        _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
        break;

      case TagsConfigAction.addTagGroup:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Adding a new tag group is disabled', SnackbarNotificationType.warning));
          return;
        }

        var newGroupName = tagManager.createTagGroup();
        _addTagsToView({newGroupName: []}, startEditingName: true);
        _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
        break;

      case TagsConfigAction.updateTagGroup:
        TagGroupData groupData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Renaming a tag group is disabled', SnackbarNotificationType.warning));
          // TODO: the tag group name still remains edited in the UI, work out how to change it
          return;
        }

        tagManager.renameTagGroup(groupData.groupName, groupData.newGroupName);
        var groupView = _view.groups.queryItem(groupData.groupName);
        groupView.id = groupData.newGroupName;
        _view.groups.updateItem(groupData.newGroupName, groupView);
        _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
        break;

      case TagsConfigAction.removeTagGroup:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Deleting a tag group is disabled', SnackbarNotificationType.warning));
          return;
        }

        TagGroupData groupData = data;
        tagManager.deleteTagGroup(groupData.groupName);
        _view.removeTagGroup(groupData.groupName);
        break;

      case TagsConfigAction.updateTagType:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Changing the tag type is disabled', SnackbarNotificationType.warning));
          return;
        }

        TagData tagData = data;
        var tag = tagManager.modifyTag(tagData.id, type: tagData.newType);
        _modifyTagsInView(Map.fromEntries(tag.groups.map((g) => new MapEntry(g, [tag]))));
        _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
        break;

      default:
    }

    _view.unsavedChanges = tagManager.hasUnsavedTags;
  }

  @override
  void setUpOnLogin() {
    super.setUpOnLogin();
    platform.listenForTags((added, modified, removed) {
      var tagsAdded = tagManager.addTags(added);
      var tagsModified = tagManager.updateTags(modified);
      var tagsRemoved = tagManager.removeTags(removed);

      _addTagsToView(_groupTagsIntoCategories(tagsAdded));
      _modifyTagsInView(_groupTagsIntoCategories(tagsModified));
      _removeTagsFromView(_groupTagsIntoCategories(tagsRemoved));
    });
  }

  @override
  void applyConfiguration(model.UserConfiguration newConfig) {
    super.applyConfiguration(newConfig);

    if (!currentConfig.editTagsEnabled) {
      tagManager.editedTags.clear();
      tagManager.movedFromGroupIds.clear();
      tagManager.deletedTags.clear();
      _view.showSaveStatus('Modifying tags has been disabled, dropping all changes');
      _view.unsavedChanges = false;
      _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
    }
  }

  @override
  void saveConfiguration() {
    _view.showSaveStatus('Saving...');
    bool otherPartSaved = false;

    platform.updateTags(tagManager.editedTags.values.toList()).then((value) {
      tagManager.editedTags.clear();
      tagManager.movedFromGroupIds.clear();
      if (otherPartSaved) {
        _view.showSaveStatus('Saved!');
        _view.unsavedChanges = false;
        _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
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
        _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });
  }
}
