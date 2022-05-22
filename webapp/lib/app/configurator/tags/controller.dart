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
        _addTagsToView({tagData.groupId: [tag]}, tagManager.localGroupsById, startEditing: true);
        break;

      case TagsConfigAction.requestRenameTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Renaming a tag is disabled', SnackbarNotificationType.warning));
          // Reshow the tag as the view edits it anyway
          var renamedTag = tagManager.localTagsById[tagData.id];
          _modifyTagsInView(Map.fromEntries(renamedTag.groupIds.map((g) => new MapEntry(g, [renamedTag]))), tagManager.localGroupsById); // todo: eb: confirm this works!
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
          _modifyTagsInView(Map.fromEntries(renamedTag.groupIds.map((g) => new MapEntry(g, [renamedTag]))), tagManager.localGroupsById); // todo: eb: confirm this works!
          return;
        }

        var tag = tagManager.updateTagTextInLocal(tagData.id, tagData.text);
        _modifyTagsInView(Map.fromEntries(tag.groupIds.map((g) => new MapEntry(g, [tag]))), tagManager.localGroupsById);
        _updateUnsavedIndicators(tagManager.localTagsByGroupId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.moveTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Moving a tag is disabled', SnackbarNotificationType.warning));
          // Reshow the tag as the view edits it anyway
          var movedTag = tagManager.localTagsById[tagData.id];
          _modifyTagsInView(Map.fromEntries(movedTag.groupIds.map((g) => new MapEntry(g, [movedTag]))), tagManager.localGroupsById); // todo: eb: confirm this works!
          return;
        }

        var tag = tagManager.moveTagAcrossLocalGroups(tagData.id, tagData.groupId, tagData.newGroupId);
        _removeTagsFromView({ tagData.groupId: [tag] });
        _addTagsToView({ tagData.newGroupId: [tag] }, tagManager.localGroupsById);        
        _updateUnsavedIndicators(tagManager.localTagsByGroupId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.removeTag:
        TagData tagData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Deleting a tag is disabled', SnackbarNotificationType.warning));
          return;
        }

        var tag = tagManager.removeTagInLocal(tagData.id);
        _removeTagsFromView({tagData.groupId: [tag]});
        _updateUnsavedIndicators(tagManager.localTagsByGroupId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.addTagGroup:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Adding a new tag group is disabled', SnackbarNotificationType.warning));
          return;
        }

        var group = tagManager.createGroupInLocal("new group");
        _addTagsToView({group.groupId: []}, tagManager.localGroupsById, startEditingName: true);
        _updateUnsavedIndicators(tagManager.localTagsByGroupId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.updateTagGroup:
        TagGroupData groupData = data;
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Renaming a tag group is disabled', SnackbarNotificationType.warning));
          // TODO: the tag group name still remains edited in the UI, work out how to change it
          return;
        }

        tagManager.renameGroupInLocal(groupData.id, groupData.newGroupName);
        _updateUnsavedIndicators(tagManager.localTagsByGroupId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      case TagsConfigAction.removeTagGroup:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Deleting a tag group is disabled', SnackbarNotificationType.warning));
          return;
        }

        TagGroupData groupData = data;
        tagManager.removeGroupAndTagsinLocal(groupData.id);
        _view.removeTagGroup(groupData.id);
        break;

      case TagsConfigAction.updateTagType:
        if (!currentConfig.editTagsEnabled) {
          command(BaseAction.showSnackbar, SnackbarData('Changing the tag type is disabled', SnackbarNotificationType.warning));
          return;
        }

        TagData tagData = data;
        var tag = tagManager.updateTagTypeInLocal(tagData.id, tagData.newType);
        _modifyTagsInView(Map.fromEntries(tag.groupIds.map((g) => new MapEntry(g, [tag]))), tagManager.localGroupsById);
        _updateUnsavedIndicators(tagManager.localTagsByGroupId, tagManager.editedTagIds, tagManager.editedGroupIds);
        break;

      default:
    }

    _view.unsavedChanges = tagManager.hasUnsavedTags;
  }

  @override
  void setUpOnLogin() {
    platform.listenForTags((added, modified, removed) {
      var tagsAdded = tagManager.addOrUpdateTagsInStorage(added);
      var tagsModified = tagManager.addOrUpdateTagsInStorage(modified);
      var tagsRemoved = tagManager.removeTagsFromStorage(removed.map((tag) => tag.tagId).toList());

      _addTagsToView(_groupTagsIntoCategories(tagsAdded), tagManager.storageGroupsById);
      _modifyTagsInView(_groupTagsIntoCategories(tagsModified), tagManager.storageGroupsById);
      _removeTagsFromView(_groupTagsIntoCategories(tagsRemoved));
      _updateUnsavedIndicators(tagManager.localTagsByGroupId, tagManager.editedTagIds, tagManager.editedGroupIds);
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
        tagManager.removeAllEditedTags();
        tagManager.removeAllDeletedTags();
        tagManager.removeAllEditedGroups();

        // todo: eb: convert this to a helper function to copy over storage to local
        tagManager.localTagsById = {};
        tagManager.storageTagsById.keys.forEach((tagId) {
          tagManager.localTagsById[tagId] = tagManager.storageTagsById[tagId]; // todo: eb: clone!
        });
        _view.showSaveStatus('Modifying tags has been disabled, dropping all changes');
        _view.unsavedChanges = false;
        // todo: eb: fix existing bug / reset view to discard all user made changes!
        _updateUnsavedIndicators(tagManager.localTagsByGroupId, tagManager.editedTagIds, tagManager.editedGroupIds);
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
  void saveConfiguration() async {
    _view.showSaveStatus('Saving...');
    _view.disableSaveButton();

    // ignore: placeholder for tool/adhoc/tag-data-index-id-script.txt

    try {
      await Future.wait([platform.updateTags(tagManager.editedTags), platform.deleteTags(tagManager.deletedTags)]);
      _view
        ..unsavedChanges = false
        ..showSaveStatus('Saved!', autoHide: true);
    } catch (err) {
      _view
        ..hideSaveStatus()
        ..showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    }
  }
}
