library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/configurator/controller.dart';
export 'package:nook/app/configurator/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:katikati_ui_lib/components/tag/tag.dart';
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

  /// Used when removing or moving a tag
  String groupId;

  /// Used when moving a tag
  String newGroupId;

  TagData(this.id, {this.text, this.groupId, this.newGroupId});

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

      case TagsConfigAction.renameTag:
        TagData tagData = data;
        var tag = tagManager.modifyTag(tagData.id, text: tagData.text);
        _modifyTagsInView(Map.fromEntries(tag.groups.map((g) => new MapEntry(g, [tag]))));
        break;

      case TagsConfigAction.moveTag:
        TagData tagData = data;
        model.Tag tag = tagManager.modifyTag(tagData.id, group: tagData.newGroupId);
        // update the view by removing the tag and then adding it
        _removeTagsFromView({
          tagData.groupId: [tag]
        });
        _addTagsToView({
          tagData.newGroupId: [tag]
        });
        break;

      case TagsConfigAction.removeTag:
        TagData tagData = data;
        model.Tag tag = tagManager.deleteTag(tagData.id);
        _removeTagsFromView({
          tagData.groupId: [tag]
        });
        break;

      case TagsConfigAction.addTagGroup:
        var newGroupName = tagManager.createTagGroup();
        _addTagsToView({newGroupName: []}, startEditingName: true);
        break;

      case TagsConfigAction.updateTagGroup:
        TagGroupData groupData = data;
        tagManager.renameTagGroup(groupData.groupName, groupData.newGroupName);

        var groupView = _view.groups[groupData.groupName];
        groupView.name = groupData.newGroupName;
        _view.groups.remove(groupData.groupName);
        _view.groups[groupData.newGroupName] = groupView;
        break;

      case TagsConfigAction.removeTagGroup:
        TagGroupData groupData = data;
        tagManager.deleteTagGroup(groupData.groupName);
        _view.removeTagGroup(groupData.groupName);
        break;

      default:
    }

    if (tagManager.hasUnsavedTags) {
      _view.enableSaveButton();
    } else {
      _view.disableSaveButton();
    }
  }

  @override
  void setUpOnLogin() {
    platform.listenForTags((added, modified, removed) {
      var tagsAdded = tagManager.addTags(added);
      var tagsModified = tagManager.updateTags(modified);
      var tagsDeleted = tagManager.removeTags(removed);

      _addTagsToView(_groupTagsIntoCategories(tagsAdded));
      _modifyTagsInView(_groupTagsIntoCategories(tagsModified));
      _removeTagsFromView(_groupTagsIntoCategories(tagsDeleted));
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
        _view.disableSaveButton();
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
        _view.disableSaveButton();
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });
  }
}
