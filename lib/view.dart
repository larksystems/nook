import 'dart:html';

import 'dom_utils.dart';
import 'logger.dart';
import 'viewmodel.dart';


Logger log = new Logger('view.dart');

ConversationListPanelView conversationListPanelView;
ConversationPanelView conversationPanelView;
ReplyPanelView replyPanelView;
TagPanelView tagPanelView;

void init() {
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

  List<MessageView> _messageViews = [];

  ConversationPanelView() {
    conversationPanel = new DivElement()
      ..classes.add('message-panel')
      ..onClick.listen((_) => command(UIAction.deselectMessage, null));

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

  void addMessage(MessageView message) {
    _messages.append(message.message);
    _messageViews.add(message);
  }

  void addTags(TagView tag) {
    _tags.append(tag.tag);
  }

  void selectMessage(int index) {
    _messageViews[index]._select();
  }

  void deselectMessage() {
    MessageView._deselect();
  }

  MessageView messageViewAtIndex(int index) {
    return _messageViews[index];
  }

  void clear() {
    _deidentifiedPhoneNumber.text = '';
    _info.text = '';
    _messageViews = [];

    int tagsNo = _tags.children.length;
    for (int i = 0; i < tagsNo; i++) {
      _tags.firstChild.remove();
    }

    int messagesNo = _messages.children.length;
    for (int i = 0; i < messagesNo; i++) {
      _messages.firstChild.remove();
    }
  }
}

class MessageView {
  DivElement message;
  DivElement _messageContent;
  DivElement _messageTags;
  DivElement _messageText;
  DivElement _messageTranslation;

  static MessageView selectedMessageView;

  MessageView(String content, String conversationId, int messageIndex, {String translation = '', bool incoming = true, List<TagView> tags = const[]}) {
    message = new DivElement()
      ..classes.add('message')
      ..classes.add(incoming ? 'message--incoming' : 'message--outgoing')
      ..dataset['conversationId'] = conversationId
      ..dataset['messageIndex'] = '$messageIndex';

    _messageContent = new DivElement()
      ..classes.add('message__content')
      ..onClick.listen((event) {
        event.preventDefault();
        event.stopPropagation();
        command(UIAction.selectMessage, new MessageData(conversationId, messageIndex));
      });
    message.append(_messageContent);

    _messageText = new DivElement()
      ..classes.add('message__text')
      ..text = content;
    _messageContent.append(_messageText);

    _messageTranslation = new DivElement()
      ..classes.add('message__translation')
      ..contentEditable = 'true'
      ..text = translation
      ..onInput.listen((_) => command(UIAction.updateTranslation, new TranslationData(_messageTranslation.text, conversationId, messageIndex)));
    _messageContent.append(_messageTranslation);

    _messageTags = new DivElement()
      ..classes.add('message__tags');
    tags.forEach((tag) => _messageTags.append(tag.tag));
    message.append(_messageTags);

  }

  set translation(String translation) => _messageTranslation.text = translation;

  void addTag(TagView tag, [int position]) {
    if (position == null || position >= _messageTags.children.length) {
      // Add at the end
      _messageTags.append(tag.tag);
      return;
    }
    // Add before an existing tag
    if (position < 0) {
      position = 0;
    }
    Node refChild = _messageTags.children[position];
    _messageTags.insertBefore(tag.tag, refChild);
  }

  void _select() {
    MessageView._deselect();
    message.classes.add('message--selected');
    selectedMessageView = this;
  }

  static void _deselect() {
    selectedMessageView?.message?.classes?.remove('message--selected');
    selectedMessageView = null;
  }
}

enum TagColour {
  None,
  Green,
  Yellow,
  Red
}

class TagView {
  DivElement tag;

  TagView(String text, String tagId, [TagColour tagColour = TagColour.None]) {
    tag = new DivElement()
      ..classes.add('tag')
      ..dataset['id'] = tagId;
    switch (tagColour) {
      case TagColour.Green:
        tag.classes.add('tag--green');
        break;
      case TagColour.Yellow:
        tag.classes.add('tag--yellow');
        break;
      case TagColour.Red:
        tag.classes.add('tag--red');
        break;
      default:
    }

    var tagText = new SpanElement()
      ..classes.add('tag__name')
      ..text = text;
    tag.append(tagText);

    var removeButton = new SpanElement()
      ..classes.add('tag__remove')
      ..onClick.listen((_) {
        DivElement message = getAncestors(tag).firstWhere((e) => e.classes.contains('message'));
        command(UIAction.removeMessageTag, new MessageTagData(tagId, message.dataset['id']));
      });
    tag.append(removeButton);
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
    // Add before an existing tag
    if (position < 0) {
      position = 0;
    }
    Node refChild = conversationListPanel.children[position];
    conversationListPanel.insertBefore(conversationSummary.conversationSummary, refChild);
    _phoneToConversations[conversationSummary.deidentifiedPhoneNumber] = conversationSummary;
  }

  void selectConversation(String deidentifiedPhoneNumber) {
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

  void addReply(ActionView action) {
    _replyList.append(action.action);
  }

  void clear() {
    int repliesNo = _replyList.children.length;
    for (int i = 0; i < repliesNo; i++) {
      _replyList.firstChild.remove();
    }
    assert(_replyList.children.length == 0);
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

  void addTag(ActionView action) {
    _tagList.append(action.action);
  }

  void clear() {
    int tagsNo = _tagList.children.length;
    for (int i = 0; i < tagsNo; i++) {
      _tagList.firstChild.remove();
    }
    assert(_tagList.children.length == 0);
  }
}

class ActionView {
  DivElement action;

  ActionView(String text, String shortcut, String actionId, String buttonText) {
    action = new DivElement()
      ..classes.add('action')
      ..dataset['id'] = actionId;

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

class ReplyActionView extends ActionView {
  ReplyActionView(String text, String shortcut, int replyIndex, String buttonText) : super(text, shortcut, '$replyIndex', buttonText) {
    var buttonElement = action.querySelector('.action__button');
    buttonElement.onClick.listen((_) => command(UIAction.sendMessage, new ReplyData(replyIndex)));
  }
}

class TagActionView extends ActionView {
  TagActionView(String text, String shortcut, String tagId, String buttonText) : super(text, shortcut, tagId, buttonText) {
    var buttonElement = action.querySelector('.action__button');
    buttonElement.onClick.listen((_) => command(UIAction.addTag, new TagData(action.dataset['id'])));
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
