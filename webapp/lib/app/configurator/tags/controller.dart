library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/configurator/controller.dart';
export 'package:nook/app/configurator/controller.dart';
import 'package:nook/model/model.dart' as model;
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
  Set<String> editedTagIds = {};

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
        editedTagIds.add(newTag.docId);
        break;

      case TagsConfigAction.renameTag:
        TagData tagData = data;
        model.Tag tag = tagManager.getTagById(tagData.id);
        tag.text = tagData.text;
        print(tagData.text);
        editedTagIds.add(tagData.id);
        _modifyTagsInView(Map.fromEntries(tag.groups.map((g) => new MapEntry(g, [tag]))));
        break;

      case TagsConfigAction.moveTag:
        TagData tagData = data;
        model.Tag tag = tagManager.getTagById(tagData.id);
        tag.groups.remove(tagData.groupId);
        tag.groups.add(tagData.newGroupId);
        editedTagIds.add(tagData.id);
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
          // handle removals
        } else {
          editedTagIds.add(tagData.id);
        }
        break;

      case TagsConfigAction.addTagGroup:
        var newGroupName = tagManager.nextTagGroupName;
        tagManager.namesOfEmptyGroups.add(newGroupName);
        _addTagsToView({newGroupName: []});
        break;
      case TagsConfigAction.updateTagGroup:
        TagGroupData groupData = data;

        break;
      case TagsConfigAction.removeTagGroup:

        // throw "Not implemented";
        // TODO: Handle this case.
        break;
      default:
    }
  }

  @override
  void setUpOnLogin() {
    platform.listenForConversationTags((added, modified, removed) {
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
    List<model.Tag> tagsToSave = editedTagIds.map((tagId) => tagManager.getTagById(tagId)).toList();
    _view.showSaveStatus('Saving...');
    platform.updateTags(tagsToSave).then((value) {
      _view.showSaveStatus('Saved!');
      tagsToSave.clear();
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });
  }
}
