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

  Map<String, StandardMessagesCategoryView> categoriesByName = {};

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

  void addCategory(String category, StandardMessagesCategoryView categoryView) {
    categories.appendItem(categoryView);
    categoriesByName[category] = categoryView;
  }

  void renameCategory(String categoryName, String newCategoryName) {
    var categoryView = _view.categoriesByName.remove(categoryName);
    categoryView.id = newCategoryName;
    categoryView.name = newCategoryName;
    categoriesByName[newCategoryName] = categoryView;
    categories.updateItem(newCategoryName, categoryView);
  }

  void removeCategory(String category) {
    categories.removeItem(category);
    categoriesByName.remove(category);
  }

  void clear() {
    categories.clear();
  }
}

class StandardMessagesCategoryView extends AccordionItem {
  String _categoryName;
  DivElement _standardMessagesGroupContainer;
  Button _addButton;
  TextEdit editableTitle;

  Accordion groups;

  Map<String, StandardMessagesGroupView> groupsByName = {};

  StandardMessagesCategoryView(this._categoryName, DivElement header, DivElement body) : super(_categoryName, header, body, false) {
    _categoryName = _categoryName ?? '';

    editableTitle = TextEdit(_categoryName, removable: true)
      ..testInput = (String value) {
        var messageManager = (_view.appController as MessagesConfiguratorController).standardMessagesManager;
        var categories = messageManager.standardMessages.map((e) => e.category).toSet();
        categories.remove(id);
        return !categories.contains(value);
      }
      ..onEdit = (value) {
        _view.appController.command(MessagesConfigAction.updateStandardMessagesCategory, new StandardMessagesCategoryData(_categoryName, newCategoryName: value));
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

    _addButton = Button(ButtonType.add, hoverText: 'Add a new group of standard messages', onClick: (event) => _view.appController.command(MessagesConfigAction.addStandardMessagesGroup, new StandardMessagesGroupData(_categoryName, '')));

    body.append(_addButton.renderElement);
  }

  void set name(String value) => _categoryName = value;
  String get name => _categoryName;

  void addGroup(String groupName, StandardMessagesGroupView standardMessagesGroupView) {
    groups.appendItem(standardMessagesGroupView);
    groupsByName[groupName] = standardMessagesGroupView;
  }

  void renameGroup(String groupName, String newGroupName) {
    var groupView = groupsByName.remove(groupName);
    groupView.id = newGroupName;
    groupsByName[newGroupName] = groupView;
    groups.updateItem(newGroupName, groupView);
  }

  void removeGroup(String groupName) {
    groupsByName[groupName].renderElement.remove();
    groupsByName.remove(groupName);
  }

  void requestToDelete() {
    expand();
    var standardMessagesCategoryData = new StandardMessagesCategoryData(id);
    var removeWarningModal;
    removeWarningModal = new InlineOverlayModal('Are you sure you want to remove this category?', [
        new Button(ButtonType.text,
            buttonText: 'Yes', onClick: (_) => _view.appController.command(MessagesConfigAction.removeStandardMessagesCategory, standardMessagesCategoryData)),
        new Button(ButtonType.text, buttonText: 'No', onClick: (_) => removeWarningModal.remove()),
      ]);
    renderElement.append(removeWarningModal.inlineOverlayModal);
  }
}

class StandardMessagesGroupView extends AccordionItem {
  String _categoryName;
  DivElement _standardMessagesContainer;
  Button _addButton;
  TextEdit editableTitle;

  Map<String, StandardMessageView> messagesById = {};

  StandardMessagesGroupView(this._categoryName, String groupName, DivElement header, DivElement body) : super(groupName, header, body, false) {
    editableTitle = TextEdit(groupName, removable: true)
      ..testInput = (String value) {
        var messageManager = (_view.appController as MessagesConfiguratorController).standardMessagesManager;
        var groups = messageManager.standardMessages.map((e) => e.group_description).toSet();
        groups.remove(id);
        return !groups.contains(value);
      }
      ..onEdit = (value) {
        _view.appController.command(MessagesConfigAction.updateStandardMessagesGroup, new StandardMessagesGroupData(_categoryName, id, newGroupName: value));
      }
      ..onDelete = () {
        requestToDelete();
      };
    header.append(editableTitle.renderElement);

    _standardMessagesContainer = DivElement();
    body.append(_standardMessagesContainer);

    _addButton = Button(ButtonType.add);
    _addButton.renderElement.onClick.listen((e) {
      _view.appController.command(MessagesConfigAction.addStandardMessage, new StandardMessageData('', group: id, category: _categoryName));
    });

    body.append(_addButton.renderElement);
  }

  void addMessage(String id, StandardMessageView standardMessageView) {
    _standardMessagesContainer.append(standardMessageView.renderElement);
    messagesById[id] = standardMessageView;
  }

  void modifyMessage(String id, StandardMessageView standardMessageView) {
    _standardMessagesContainer.insertBefore(standardMessageView.renderElement, messagesById[id].renderElement);
    messagesById[id].renderElement.remove();
    messagesById[id] = standardMessageView;
  }

  void removeMessage(String id) {
    messagesById[id].renderElement.remove();
    messagesById.remove(id);
  }

  void requestToDelete() {
    expand();
    var standardMessagesGroupData = new StandardMessagesGroupData(_categoryName, id);
    var removeWarningModal;
    removeWarningModal = new InlineOverlayModal('Are you sure you want to remove this group?', [
        new Button(ButtonType.text,
            buttonText: 'Yes', onClick: (_) => _view.appController.command(MessagesConfigAction.removeStandardMessagesGroup, standardMessagesGroupData)),
        new Button(ButtonType.text, buttonText: 'No', onClick: (_) => removeWarningModal.remove()),
      ]);
    renderElement.append(removeWarningModal.inlineOverlayModal);
  }
}

class StandardMessageView {
  Element _standardMessageElement;

  StandardMessageView(String id, String text, String translation) {
    _standardMessageElement = new DivElement()
      ..classes.add('standard-message')
      ..dataset['id'] = '$id';

    var textView = new MessageView(
        0, text, (index, text) => _view.appController.command(MessagesConfigAction.updateStandardMessage, new StandardMessageData(id, text: text)));
    var translationView = new MessageView(0, translation,
        (index, translation) => _view.appController.command(MessagesConfigAction.updateStandardMessage, new StandardMessageData(id, translation: translation)));
    _standardMessageElement..append(textView.renderElement)..append(translationView.renderElement);
    _makeStandardMessageViewTextareasSynchronisable([textView, translationView]);

    var removeButton = new Button(ButtonType.remove, hoverText: 'Remove standard message', onClick: (_) {
      var removeWarningModal;
      removeWarningModal = new InlineOverlayModal('Are you sure you want to remove this message?', [
        new Button(ButtonType.text,
            buttonText: 'Yes', onClick: (_) => _view.appController.command(MessagesConfigAction.removeStandardMessage, new StandardMessageData(id))),
        new Button(ButtonType.text, buttonText: 'No', onClick: (_) => removeWarningModal.remove()),
      ]);
      removeWarningModal.parent = _standardMessageElement;
    });
    removeButton.parent = _standardMessageElement;
  }

  Element get renderElement => _standardMessageElement;
}

class MessageView {
  Element _messageElement;
  TextAreaElement _messageText;
  Function onMessageUpdateCallback;
  Function _onTextareaHeightChangeCallback;

  MessageView(int index, String message, this.onMessageUpdateCallback) {
    _messageElement = new DivElement()..classes.add('message');

    var textLengthIndicator = new SpanElement()
      ..classes.add('message__length-indicator')
      ..classes.toggle('message__length-indicator--alert', message.length > 160)
      ..text = '${message.length}/160';

    _messageText = new TextAreaElement()
      ..classes.add('message__text')
      ..classes.toggle('message__text--alert', message.length > 160)
      ..text = message != null ? message : ''
      ..contentEditable = 'true'
      ..dataset['index'] = '$index'
      ..onBlur.listen((event) => onMessageUpdateCallback(index, (event.target as TextAreaElement).value))
      ..onInput.listen((event) {
        int count = _messageText.value.split('').length;
        textLengthIndicator.text = '${count}/160';
        _messageText.classes.toggle('message__text--alert', count > 160);
        textLengthIndicator.classes.toggle('message__length-indicator--alert', count > 160);
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
