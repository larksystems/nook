library view;

import 'dart:async';
import 'dart:html';
import 'package:katikati_ui_lib/components/accordion/accordion.dart';
import 'package:katikati_ui_lib/components/editable/editable_text.dart';
import 'package:katikati_ui_lib/components/button/button.dart';
import 'package:nook/app/configurator/view.dart';
export 'package:nook/app/configurator/view.dart';

import 'controller.dart';
import 'package:katikati_ui_lib/components/logger.dart';

Logger log = new Logger('view.dart');

MessagesConfigurationPageView _view;

class MessagesConfigurationPageView extends ConfigurationPageView {
  DivElement _messagesContainer;
  Button _addButton;

  Accordion categories;

  Map<String, StandardMessagesCategoryView> categoriesById = {};

  MessagesConfigurationPageView(MessagesConfiguratorController controller) : super(controller) {
    _view = this;

    configurationTitle.text = 'What do you want to say?';

    _messagesContainer = new DivElement();
    configurationContent.append(_messagesContainer);

    categories = new Accordion([]);
    configurationContent.append(categories.renderElement);

    _addButton = new Button(ButtonType.add, hoverText: 'Add a new message category', onClick: (_) => _view.appController.command(MessagesConfigAction.addStandardMessagesCategory));
    configurationContent.append(_addButton.renderElement);
  }

  void addCategory(String categoryId, StandardMessagesCategoryView categoryView) {
    categories.appendItem(categoryView);
    categoriesById[categoryId] = categoryView;
  }

  void renameCategory(String categoryId, String categoryName, String newCategoryName) {
    var categoryView = _view.categoriesById.remove(categoryId); // why remove?
    categoryView.id = categoryId;
    categoryView.name = newCategoryName;
    categoriesById[categoryId] = categoryView;
    categories.updateItem(categoryId, categoryView);
  }

  void removeCategory(String categoryId) {
    categories.removeItem(categoryId);
    categoriesById.remove(categoryId);
  }

  void clear() {
    categories.clear();
  }

  void clearUnsavedIndicators() {
    categoriesById.keys.forEach((categoryId) {
      categoriesById[categoryId].markAsUnsaved(false);
      categoriesById[categoryId].groupsById.keys.forEach((groupId) {
        categoriesById[categoryId].groupsById[groupId].markAsUnsaved(false);
        categoriesById[categoryId].groupsById[groupId].messagesById.keys.forEach((messageId) {
          categoriesById[categoryId].groupsById[groupId].messagesById[messageId].markAsUnsaved(false);
        });
      });
    });
  }
}

class StandardMessagesCategoryView extends AccordionItem {
  String _categoryId;
  String _categoryName;
  DivElement _standardMessagesGroupContainer;
  Button _addButton;
  TextEdit editableTitle;

  Accordion groups;

  Map<String, StandardMessagesGroupView> groupsById = {};

  StandardMessagesCategoryView(String this._categoryId, this._categoryName, DivElement header, DivElement body) : super(_categoryId, header, body, false) {
    _categoryName = _categoryName ?? '';

    editableTitle = TextEdit(_categoryName, removable: true)
      ..testInput = (String value) {
        var messageManager = (_view.appController as MessagesConfiguratorController).standardMessagesManager;
        var categories = messageManager.standardMessages.map((e) => e.category).toSet();
        categories.remove(id);
        return !categories.contains(value);
      }
      ..onEdit = (value) {
        _view.appController.command(MessagesConfigAction.updateStandardMessagesCategory, new StandardMessagesCategoryData(_categoryId, _categoryName, newCategoryName: value));
        _categoryName = value;
      }
      ..onDelete = () {
        requestToDelete();
      };
    header.append(editableTitle.renderElement);

    _standardMessagesGroupContainer = new DivElement()..classes.add('standard-messages__group');
    body.append(_standardMessagesGroupContainer);

    groups = new Accordion([]);
    _standardMessagesGroupContainer.append(groups.renderElement);

    _addButton = Button(ButtonType.add, hoverText: 'Add a new group of standard messages', onClick: (event) => _view.appController.command(MessagesConfigAction.addStandardMessagesGroup, new StandardMessagesGroupData(_categoryId, _categoryName, null, 'New group')));

    body.append(_addButton.renderElement);
  }

  void set name(String value) => _categoryName = value;
  String get name => _categoryName;

  void addGroup(String groupId, StandardMessagesGroupView standardMessagesGroupView, [int index]) {
    if (index == null || groups.items.length == index) {
      groups.appendItem(standardMessagesGroupView);
    } else {
      groups.insertItem(standardMessagesGroupView, index);
    }
    groupsById[groupId] = standardMessagesGroupView;
  }

  void renameGroup(String groupId, String groupName, String newGroupName) {
    var groupView = groupsById.remove(groupId);
    // groupView.id = newGroupName;
    groupsById[groupId] = groupView;
    groups.updateItem(groupId, groupView);
  }

  void removeGroup(String groupName) {
    groupsById[groupName].renderElement.remove();
    groupsById.remove(groupName);
  }

  void requestToDelete() {
    expand();
    var standardMessagesCategoryData = new StandardMessagesCategoryData(_categoryId, _categoryName);
    var removeWarningModal;
    removeWarningModal = new InlineOverlayModal('Are you sure you want to remove this category?', [
        new Button(ButtonType.text,
            buttonText: 'Yes', onClick: (_) => _view.appController.command(MessagesConfigAction.removeStandardMessagesCategory, standardMessagesCategoryData)),
        new Button(ButtonType.text, buttonText: 'No', onClick: (_) => removeWarningModal.remove()),
      ]);
    renderElement.append(removeWarningModal.inlineOverlayModal);
  }

  void markAsUnsaved(bool unsaved) {
    editableTitle.renderElement.classes.toggle("unsaved", unsaved);
  }
}

class StandardMessagesGroupView extends AccordionItem {
  String _categoryId;
  String _categoryName;
  String _groupId;
  String _groupName;
  DivElement _standardMessagesContainer;
  Button _addButton;
  TextEdit editableTitle;

  Map<String, StandardMessageView> messagesById = {};

  StandardMessagesGroupView(this._categoryId, this._categoryName, this._groupId, this._groupName, DivElement header, DivElement body) : super(_groupId, header, body, false) {
    editableTitle = TextEdit(_groupName, removable: true)
      ..testInput = (String value) {
        var messageManager = (_view.appController as MessagesConfiguratorController).standardMessagesManager;
        var groups = messageManager.standardMessages.map((e) => e.group_description).toSet();
        groups.remove(id);
        return !groups.contains(value);
      }
      ..onEdit = (value) {
        _view.appController.command(MessagesConfigAction.updateStandardMessagesGroup, new StandardMessagesGroupData(_categoryId, _categoryName, _groupId, _groupName, newGroupName: value));
      }
      ..onDelete = () {
        requestToDelete();
      };
    header.append(editableTitle.renderElement);

    _standardMessagesContainer = DivElement();
    body.append(_standardMessagesContainer);

    _addButton = Button(ButtonType.add);
    _addButton.renderElement.onClick.listen((e) {
      _view.appController.command(MessagesConfigAction.addStandardMessage, new StandardMessageData(null, groupId: _groupId, categoryId: _categoryId));
    });

    body.append(_addButton.renderElement);
  }

  void addMessage(String messageId, StandardMessageView standardMessageView) {
    _standardMessagesContainer.append(standardMessageView.renderElement);
    messagesById[messageId] = standardMessageView;
  }

  void modifyMessage(String messageId, StandardMessageView standardMessageView) {
    _standardMessagesContainer.insertBefore(standardMessageView.renderElement, messagesById[messageId].renderElement);
    messagesById[messageId].renderElement.remove();
    messagesById[messageId] = standardMessageView;
  }

  void removeMessage(String messageId) {
    messagesById[messageId].renderElement.remove();
    messagesById.remove(messageId);
  }

  void requestToDelete() {
    expand();
    var standardMessagesGroupData = new StandardMessagesGroupData(_categoryId, _categoryName, _groupId, _groupName);
    var removeWarningModal;
    removeWarningModal = new InlineOverlayModal('Are you sure you want to remove this group?', [
        new Button(ButtonType.text,
            buttonText: 'Yes', onClick: (_) => _view.appController.command(MessagesConfigAction.removeStandardMessagesGroup, standardMessagesGroupData)),
        new Button(ButtonType.text, buttonText: 'No', onClick: (_) => removeWarningModal.remove()),
      ]);
    renderElement.append(removeWarningModal.inlineOverlayModal);
  }

  void markAsUnsaved(bool unsaved) {
    editableTitle.renderElement.classes.toggle("unsaved", unsaved);
  }
}

class StandardMessageView {
  Element _standardMessageElement;

  StandardMessageView(String messageId, String text, String translation) {
    _standardMessageElement = new DivElement()
      ..classes.add('standard-message')
      ..dataset['id'] = '$messageId';

    var textView = new MessageView(text, (text) => _view.appController.command(MessagesConfigAction.updateStandardMessage, new StandardMessageData(messageId, text: text)));
    var translationView = new MessageView(translation, (translation) => _view.appController.command(MessagesConfigAction.updateStandardMessage, new StandardMessageData(messageId, translation: translation)), placeholder: '(optional) Translate the message in a secondary language here');
    _standardMessageElement
      ..append(textView.renderElement)
      ..append(translationView.renderElement);
    _makeStandardMessageViewTextareasSynchronisable([textView, translationView]);

    var removeButton = new Button(ButtonType.remove, hoverText: 'Remove standard message', onClick: (_) {
      var removeWarningModal;
      removeWarningModal = new InlineOverlayModal('Are you sure you want to remove this message?', [
        new Button(ButtonType.text,
            buttonText: 'Yes', onClick: (_) => _view.appController.command(MessagesConfigAction.removeStandardMessage, new StandardMessageData(messageId))),
        new Button(ButtonType.text, buttonText: 'No', onClick: (_) => removeWarningModal.remove()),
      ]);
      removeWarningModal.parent = _standardMessageElement;
    });
    removeButton.parent = _standardMessageElement;
  }

  Element get renderElement => _standardMessageElement;

  void markAsUnsaved(bool unsaved) {
    _standardMessageElement.classes.toggle("unsaved", unsaved);
  }
}

class MessageView {
  Element _messageElement;
  TextAreaElement _messageText;
  Function onMessageUpdateCallback;
  Function _onTextareaHeightChangeCallback;

  MessageView(String message, this.onMessageUpdateCallback, {String placeholder = ''}) {
    _messageElement = new DivElement()..classes.add('message');

    var textLengthIndicator = new SpanElement()
      ..classes.add('message__length-indicator')
      ..classes.toggle('message__length-indicator--alert', message.length > _view.appController.MESSAGE_MAX_LENGTH)
      ..text = '${message.length}/${_view.appController.MESSAGE_MAX_LENGTH}';

    _messageText = new TextAreaElement()
      ..classes.add('message__text')
      ..classes.toggle('message__text--alert', message.length > _view.appController.MESSAGE_MAX_LENGTH)
      ..text = message != null ? message : ''
      ..placeholder = placeholder
      ..contentEditable = 'true'
      ..onBlur.listen((event) => onMessageUpdateCallback((event.target as TextAreaElement).value))
      ..onInput.listen((event) {
        int count = _messageText.value.split('').length;
        textLengthIndicator.text = '${count}/${_view.appController.MESSAGE_MAX_LENGTH}';
        _messageText.classes.toggle('message__text--alert', count > _view.appController.MESSAGE_MAX_LENGTH);
        textLengthIndicator.classes.toggle('message__length-indicator--alert', count > _view.appController.MESSAGE_MAX_LENGTH);
        _handleTextareaHeightChange();
      });

    _messageElement..append(_messageText)..append(textLengthIndicator);
    finaliseRenderAsync();
  }

  Element get renderElement => _messageElement;

  void set textareaHeight(int height) => _messageText.style.height = '${height - 6}px';

  /// Returns the height of the content text in the textarea element.
  int get textareaScrollHeight {
    var height = _messageText.style.height;
    _messageText.style.height = '0';
    var scrollHeight = _messageText.scrollHeight;
    _messageText.style.height = height;
    return scrollHeight;
  }

  /// This method reports the height of the content text (if the callback is set).
  void _handleTextareaHeightChange() {
    if (_onTextareaHeightChangeCallback == null) return;
    _onTextareaHeightChangeCallback(textareaScrollHeight);
  }

  /// The message view is added to the DOM at some later point, outside this class.
  /// This method periodically polls until the element has been added to the DOM (height > 0)
  /// and then triggers the first [_handleTextareaHeightChange] so that the parent can
  /// synchronise the height between this message and its sibling(s).
  void finaliseRenderAsync() {
    Timer.periodic(new Duration(milliseconds: 10), (timer) {
      if (_messageText.scrollHeight == 0) return;
      _handleTextareaHeightChange();
      timer.cancel();
    });
  }
}

_makeStandardMessageViewTextareasSynchronisable(List<MessageView> messageViews) {
  var onTextareaHeightChangeCallback = (int height) {
    var maxHeight = height;
    for (var messageView in messageViews) {
      var textareaScrollHeight = messageView.textareaScrollHeight;
      if (textareaScrollHeight > maxHeight) {
        maxHeight = textareaScrollHeight;
      }
    }
    for (var messageView in messageViews) {
      messageView.textareaHeight = maxHeight;
    }
  };

  for (var messageView in messageViews) {
    messageView._onTextareaHeightChangeCallback = onTextareaHeightChangeCallback;
  }
}
