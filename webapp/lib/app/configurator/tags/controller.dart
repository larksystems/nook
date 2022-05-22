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
import 'dart:math';

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
  String id;

  // Used when renaming a tag group
  String newGroupName;

  TagGroupData(this.id, {this.newGroupName});

  @override
  String toString() {
    return 'TagData($id, {$newGroupName})';
  }
}

TagsConfiguratorController _controller;
TagsConfigurationPageView get _view => _controller.view;

class TagsConfiguratorController extends ConfiguratorController {
  TagManager tagManager = new TagManager();

  model.UserConfiguration defaultUserConfig;
  model.UserConfiguration currentUserConfig;
  /// This represents the current configuration of the UI.
  /// It's computed by merging the [defaultUserConfig] and [currentUserConfig] (if set).
  model.UserConfiguration currentConfig;

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

        var tag = tagManager.createTagInLocal(tagData.groupId);
        _addTagsToView({tagData.groupId: [tag]}, tagManager.localTagGroupsById, startEditing: true);
        break;

      case TagsConfigAction.requestRenameTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Renaming a tag is disabled', SnackbarNotificationType.warning));
          // Reshow the tag as the view edits it anyway
          var renamedTag = tagManager.localTagsById[tagData.id];
          _modifyTagsInView(Map.fromEntries(renamedTag.groupIds.map((g) => new MapEntry(g, [renamedTag]))), tagManager.localTagGroupsById); // todo: eb: confirm this works!
          return;
        }

        var tagText = tagData.text.toLowerCase().trim();
        var presentTagTexts = tagManager.tagsInLocal.map((tag) => tag.text.toLowerCase().trim()).toList();

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
          var renamedTag = tagManager.localTagsById[tagData.id];
          _modifyTagsInView(Map.fromEntries(renamedTag.groupIds.map((g) => new MapEntry(g, [renamedTag]))), tagManager.localTagGroupsById); // todo: eb: confirm this works!
          return;
        }

        var tag = tagManager.updateTextInLocal(tagData.id, tagData.text);
        _modifyTagsInView(Map.fromEntries(tag.groupIds.map((g) => new MapEntry(g, [tag]))), tagManager.localTagGroupsById);
        _updateUnsavedIndicators(tagManager.localTagsByCategoryId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.moveTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Moving a tag is disabled', SnackbarNotificationType.warning));
          // Reshow the tag as the view edits it anyway
          var movedTag = tagManager.localTagsById[tagData.id];
          _modifyTagsInView(Map.fromEntries(movedTag.groupIds.map((g) => new MapEntry(g, [movedTag]))), tagManager.localTagGroupsById); // todo: eb: confirm this works!
          return;
        }

        var tag = tagManager.removeTagFromLocalGroup(tagData.id, tagData.groupId, skipUpdate: true);
        tagManager.addTagToLocalGroup(tag, tagData.newGroupId);
        _removeTagsFromView({ tagData.groupId: [tag] });
        _addTagsToView({ tagData.newGroupId: [tag] }, tagManager.localTagGroupsById);
        
        tagManager.editedTagIds.add(tagData.id);
        _updateUnsavedIndicators(tagManager.localTagsByCategoryId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.removeTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Deleting a tag is disabled', SnackbarNotificationType.warning));
          return;
        }

        var tag = tagManager.removeTagInLocal(tagData.id);
        _removeTagsFromView({tagData.groupId: [tag]});
        _updateUnsavedIndicators(tagManager.localTagsByCategoryId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.addTagGroup:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Adding a new tag group is disabled', SnackbarNotificationType.warning));
          return;
        }

        var groupName = "new group";
        var group = tagManager.createGroupInLocal(groupName);
        _addTagsToView({group.groupId: []}, tagManager.localTagGroupsById, startEditingName: true);
        _updateUnsavedIndicators(tagManager.localTagsByCategoryId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.updateTagGroup:
        TagGroupData groupData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Renaming a tag group is disabled', SnackbarNotificationType.warning));
          // TODO: the tag group name still remains edited in the UI, work out how to change it
          return;
        }

        tagManager.renameGroupInLocal(groupData.id, groupData.newGroupName);
        _updateUnsavedIndicators(tagManager.localTagsByCategoryId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.removeTagGroup:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Deleting a tag group is disabled', SnackbarNotificationType.warning));
          return;
        }

        TagGroupData groupData = data;
        tagManager.removeAllTagsFromGroupInLocal(groupData.id);
        _view.removeTagGroup(groupData.id);
        break;

      case TagsConfigAction.updateTagType:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Changing the tag type is disabled', SnackbarNotificationType.warning));
          return;
        }

        TagData tagData = data;
        var tag = tagManager.updateTypeInLocal(tagData.id, tagData.newType);
        _modifyTagsInView(Map.fromEntries(tag.groupIds.map((g) => new MapEntry(g, [tag]))), tagManager.localTagGroupsById);
        _updateUnsavedIndicators(tagManager.localTagsByCategoryId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      default:
    }

    _view.unsavedChanges = tagManager.hasUnsavedTags;
  }

  @override
  void setUpOnLogin() {
    platform.listenForTags((added, modified, removed) {
      var tagsAdded = tagManager.populateTagsInStorage(added);
      var tagsModified = tagManager.populateTagsInStorage(modified);
      var tagsRemoved = tagManager.removeTagsFromStorage(removed.map((tag) => tag.tagId).toList());

      _addTagsToView(_groupTagsIntoCategories(tagsAdded), tagManager.storageTagGroupsById);
      _modifyTagsInView(_groupTagsIntoCategories(tagsModified), tagManager.storageTagGroupsById);
      _removeTagsFromView(_groupTagsIntoCategories(tagsRemoved));
    });

    platform.listenForUserConfigurations((added, modified, removed) {
      List<model.UserConfiguration> changedUserConfigurations = new List()
        ..addAll(added)
        ..addAll(modified);

      var defaultConfig = changedUserConfigurations.singleWhere((c) => c.docId == 'default', orElse: () => null);
      defaultConfig = removed.where((c) => c.docId == 'default').length > 0 ? model.UserConfigurationUtil.baseUserConfiguration : defaultConfig;
      var userConfig = changedUserConfigurations.singleWhere((c) => c.docId == signedInUser.userEmail, orElse: () => null);
      userConfig = removed.where((c) => c.docId == signedInUser.userEmail).length > 0 ? model.UserConfigurationUtil.emptyUserConfiguration : userConfig;
      if (defaultConfig == null && userConfig == null) {
        // Neither of the relevant configurations has been changed, nothing to do here
        return;
      }
      defaultUserConfig = defaultConfig ?? defaultUserConfig;
      currentUserConfig = userConfig ?? currentUserConfig;
      currentConfig = currentUserConfig.applyDefaults(defaultUserConfig);

      // Apply new config
      if (!currentConfig.editTagsEnabled) {
        tagManager.editedTagIds.clear();
        tagManager.deletedTagIds.clear();
        tagManager.editedGroupIds.clear();
        tagManager.localTagsById = {};
        tagManager.storageTagsById.keys.forEach((tagId) {
          tagManager.localTagsById[tagId] = tagManager.storageTagsById[tagId]; // todo: eb: clone!
        });
        _view.showSaveStatus('Modifying tags has been disabled, dropping all changes');
        _view.unsavedChanges = false;
        // todo: eb: fix existing bug / reset view!
        _updateUnsavedIndicators(tagManager.localTagsByCategoryId, tagManager.editedTagIds, tagManager.editedGroupIds);
      }

      if (currentConfig.consoleLoggingLevel.toLowerCase().contains('verbose')) {
          logLevel = LogLevel.VERBOSE;
      }
      if (currentConfig.consoleLoggingLevel.toLowerCase().contains('debug')) {
          logLevel = LogLevel.DEBUG;
      }
      if (currentConfig.consoleLoggingLevel.toLowerCase().contains('warning')) {
          logLevel = LogLevel.WARNING;
      }
      if (currentConfig.consoleLoggingLevel.toLowerCase().contains('error')) {
          logLevel = LogLevel.ERROR;
      }
    });

  }

  @override
  void saveConfiguration() {
    _view.showSaveStatus('Saving...');
    bool otherPartSaved = false;

    // ignore: placeholder for tool/adhoc/tag-data-index-id-script.txt

    // platform.updateTags(tagManager.editedTags.values.toList()).then((value) {
    //   tagManager.editedTags.clear();
    //   tagManager.movedFromGroupIds.clear();
    //   if (otherPartSaved) {
    //     _view.showSaveStatus('Saved!');
    //     _view.unsavedChanges = false;
    //     _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
    //     return;
    //   }
    //   otherPartSaved = true;
    // }, onError: (error, stacktrace) {
    //   _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    // });

    // platform.deleteTags(tagManager.deletedTags.values.toList()).then((value) {
    //   tagManager.deletedTags.clear();
    //   if (otherPartSaved) {
    //     _view.showSaveStatus('Saved!');
    //     _view.unsavedChanges = false;
    //     _updateUnsavedIndicators(tagManager.tagsByGroup, tagManager.unsavedTagIds, tagManager.unsavedGroupIds);
    //     return;
    //   }
    //   otherPartSaved = true;
    // }, onError: (error, stacktrace) {
    //   _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    // });
  }
}
