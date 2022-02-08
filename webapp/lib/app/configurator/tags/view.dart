library view;

import 'dart:async';
import 'dart:html';
import 'package:dnd/dnd.dart' as dnd;
import 'package:katikati_ui_lib/components/accordion/accordion.dart';
import 'package:katikati_ui_lib/components/editable/editable_text.dart';
import 'package:katikati_ui_lib/components/button/button.dart';
import 'package:katikati_ui_lib/components/menu/menu.dart';
import 'package:katikati_ui_lib/components/model/model.dart';
import 'package:nook/app/configurator/view.dart';
export 'package:nook/app/configurator/view.dart';
import 'package:nook/platform/platform.dart' as platform;
import 'package:katikati_ui_lib/components/tag/tag.dart';

import 'controller.dart';
import 'sample_data_helper.dart';

import 'package:katikati_ui_lib/components/logger.dart';

const DRAG_AUTOSCROLL_OFFSET = 30;
const DRAG_AUTOSCROLL_SPEED = 5;

Logger log = new Logger('view.dart');

TagsConfigurationPageView _view;

class TagsConfigurationPageView extends ConfigurationPageView {
  DivElement _tagsContainer;
  Button addGroupButton;

  Accordion groups;

  TagsConfigurationPageView(TagsConfiguratorController controller) : super(controller) {
    _view = this;

    configurationTitle.text = 'How do you want to tag the messages and conversations?';

    _tagsContainer = new DivElement();
    configurationContent.append(_tagsContainer);

    groups = new Accordion([]);
    configurationContent.append(groups.renderElement);

    addGroupButton = new Button(ButtonType.add, hoverText: 'Add a new tag group', onClick: (_) => controller.command(TagsConfigAction.addTagGroup));
    configurationContent.append(addGroupButton.renderElement);
  }

  void addTagCategory(String id, TagGroupView tagGroupView) {
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

  Map<String, ConfigureTagView> tagViewsById;

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

  void showDuplicateWarningModal(String tagId, String text) {
    tagViewsById[tagId]?.showDuplicateTagsWarningModal(text);
  }

  void markAsUnsaved(bool unsaved) {
    editableTitle.renderElement.classes.toggle("unsaved", unsaved);
  }
}

class ConfigureTagView extends TagView {
  static bool dragInProgress = false;
  bool _tooltipInTransition = false;
  PopupModal warningModal;

  Function(String text) showDuplicateTagsWarningModal;

  ConfigureTagView(String tagText, String tagId, String groupId, TagStyle tagStyle, List<MenuItem> menuItems)
      : super(tagText, tagId, groupId: groupId, tagStyle: tagStyle, deletable: true, editable: true, menuItems: menuItems) {
    var draggableTag = new dnd.Draggable(renderElement, avatarHandler: dnd.AvatarHandler.original(), draggingClass: 'tag__text--dragging');
    draggableTag
      ..onDragStart.listen((_) => dragInProgress = true)
      ..onDragEnd.listen((_) => dragInProgress = false)
      ..onDrag.listen((event) {
        num relativePositionY = event.position.y - window.pageYOffset;
        if (relativePositionY > window.innerHeight - window.screenY - DRAG_AUTOSCROLL_OFFSET) {
          window.scrollBy(0, DRAG_AUTOSCROLL_SPEED);
        } else if (relativePositionY < DRAG_AUTOSCROLL_OFFSET) {
          window.scrollBy(0, -DRAG_AUTOSCROLL_SPEED);
        }
      });

    onEdit = (text) {
      if (tagText.trim().toLowerCase() == text.trim().toLowerCase()) return;
      var requestRenameTagData = new TagData(tagId, groupId: groupId, text: text);
      _view.appController.command(TagsConfigAction.requestRenameTag, requestRenameTagData);
    };

    this.showDuplicateTagsWarningModal = (String text) {
      warningModal = PopupModal('A tag with text [${text}] already exists.', [
        Button(ButtonType.text, buttonText: 'Go back', onClick: (_) {
          warningModal.remove();
          this.text = tagText;
          beginEdit();
        })
      ]);
      warningModal.parent = renderElement;
    };

    onDelete = () async {
      var warningModal;
      var messages = await getSampleMessages(platform.firestoreInstance, tagId) ?? [];

      if (messages.isNotEmpty) {
        warningModal = new PopupModal('Tag [${tagText}] is being used in ${messages.length} messages, and cannot be removed.', [
          new Button(ButtonType.text, buttonText: 'Close', onClick: (_) => warningModal.remove()),
        ]);
      } else {
        warningModal = new PopupModal('Are you sure you want to remove this tag [${tagText}]?', [
          new Button(ButtonType.text,
              buttonText: 'Yes', onClick: (_) => _view.appController.command(TagsConfigAction.removeTag, new TagData(tagId, groupId: groupId))),
          new Button(ButtonType.text, buttonText: 'No', onClick: (_) => warningModal.remove()),
        ]);
      }
      warningModal.parent = renderElement;
    };

    var tooltip = new SampleMessagesTooltip('Sample messages for tag "$tagText"', tagId);
    tooltip.onMouseEnter = () {
      _tooltipInTransition = true;
      tooltip.parent = renderElement;
    };
    tooltip.onMouseLeave = () {
      _tooltipInTransition = false;
      tooltip.remove();
    };

    onMouseEnter = () {
      if (dragInProgress) return;
      if ((_view.appController as TagsConfiguratorController).currentConfig.sampleMessagesEnabled) {
        tooltip.parent = renderElement;
        getSampleMessages(platform.firestoreInstance, tagId).then((value) => tooltip.displayMessages(value));
      }
    };
    onMouseLeave = () {
      Timer(Duration(milliseconds: 100), () {
        if (!_tooltipInTransition) {
          tooltip.remove();
        }
      });
    };
  }

  void markAsUnsaved(bool unsaved) {
    renderElement.classes.toggle("unsaved", unsaved);
  }
}

class SampleMessagesTooltip {
  DivElement tooltip;
  String _tagId;
  DivElement _messages;
  Function onMouseEnter;
  Function onMouseLeave;

  SampleMessagesTooltip(String title, this._tagId) {
    tooltip = new DivElement()
      ..classes.add('tooltip')
      ..onMouseEnter.listen((e) {
        if (onMouseEnter == null) return;
        onMouseEnter();
      })
      ..onMouseLeave.listen((e) {
        if (onMouseLeave == null) return;
        onMouseLeave();
      });

    var titleElement = new AnchorElement(href: _linkToFilteredConversationView(tagId: _tagId))..classes.add('tooltip__title');
    titleElement.append(SpanElement()..className = 'fas fa-external-link-square-alt');
    titleElement.append(SpanElement()..innerText = " ${title}");
    tooltip.append(titleElement);

    var removeButton = new Button(ButtonType.text, hoverText: 'Close sample messages tooltip', onClick: (_) => remove(), buttonText: "Close");
    removeButton.renderElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '10px';
    removeButton.parent = tooltip;

    _messages = new DivElement()..classes.add('tooltip__messages');
    var loadingText = DivElement()
      ..classes.add('tooltip__placeholder')
      ..innerText = "Loading...";
    _messages..append(loadingText);

    tooltip.append(_messages);
  }

  void displayMessages(List<Message> messages) {
    _messages.children.clear();

    if (messages.isEmpty) {
      var noMessageText = SpanElement()
        ..classes.add("tooltip__placeholder")
        ..innerText = "No messages with this tag.";
      _messages.append(noMessageText);
      return;
    }

    for (var message in messages) {
      var messageLink = AnchorElement(href: _linkToFilteredConversationView(messageId: message.id, tagId: _tagId))..classes.add('tooltip__message');
      var linkIcon = SpanElement()..className = 'fas fa-external-link-alt';
      var messageText = SpanElement()..innerText = "  ${message.text}";
      messageLink..append(linkIcon)..append(messageText);
      _messages.append(messageLink);
    }
  }

  String _linkToFilteredConversationView({String messageId, String tagId}) {
    Map<String, String> queryParams = {};
    if (messageId != null) {
      queryParams["conversation-id"] = messageId.replaceAll('nook-message-', '').substring(0, 52);
    }
    if (tagId != null) {
      queryParams["include-filter"] = tagId;
    }
    String queryString = Uri(queryParameters: queryParams).query;
    return "/converse/index.html?${queryString}";
  }

  void set parent(Element value) => value.append(tooltip);
  void remove() => tooltip.remove();

  void set visible(bool value) {
    tooltip.classes.toggle('hidden', !value);
  }
}
