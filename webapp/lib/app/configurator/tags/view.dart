library view;

import 'dart:html';
import 'package:dnd/dnd.dart' as dnd;
import 'package:katikati_ui_lib/components/accordion/accordion.dart';
import 'package:katikati_ui_lib/components/editable/editable_text.dart';
import 'package:katikati_ui_lib/components/button/button.dart';
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

  Accordion groups = new Accordion([]);

  TagsConfigurationPageView(TagsConfiguratorController controller) : super(controller) {
    _view = this;

    configurationTitle.text = 'How do you want to tag the messages and conversations?';

    _tagsContainer = new DivElement();
    configurationContent.append(_tagsContainer);

    configurationContent.append(groups.renderElement);
    addGroupButton = new Button(ButtonType.add, hoverText: 'Add a new tag group', onClick: (_) => controller.command(TagsConfigAction.addTagGroup));
    configurationContent.append(addGroupButton.renderElement);
  }

  void addTagCategory(String id, TagGroupView tagGroupView) {
    _tagsContainer.append(tagGroupView.renderElement);
    groups.appendItem(tagGroupView);
  }

  void removeTagGroup(String id) {
    groups.removeItem(id);
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

class TagGroupView extends AccordionItem {
  String _groupName;
  TextEdit editableTitle;
  DivElement _header;
  DivElement _body;
  DivElement _tagsContainer;
  Button _addButton;

  Map<String, TagView> tagViewsById;

  TagGroupView(id, this._groupName, this._header, this._body) : super(id, _header, _body, false) {
    _groupName = _groupName ?? '';

    editableTitle = TextEdit(_groupName, removable: true)
      ..onEdit = (value) {
        _view.appController.command(TagsConfigAction.updateTagGroup, new TagGroupData(_groupName, newGroupName: value));
        _groupName = value;
      }
      ..onDelete = () {
        requestToDelete();
      };

    _header.append(editableTitle.renderElement);

    _tagsContainer = DivElement()..classes.add('tags-group__tags');
    _body.append(_tagsContainer);

    _addButton = Button(ButtonType.add);
    _addButton.renderElement.onClick.listen((e) {
      _view.appController.command(TagsConfigAction.addTag, new TagData(null, groupId: _groupName));
    });
    _body.append(_addButton.renderElement);

    var tagsDropzone = new dnd.Dropzone(renderElement);
    tagsDropzone.onDragOver.listen((event) {
      renderElement.classes.toggle('dropzone--active', true);
    });
    tagsDropzone.onDragLeave.listen((event) {
      renderElement.classes.toggle('dropzone--active', false);
    });
    tagsDropzone.onDrop.listen((event) {
      var tag = event.draggableElement;
      var tagId = tag.dataset['id'];
      var groupId = tag.dataset['group-id'];
      expand();
      _view.appController.command(TagsConfigAction.moveTag, new TagData(tagId, groupId: groupId, newGroupId: name));
      tag.remove();
    });

    tagViewsById = {};
  }

  void set name(String text) => _groupName = text;
  String get name => _groupName;

  void requestToDelete() {
    expand();
    InlineOverlayModal warningModal;
    warningModal = new InlineOverlayModal('Are you sure you want to remove this group?', [
      new Button(ButtonType.text, buttonText: 'Yes', onClick: (_) => _view.appController.command(TagsConfigAction.removeTagGroup, new TagGroupData(name))),
      new Button(ButtonType.text, buttonText: 'No', onClick: (_) => warningModal.remove()),
    ]);
    renderElement.append(warningModal.inlineOverlayModal);
  }

  void addTags(Map<String, TagView> tags) {
    for (var tag in tags.keys) {
      _tagsContainer.append(tags[tag].renderElement);
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
  ConfigureTagView(String tagText, String tagId, String groupId, TagStyle tagStyle) : super(tagText, tagId, groupId: groupId, tagStyle: tagStyle, deletable: true, editable: true) {
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
