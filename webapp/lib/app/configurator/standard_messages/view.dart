library view;

import 'dart:async';
import 'dart:html';
import 'package:katikati_ui_lib/components/accordion/accordion.dart';
import 'package:katikati_ui_lib/components/editable/editable_text.dart';
import 'package:nook/app/configurator/view.dart';
export 'package:nook/app/configurator/view.dart';

import 'controller.dart';
import 'package:katikati_ui_lib/components/logger.dart';

Logger log = new Logger('view.dart');

MessagesConfigurationPageView _view;

class MessagesConfigurationPageView extends ConfigurationPageView {
  SelectElement _categories;
  Accordion groups;

  MessagesConfigurationPageView(MessagesConfiguratorController controller) : super(controller) {
    _view = this;
    configurationTitle.text = "What do you want to say?";
    _categories = new SelectElement()
      ..onChange.listen((_) => controller.command(MessagesConfigAction.changeStandardMessagesCategory, new StandardMessagesCategoryData(_categories.value)));
    configurationContent.append(_categories);

    groups = new Accordion([]);
    configurationContent.append(groups.renderElement);

    var addButton = new Button(ButtonType.add,
        hoverText: 'Add a new group of standard messages', onClick: (event) => controller.command(MessagesConfigAction.addStandardMessagesGroup));
    addButton.parent = configurationContent;
  }

  void addItem(AccordionItem item) {
    groups.appendItem(item);
  }

  void removeItem(String id) {
    groups.removeItem(id);
  }

  set selectedCategory(String category) {
    int index = _categories.children.indexWhere((Element option) => (option as OptionElement).value == category);
    if (index == -1) {
      // Couldn't find category in list of standard messages category, using first
      _categories.selectedIndex = 0;
      _view.appController.command(MessagesConfigAction.changeStandardMessagesCategory, new StandardMessagesCategoryData(_categories.value));
      return;
    }
    _categories.selectedIndex = index;
  }

  set categories(List<String> categories) {
    _categories.children.clear();
    for (var category in categories) {
      _categories.append(new OptionElement()
        ..value = category
        ..text = category.isEmpty ? '[Unnamed]' : category);
    }
  }

  void clear() {
    groups.clear();
  }
}

class StandardMessagesGroupView extends AccordionItem {
  String id;
  String _title;
  DivElement _header;
  DivElement _body;
  DivElement _standardMessagesContainer;
  Button _addButton;

  Map<String, StandardMessageView> messagesById = {};

  StandardMessagesGroupView(this.id, this._title, this._header, this._body) : super(id, _header, _body, false) {
    var editableTitle = TextEdit(_title, removable: true)
      ..onEdit = (value) {
        _view.appController.command(MessagesConfigAction.updateStandardMessagesGroup, new StandardMessagesGroupData(id, newGroupName: value));
      }
      ..onDelete = () {
        requestToDelete();
      };
    _header.append(editableTitle.renderElement);

    _standardMessagesContainer = DivElement();
    _body.append(_standardMessagesContainer);

    _addButton = Button(ButtonType.add);
    _addButton.renderElement.onClick.listen((e) {
      _view.appController.command(MessagesConfigAction.addStandardMessage, new StandardMessageData('', groupId: id));
    });
    
    _body.append(_addButton.renderElement);
  }

  void addMessage(String id, StandardMessageView standardMessageView) {
    _standardMessagesContainer.append(standardMessageView.renderElement);
    messagesById[id] = standardMessageView;
  }

  void removeMessage(String id) {
    messagesById[id].renderElement.remove();
    messagesById.remove(id);
  }

  void requestToDelete() {
    expand();
    var standardMessagesGroupData = new StandardMessagesGroupData(id);
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
