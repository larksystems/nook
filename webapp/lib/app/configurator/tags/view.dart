library view;

import 'dart:html';
import 'package:dnd/dnd.dart' as dnd;
import 'package:nook/app/configurator/view.dart';
export 'package:nook/app/configurator/view.dart';
import 'package:nook/platform/platform.dart' as platform;
import 'package:katikati_ui_lib/components/tag/tag.dart';

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
      _view.appController.command(TagsConfigAction.moveTag, new TagData(tagId, groupId: groupId, newGroupId: name));
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
                buttonText: 'Yes', onClick: (_) => _view.appController.command(TagsConfigAction.removeTagGroup, new TagGroupData(name))),
            new Button(ButtonType.text, buttonText: 'No', onClick: (_) => warningModal.remove()),
          ]);
          warningModal.parent = _tagsGroupElement;
        });
    _editableTitle.parent = _title;

    _tagsContainer = new DivElement()..classes.add('tags-group__tags');
    _tagsGroupElement.append(_tagsContainer);

    _addTagButton = new Button(ButtonType.add,
        hoverText: 'Add new tag', onClick: (_) => _view.appController.command(TagsConfigAction.addTag, new TagData(null, groupId: name)));
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


class ConfigureTagView extends TagView {
  static bool dragInProgress = false;
  ConfigureTagView(String tagText, String tagId, String groupId, TagStyle tagStyle) : super(tagText, tagId, groupId: groupId, tagStyle: tagStyle, removable: true, editable: true) {
    var draggableTag = new dnd.Draggable(renderElement, avatarHandler: dnd.AvatarHandler.original(), draggingClass: 'tag__text');
    draggableTag
      ..onDragStart.listen((_) => dragInProgress = true)
      ..onDragEnd.listen((_) => dragInProgress = false);

    onEdit = (text) {
      _view.appController.command(TagsConfigAction.renameTag, new TagData(tagId, text: text));
    };
    onDelete = () {
      var warningModal;
      warningModal = new PopupModal('Are you sure you want to remove this tag?', [
        new Button(ButtonType.text,
            buttonText: 'Yes', onClick: (_) => _view.appController.command(TagsConfigAction.removeTag, new TagData(tagId, groupId: groupId))),
        new Button(ButtonType.text, buttonText: 'No', onClick: (_) => warningModal.remove()),
      ]);
      warningModal.parent = renderElement;
    };

    var tooltip = new SampleMessagesTooltip('Sample messages for tag "$tagText"');
    onMouseEnter = () {
      if (dragInProgress) return;
      tooltip.parent = renderElement;
      getSampleMessages(platform.firestoreInstance, tagId).then((value) => tooltip.displayMessages(value));
    };
    onMouseLeave = () {
      tooltip.remove();
    };
  }
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
