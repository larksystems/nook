import 'dart:html';

import 'dom_utils.dart';
import 'logger.dart';
import 'viewmodel.dart';


Logger log = new Logger('view.dart');

ConversationListPanelView conversationListPanelView;
ConversationPanelView conversationPanelView;
ReplyPanelView replyPanelView;
TagPanelView tagPanelView;

init() {
  conversationListPanelView = new ConversationListPanelView();
  conversationPanelView = new ConversationPanelView();
  replyPanelView = new ReplyPanelView();
  tagPanelView = new TagPanelView();

  querySelector('main')
    ..append(conversationListPanelView.conversationListPanel)
    ..append(conversationPanelView.conversationPanel)
    ..append(replyPanelView.replyPanel)
    ..append(tagPanelView.tagPanel);
}

const REPLY_PANEL_TITLE = 'Suggested responses';
const TAG_PANEL_TITLE = 'Available tags';
const ADD_REPLY_INFO = 'Add new suggested response';
const ADD_TAG_INFO = 'Add new tag';

class ConversationPanelView {
  // HTML elements
  DivElement conversationPanel;
  DivElement _messages;
  DivElement _deidentifiedPhoneNumber;
  DivElement _info;
  DivElement _tags;

  ConversationPanelView() {
    conversationPanel = new DivElement();
    conversationPanel.classes.add('message-panel');

    var conversationSummary = new DivElement()
      ..classes.add('message-summary');
    conversationPanel.append(conversationSummary);

    _deidentifiedPhoneNumber = new DivElement()
      ..classes.add('message-summary__id');
    conversationSummary.append(_deidentifiedPhoneNumber);

    _info = new DivElement()
      ..classes.add('message-summary__demographics');
    conversationSummary.append(_info);

    _tags = new DivElement()
      ..classes.add('message-summary__tags');
    conversationSummary.append(_tags);

    _messages = new DivElement()
      ..classes.add('messages');
    conversationPanel.append(_messages);
  }

  set deidentifiedPhoneNumber(String deidentifiedPhoneNumber) => _deidentifiedPhoneNumber.text = deidentifiedPhoneNumber;
  set demographicsInfo(String demographicsInfo) => _info.text = demographicsInfo;

  addMessage(MessageView message) {
    _messages.append(message.message);
  }

  addTags(LabelView label) {
    _tags.append(label.label);
  }

  clear() {
    _deidentifiedPhoneNumber.text = '';
    _info.text = '';

    while (_tags.firstChild != null) {
      _tags.firstChild.remove();
    }
    while (_messages.firstChild != null) {
      _messages.firstChild.remove();
    }
  }
}

class MessageView {
  DivElement message;
  DivElement _messageContent;
  DivElement _messageLabels;
  DivElement _messageText;
  DivElement _messageTranslation;

  MessageView(String content, String messageId, {String translation = '', bool incoming = true, List<LabelView> labels = const[]}) {
    message = new DivElement()
      ..classes.add('message')
      ..classes.add(incoming ? 'message--incoming' : 'message--outgoing')
      ..dataset['id'] = messageId;

    _messageContent = new DivElement()
      ..classes.add('message__content');
    message.append(_messageContent);

    _messageText = new DivElement()
      ..classes.add('message__text')
      ..text = content;
    _messageContent.append(_messageText);

    _messageTranslation = new DivElement()
      ..classes.add('message__translation')
      ..contentEditable = 'true'
      ..text = translation
      ..onInput.listen((_) => command(UIAction.updateTranslation, new TranslationData(_messageTranslation.text, messageId)));
    _messageContent.append(_messageTranslation);

    _messageLabels = new DivElement()
      ..classes.add('message__labels');
    labels.forEach((label) => _messageLabels.append(label.label));
    message.append(_messageLabels);

  }

  set translation(String translation) => _messageTranslation.text = translation;

  void addLabel(LabelView label, [int position]) {
    if (position == null || position >= _messageLabels.children.length) {
      // Add at the end
      _messageLabels.append(label.label);
      return;
    }
    // Add before an existing label
    if (position < 0) {
      position = 0;
    }
    Node refChild = _messageLabels.children[position];
    _messageLabels.insertBefore(label.label, refChild);
  }
}

enum TagColour {
  None,
  Green,
  Yellow,
  Red
}

class LabelView {
  DivElement label;

  LabelView(String text, String labelId, [TagColour tagColour = TagColour.None]) {
    label = new DivElement()
      ..classes.add('label')
      ..dataset['id'] = labelId;
    switch (tagColour) {
      case TagColour.Green:
        label.classes.add('label--green');
        break;
      case TagColour.Yellow:
        label.classes.add('label--yellow');
        break;
      case TagColour.Red:
        label.classes.add('label--red');
        break;
      default:
    }

    var labelText = new SpanElement()
      ..classes.add('label__name')
      ..text = text;
    label.append(labelText);

    var removeButton = new SpanElement()
      ..classes.add('label__remove')
      ..onClick.listen((_) {
        DivElement message = getAncestors(label).firstWhere((e) => e.classes.contains('message'));
        command(UIAction.removeLabel, new LabelData(labelId, message.dataset['id']));
      });
    label.append(removeButton);
  }
}

class ConversationListPanelView {
  DivElement conversationListPanel;

  Map<String, ConversationSummary> _phoneToConversations = {};
  ConversationSummary activeConversation;

  ConversationListPanelView() {
    conversationListPanel = new DivElement();
    conversationListPanel.classes.add('message-list');
  }

  void addConversation(ConversationSummary conversationSummary, [int position]) {
    if (position == null || position >= conversationListPanel.children.length) {
      // Add at the end
      conversationListPanel.append(conversationSummary.conversationSummary);
      _phoneToConversations[conversationSummary.deidentifiedPhoneNumber] = conversationSummary;
      return;
    }
    // Add before an existing label
    if (position < 0) {
      position = 0;
    }
    Node refChild = conversationListPanel.children[position];
    conversationListPanel.insertBefore(conversationSummary.conversationSummary, refChild);
    _phoneToConversations[conversationSummary.deidentifiedPhoneNumber] = conversationSummary;
  }

  selectConversation(String deidentifiedPhoneNumber) {
    activeConversation?._deselect();
    activeConversation = _phoneToConversations[deidentifiedPhoneNumber];
    activeConversation._select();
  }
}

class ConversationSummary {
  DivElement conversationSummary;

  String deidentifiedPhoneNumber;

  ConversationSummary(this.deidentifiedPhoneNumber, String content) {
    conversationSummary = new DivElement()
      ..classes.add('summary-message')
      ..dataset['id'] = deidentifiedPhoneNumber
      ..text = content
      ..onClick.listen((_) => command(UIAction.selectConversation, new ConversationData(deidentifiedPhoneNumber)));
  }

  set content(String text) => conversationSummary.text = text;

  void _deselect() => conversationSummary.classes.remove('summary-message--selected');
  void _select() => conversationSummary.classes.add('summary-message--selected');
}

class ReplyPanelView {
  DivElement replyPanel;
  DivElement _replies;
  DivElement _replyList;
  DivElement _notes;

  AddAction _addReply;

  ReplyPanelView() {
    replyPanel = new DivElement()
      ..classes.add('reply-panel');

    var panelTitle = new DivElement()
      ..classes.add('panel-title')
      ..text = REPLY_PANEL_TITLE;
    replyPanel.append(panelTitle);

    _replies = new DivElement()
      ..classes.add('replies')
      ..classes.add('action-list');
    replyPanel.append(_replies);

    _replyList = new DivElement();
    _replies.append(_replyList);

    _addReply = new AddAction(ADD_REPLY_INFO);
    _replies.append(_addReply.addAction);

    _notes = new DivElement()
      ..classes.add('notes-box')
      ..append(new DivElement()
          ..classes.add('notes-box__textarea')
          ..contentEditable = 'true');
    replyPanel.append(_notes);
  }

  addReply(ActionView action) {
    _replyList.append(action.action);
  }
}

class TagPanelView {
  DivElement tagPanel;
  DivElement _tags;
  DivElement _tagList;

  AddAction _addTag;

  TagPanelView() {
    tagPanel = new DivElement()
      ..classes.add('tag-panel');

    var panelTitle = new DivElement()
      ..classes.add('panel-title')
      ..text = TAG_PANEL_TITLE;
    tagPanel.append(panelTitle);

    _tags = new DivElement()
      ..classes.add('tags')
      ..classes.add('action-list');
    tagPanel.append(_tags);

    _tagList = new DivElement();
    _tags.append(_tagList);

    _addTag = new AddAction(ADD_TAG_INFO);
    _tags.append(_addTag.addAction);
  }

  addTag(ActionView action) {
    _tagList.append(action.action);
  }
}

class ActionView {
  DivElement action;

  ActionView(String text, String shortcut, String buttonText) {
    action = new DivElement()
      ..classes.add('action');

    var shortcutElement = new DivElement()
      ..classes.add('action__shortcut')
      ..text = shortcut;
    action.append(shortcutElement);

    var textElement = new DivElement()
      ..classes.add('action__text')
      ..text = text;
    action.append(textElement);

    var buttonElement = new DivElement()
      ..classes.add('action__button')
      ..text = buttonText;
    action.append(buttonElement);
  }
}

class AddAction {
  DivElement addAction;

  AddAction(String infoText) {
    addAction = new DivElement()
      ..classes.add('add-action');

    var info = new DivElement()
      ..classes.add('add-action__info')
      ..text = infoText;
    addAction.append(info);

    // TODO(mariana): fill in functionality for adding new action
  }
}
