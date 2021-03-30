library view;

import 'dart:html';
import 'package:dnd/dnd.dart' as dnd;
import 'package:nook/app/configurator/view.dart';
export 'package:nook/app/configurator/view.dart';
import 'package:nook/platform/platform.dart' as platform;

import 'controller.dart';
import 'sample_data_helper.dart';

import 'package:katikati_ui_lib/components/logger.dart';

Logger log = new Logger('view.dart');

TagsConfigurationPageView _view;

class TagsConfigurationPageView extends ConfigurationPageView {
  DivElement _tagsContainer;
  Button addGroupButton;

  Map<String, TagGroupView> groups = {};

  TagsConfigurationPageView(TagsConfiguratorController controller) : super(controller) {
    _view = this;

    configurationTitle.text = 'How do you want to tag the messages and conversations?';

    _tagsContainer = new DivElement()..classes.add('tags-group-list');
    configurationContent.append(_tagsContainer);

    addGroupButton = new Button(ButtonType.add, hoverText: 'Add a new tag group', onClick: (_) => controller.command(TagsConfigAction.addTagGroup));
    addGroupButton.parent = _tagsContainer;
  }

  void addTagCategory(String id, TagGroupView tagGroupView) {
    _tagsContainer.insertBefore(tagGroupView.renderElement, addGroupButton.renderElement);
    groups[id] = tagGroupView;
  }

  void removeTagGroup(String id) {
    groups[id].renderElement.remove();
    groups.remove(id);
  }

  void clear() {
    int messagesNo = _tagsContainer.children.length;
    for (int i = 0; i < messagesNo; i++) {
      _tagsContainer.firstChild.remove();
    }
    assert(_tagsContainer.children.length == 0);
    groups.clear();
  }
}

class TagGroupView {
  DivElement _tagsGroupElement;
  DivElement _tagsContainer;
  DivElement _title;
  SpanElement _titleText;
  EditableText _editableTitle;
  Button _addTagButton;

  Map<String, TagView> tagViewsById;

  TagGroupView(String groupName) {
    _tagsGroupElement = new DivElement()..classes.add('tags-group');
    var tagsDropzone = new dnd.Dropzone(_tagsGroupElement);
    tagsDropzone.onDrop.listen((event) {
      var tag = event.draggableElement;
      var tagId = tag.dataset['id'];
      var groupId = tag.dataset['group-id'];
      _view.appController.command(TagsConfigAction.moveTag, new TagData(tagId, groupId: groupId, newGroupId: groupName));
      tag.remove();
    });

    _title = new DivElement()
      ..classes.add('tags-group__title')
      ..classes.add('foldable');
    _tagsGroupElement.append(_title);

    _titleText = new SpanElement()
      ..classes.add('tags-group__title__text')
      ..text = groupName;
    _editableTitle = new EditableText(_titleText,
        onEditStart: (_) => _title.classes.add('foldable--disabled'),
        onEditEnd: (event) {
          _title.classes.remove('foldable--disabled');
          event.preventDefault();
          event.stopPropagation();
        },
        onSave: (_) {
          _view.appController.command(TagsConfigAction.updateTagGroup, new TagGroupData(_editableTitle.textBeforeEdit, newGroupName: name));
        },
        onRemove: (_) {
          _title.classes.toggle('folded', false); // show the tag group before deletion
          var warningModal;
          warningModal = new InlineOverlayModal('Are you sure you want to remove this group?', [
            new Button(ButtonType.text,
                buttonText: 'Yes', onClick: (_) => _view.appController.command(TagsConfigAction.removeTagGroup, new TagGroupData(groupName))),
            new Button(ButtonType.text, buttonText: 'No', onClick: (_) => warningModal.remove()),
          ]);
          warningModal.parent = _tagsGroupElement;
        });
    _editableTitle.parent = _title;

    _tagsContainer = new DivElement()..classes.add('tags-group__tags');
    _tagsGroupElement.append(_tagsContainer);

    _addTagButton = new Button(ButtonType.add,
        hoverText: 'Add new tag', onClick: (_) => _view.appController.command(TagsConfigAction.addTag, new TagData(null, groupId: groupName)));
    _addTagButton.parent = _tagsContainer;

    _title.onClick.listen((event) {
      if (_title.classes.contains('foldable--disabled')) return;
      _tagsContainer.classes.toggle('hidden');
      _title.classes.toggle('folded');
    });
    // Start off folded
    _tagsContainer.classes.toggle('hidden', true);
    _title.classes.toggle('folded', true);

    tagViewsById = {};
  }

  Element get renderElement => _tagsGroupElement;

  void set name(String text) => _titleText.text = text;
  String get name => _titleText.text;

  void addTags(Map<String, TagView> tags) {
    for (var tag in tags.keys) {
      _tagsContainer.insertBefore(tags[tag].renderElement, _addTagButton.renderElement);
      tagViewsById[tag] = tags[tag];
    }
  }

  void modifyTags(Map<String, TagView> tags) {
    for (var tag in tags.keys) {
      _tagsContainer.insertBefore(tags[tag].renderElement, tagViewsById[tag].renderElement);
      tagViewsById[tag].renderElement.remove();
      tagViewsById[tag] = tags[tag];
    }
  }

  void removeTags(List<String> ids) {
    for (var id in ids) {
      tagViewsById[id]?.renderElement?.remove();
      tagViewsById.remove(id);
    }
  }
}

// This enum was adapted from Nook
enum TagStyle {
  None,
  Green,
  Yellow,
  Red,
  Important,
}

// This class was adapted from Nook
class TagView {
  DivElement tag;
  SpanElement _tagText;
  EditableText _editableTag;
  String tagId;

  static bool dragInProgress = false;

  TagView(String text, String tagId, String groupId, TagStyle tagStyle) {
    this.tagId = tagId;
    tag = new DivElement()
      ..classes.add('tag')
      ..dataset['id'] = tagId
      ..dataset['group-id'] = groupId;
    switch (tagStyle) {
      case TagStyle.Green:
        tag.classes.add('tag--green');
        break;
      case TagStyle.Yellow:
        tag.classes.add('tag--yellow');
        break;
      case TagStyle.Red:
        tag.classes.add('tag--red');
        break;
      case TagStyle.Important:
        tag.classes.add('tag--important');
        break;
      default:
    }
    var draggableTag = new dnd.Draggable(tag, avatarHandler: dnd.AvatarHandler.original(), draggingClass: 'tag__name');
    draggableTag
      ..onDragStart.listen((_) => dragInProgress = true)
      ..onDragEnd.listen((_) => dragInProgress = false);

    _tagText = new SpanElement()
      ..classes.add('tag__name')
      ..text = text
      ..title = text;

    _editableTag = new EditableText(_tagText, alwaysShowButtons: true,
        onEditStart: (_) => draggableTag.destroy(),
        onEditEnd: (_) => new dnd.Draggable(tag, avatarHandler: dnd.AvatarHandler.original(), draggingClass: 'tag__name'),
        onSave: (_) => _view.appController.command(TagsConfigAction.renameTag, new TagData(tagId, text: _tagText.text)),
        onRemove: (_) {
          var warningModal;
          warningModal = new PopupModal('Are you sure you want to remove this tag?', [
            new Button(ButtonType.text,
                buttonText: 'Yes', onClick: (_) => _view.appController.command(TagsConfigAction.removeTag, new TagData(tagId, groupId: groupId))),
            new Button(ButtonType.text, buttonText: 'No', onClick: (_) => warningModal.remove()),
          ]);
          warningModal.parent = tag;
        });
    _editableTag.parent = tag;

    var tooltip = new SampleMessagesTooltip('Sample messages for tag "$text"');
    _tagText.onMouseEnter.listen((event) {
      if (dragInProgress) return;
      tooltip.parent = tag;
      getSampleMessages(platform.firestoreInstance, this.tagId).then((value) => tooltip.displayMessages(value));
    });
    tag.onMouseLeave.listen((event) {
      tooltip.remove();
    });
  }

  void focus() => _tagText.focus();

  Element get renderElement => tag;
}

class SampleMessagesTooltip {
  DivElement tooltip;
  DivElement _messages;

  SampleMessagesTooltip(String title) {
    tooltip = new DivElement()..classes.add('tooltip');

    tooltip.append(new ParagraphElement()
      ..classes.add('tooltip__title')
      ..text = title);

    var removeButton = new Button(ButtonType.text, hoverText: 'Close sample messages tooltip', onClick: (_) => remove(), buttonText: "Close");
    removeButton.renderElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '10px';
    removeButton.parent = tooltip;

    _messages = new DivElement()..classes.add('tooltip__messages');
    tooltip.append(_messages);
  }

  void displayMessages(List<String> messages) {
    _messages.children.clear();
    for (var message in messages) {
      _messages.append(new DivElement()
        ..classes.add('tooltip__message')
        ..text = message);
    }
  }

  void set parent(Element value) => value.append(tooltip);
  void remove() => tooltip.remove();

  void set visible(bool value) {
    tooltip.classes.toggle('hidden', !value);
  }
}
