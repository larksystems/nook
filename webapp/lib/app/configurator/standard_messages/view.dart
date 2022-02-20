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

  void renameCategory(String categoryId, String newCategoryName) {
    var categoryView = _view.categoriesById[categoryId];
    categoryView
      ..id = categoryId
      ..name = newCategoryName;
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
          categoriesById[categoryId].groupsById[groupId].messagesById[messageId].markTextAsUnsaved(false);
          categoriesById[categoryId].groupsById[groupId].messagesById[messageId].markTranslationAsUnsaved(false);
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
  Element _alternativeElement;

  Accordion groups;

  Map<String, StandardMessagesGroupView> groupsById = {};

  StandardMessagesCategoryView(String this._categoryId, this._categoryName, DivElement header, DivElement body) : super(_categoryId, header, body, false) {
    _categoryName = _categoryName ?? '';

    editableTitle = TextEdit(_categoryName, removable: true)
      ..testInput = (String value) {
        var messageManager = (_view.appController as MessagesConfiguratorController).standardMessagesManager;
        var categories = messageManager.standardMessagesInLocal.map((e) => e.category).toSet();
        categories.remove(id);
        return !categories.contains(value);
      }
      ..onEdit = (value) {
        _view.appController.command(MessagesConfigAction.updateStandardMessagesCategory, new StandardMessagesCategoryData(_categoryId, newCategoryName: value));
        _categoryName = value;
      }
      ..onDelete = () {
        requestToDelete();
      };
    _alternativeElement = DivElement()..className = "category-alternative"..hidden = true;
    header
      ..append(editableTitle.renderElement)
      ..append(_alternativeElement);

    _standardMessagesGroupContainer = new DivElement()..classes.add('standard-messages__group');
    body.append(_standardMessagesGroupContainer);

    groups = new Accordion([]);
    _standardMessagesGroupContainer.append(groups.renderElement);

    _addButton = Button(ButtonType.add, 
      hoverText: 'Add a new group of standard messages', 
      onClick: (event) => _view.appController.command(MessagesConfigAction.addStandardMessagesGroup, new StandardMessagesGroupData(_categoryId, null)));

    body.append(_addButton.renderElement);
  }

  void set name(String value) => _categoryName = value;
  String get name => _categoryName;

  void updateName(String newCategoryName) {
    if (_categoryName.compareTo(newCategoryName) != 0) {
      editableTitle.updateText(newCategoryName);
    }
  }

  void showAlternative(String categoryName) {
    _alternativeElement.children.clear();
    var instructions = SpanElement()..className = "category-alternative__instruction"..innerText = "Someone else has just renamed this category to:";
    var altText = SpanElement()..innerText = categoryName;
    var acceptButton = Button(ButtonType.confirm, onClick: (_) {
      editableTitle.updateText(categoryName);
      _view.appController.command(MessagesConfigAction.updateStandardMessagesCategory, new StandardMessagesCategoryData(_categoryId, newCategoryName: categoryName));
    });
    var discardButton = Button(ButtonType.cancel, onClick: (_) => _alternativeElement..hidden = true);
    var actions = SpanElement()..append(acceptButton.renderElement)..append(discardButton.renderElement);
    _alternativeElement
      ..hidden = false
      ..append(instructions)
      ..append(altText)
      ..append(actions);
  }

  void hideAlternative() {
    _alternativeElement
      ..children.clear()
      ..hidden = true;
  }

  void addGroup(String groupId, StandardMessagesGroupView standardMessagesGroupView, [int index]) {
    // todo: test for multiple groups added from firebase at the same time after adding a group by
    if (index == null || groups.items.length <= index) {
      groups.appendItem(standardMessagesGroupView);
    } else {
      groups.insertItem(standardMessagesGroupView, index);
    }
    groupsById[groupId] = standardMessagesGroupView;
  }

  void renameGroup(String groupId, String newGroupName) {
    var groupView = groupsById[groupId];
    groupView._groupName = newGroupName;
    groupsById[groupId] = groupView;
    groups.updateItem(groupId, groupView);
  }

  void removeGroup(String groupName) {
    groupsById[groupName].renderElement.remove();
    groupsById.remove(groupName);
  }

  void requestToDelete() {
    expand();
    var standardMessagesCategoryData = new StandardMessagesCategoryData(_categoryId);
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
  String _groupId;
  String _groupName;
  DivElement _standardMessagesContainer;
  Button _addButton;
  TextEdit editableTitle;
  Element _alternativeElement;

  Map<String, StandardMessageView> messagesById = {};

  StandardMessagesGroupView(this._categoryId, this._groupId, this._groupName, DivElement header, DivElement body) : super(_groupId, header, body, false) {
    editableTitle = TextEdit(_groupName, removable: true)
      ..testInput = (String value) {
        var messageManager = (_view.appController as MessagesConfiguratorController).standardMessagesManager;
        var groups = messageManager.standardMessagesInLocal.map((e) => e.group_description).toSet();
        groups.remove(id);
        return !groups.contains(value);
      }
      ..onEdit = (value) {
        _view.appController.command(MessagesConfigAction.updateStandardMessagesGroup, new StandardMessagesGroupData(_categoryId, _groupId, newGroupName: value));
      }
      ..onDelete = () {
        requestToDelete();
      };
    _alternativeElement = DivElement()..className = "group-alternative"..hidden = true;
    header
      ..append(editableTitle.renderElement)
      ..append(_alternativeElement);

    _standardMessagesContainer = DivElement();
    body.append(_standardMessagesContainer);

    _addButton = Button(ButtonType.add);
    _addButton.renderElement.onClick.listen((e) {
      _view.appController.command(MessagesConfigAction.addStandardMessage, new StandardMessageData(null, groupId: _groupId, categoryId: _categoryId));
    });

    body.append(_addButton.renderElement);
  }

  void showAlternative(String groupName) {
    _alternativeElement.children.clear();
    var instructions = SpanElement()..className = "group-alternative__instruction"..innerText = "Someone else has just renamed this group to:";
    var altText = SpanElement()..innerText = groupName;
    var acceptButton = Button(ButtonType.confirm, onClick: (_) {
      editableTitle.updateText(groupName);
      _view.appController.command(MessagesConfigAction.updateStandardMessagesGroup, new StandardMessagesGroupData(_categoryId, _groupId, newGroupName: groupName));
    });
    var discardButton = Button(ButtonType.cancel, onClick: (_) => _alternativeElement..hidden = true);
    var actions = SpanElement()..append(acceptButton.renderElement)..append(discardButton.renderElement);
    _alternativeElement
      ..hidden = false
      ..append(instructions)
      ..append(altText)
      ..append(actions);
  }

  void hideAlternative() {
    _alternativeElement
      ..children.clear()
      ..hidden = true;
  }

  void addMessage(String messageId, StandardMessageView standardMessageView) {
    _standardMessagesContainer.append(standardMessageView.renderElement);
    messagesById[messageId] = standardMessageView;
  }

  void modifyMessage(String messageId, StandardMessageView standardMessageView) {
    messagesById[messageId] = standardMessageView;
  }

  void updateName(String newGroupName) {
    if (_groupName.compareTo(newGroupName) != 0) {
      editableTitle.updateText(newGroupName);
    }
  }

  void removeMessage(String messageId) {
    messagesById[messageId].renderElement.remove();
    messagesById.remove(messageId);
  }

  void requestToDelete() {
    expand();
    var standardMessagesGroupData = new StandardMessagesGroupData(_categoryId, _groupId);
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

  // todo: add a message to reflect group name change
}

class StandardMessageView {
  Element _standardMessageElement;
  MessageView _textView;
  MessageView _translationView;

  StandardMessageView(String messageId, String text, String translation) {
    _standardMessageElement = new DivElement()
      ..classes.add('standard-message')
      ..dataset['id'] = '$messageId';

    _textView = new MessageView(text, (text) => _view.appController.command(MessagesConfigAction.updateStandardMessage, new StandardMessageData(messageId, text: text)));
    _translationView = new MessageView(translation, (translation) => _view.appController.command(MessagesConfigAction.updateStandardMessage, new StandardMessageData(messageId, translation: translation)), placeholder: '(optional) Translate the message in a secondary language here');
    _standardMessageElement
      ..append(_textView.renderElement)
      ..append(_translationView.renderElement);
    _makeStandardMessageViewTextareasSynchronisable([_textView, _translationView]);

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

  void markTextAsUnsaved(bool unsaved) {
    _textView.markAsUnsaved(unsaved);
  }

  void markTranslationAsUnsaved(bool unsaved) {
    _translationView.markAsUnsaved(unsaved);
  }

  void updateText(String text) {
    _textView.updateText(text);
  }

  void updateTranslation(String text) {
    _translationView.updateText(text);
  }

  void showAlternativeText(String text) {
    _textView.showAlternative(text);
  }

  void showAlternativeTranslation(String translation) {
    _translationView.showAlternative(translation);
  }

  void hideAlternativeText() {
    _textView.hideAlternative();
  }

  void hideAlternativeTranslation() {
    _translationView.hideAlternative();
  }
}

class MessageView {
  Element _messageElement;
  Element _messageWrapper;
  TextAreaElement _messageText;
  Function onMessageUpdateCallback;
  Function _onTextareaHeightChangeCallback;
  SpanElement _textLengthIndicator;

  DivElement _alternativeElement;

  MessageView(String message, this.onMessageUpdateCallback, {String placeholder = ''}) {
    _messageElement = new DivElement()..classes.add('message');
    _messageWrapper = new DivElement()..classes.add('message-wrapper');
    _alternativeElement = new DivElement()..classes.add('message-alternative')..hidden = true;

    _textLengthIndicator = new SpanElement()
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
        _textLengthIndicator.text = '${count}/${_view.appController.MESSAGE_MAX_LENGTH}';
        _messageText.classes.toggle('message__text--alert', count > _view.appController.MESSAGE_MAX_LENGTH);
        _textLengthIndicator.classes.toggle('message__length-indicator--alert', count > _view.appController.MESSAGE_MAX_LENGTH);
        _handleTextareaHeightChange();
      });
    
    _messageWrapper..append(_messageText)..append(_textLengthIndicator);
    _messageElement..append(_messageWrapper)..append(_alternativeElement);
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

  void markAsUnsaved(bool unsaved) {
    _messageWrapper.classes.toggle('unsaved', unsaved);
  }

  void updateText(String text) {
    _messageText.value = text;

    int count = _messageText.value.split('').length;
    _textLengthIndicator.text = '${count}/${_view.appController.MESSAGE_MAX_LENGTH}';
    _messageText.classes.toggle('message__text--alert', count > _view.appController.MESSAGE_MAX_LENGTH);
    _textLengthIndicator.classes.toggle('message__length-indicator--alert', count > _view.appController.MESSAGE_MAX_LENGTH);
    _handleTextareaHeightChange();
  }

  void showAlternative(String text) {
    _alternativeElement.children.clear();
    var instructions = DivElement()..className = "message-alternative__instruction"..innerText = "This text has been updated in the storage to:";
    var altText = DivElement()..innerText = text;
    var acceptButton = Button(ButtonType.confirm, onClick: (_) => onMessageUpdateCallback(text));
    var discardButton = Button(ButtonType.cancel, onClick: (_) => _alternativeElement..hidden = true);
    var actions = DivElement()..append(acceptButton.renderElement)..append(discardButton.renderElement);
    _alternativeElement
      ..hidden = false
      ..append(instructions)
      ..append(altText)
      ..append(actions);
  }

  void hideAlternative() {
    _alternativeElement
      ..children.clear()
      ..hidden = true;
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
