import 'dart:html';

import 'package:intl/intl.dart';

import 'dom_utils.dart';
import 'logger.dart';
import 'controller.dart';


Logger log = new Logger('view.dart');

ConversationListPanelView conversationListPanelView;
ConversationFilter get conversationFilter => conversationListPanelView.conversationFilter;
ConversationPanelView conversationPanelView;
ReplyPanelView replyPanelView;
TagPanelView tagPanelView;
AuthHeaderView authHeaderView;
AuthMainView authMainView;
UrlView urlView;

void init() {
  conversationListPanelView = new ConversationListPanelView();
  conversationPanelView = new ConversationPanelView();
  replyPanelView = new ReplyPanelView();
  tagPanelView = new TagPanelView();
  authHeaderView = new AuthHeaderView();
  authMainView = new AuthMainView();
  urlView = new UrlView();

  querySelector('header')
    ..append(authHeaderView.authElement);

  document.onKeyPress.listen((event) => command(UIAction.keyPressed, new KeyPressData(event.key)));
}

void initSignedInView() {
  clearMain();

  querySelector('main')
    ..append(conversationListPanelView.conversationListPanel)
    ..append(conversationPanelView.conversationPanel)
    ..append(replyPanelView.replyPanel)
    ..append(tagPanelView.tagPanel);
  showNormalStatus('signed in');
}

void initSignedOutView() {
  clearMain();

  querySelector('main')
    ..append(authMainView.authElement);
  showNormalStatus('signed out');
}

void clearMain() {
  conversationListPanelView.conversationListPanel.remove();
  conversationPanelView.conversationPanel.remove();
  replyPanelView.replyPanel.remove();
  tagPanelView.tagPanel.remove();
  authMainView.authElement.remove();
}

bool sendingMultiMessagesUserConfirmation(int noMessages) {
  return window.confirm('Are you sure you want to send $noMessages SMS message${noMessages == 1 ? "" : "s" }?');
}

bool taggingMultiConversationsUserConfirmation(int noConversations) {
  return window.confirm('Are you sure you want to tag $noConversations conversation${noConversations == 1 ? "" : "s" }?');
}

void showNormalStatus(String text) {
  tagPanelView._statusText.text = text;
  tagPanelView._statusPanel.classes.remove('status-line-warning');
}

void showWarningStatus(String text) {
  tagPanelView._statusText.text = text;
  tagPanelView._statusPanel.classes.add('status-line-warning');
}

const REPLY_PANEL_TITLE = 'Suggested responses';
const TAG_PANEL_TITLE = 'Available tags';
const ADD_REPLY_INFO = 'Add new suggested response';
const ADD_TAG_INFO = 'Add new tag';

class ConversationPanelView {
  // HTML elements
  DivElement conversationPanel;
  DivElement _messages;
  DivElement _conversationId;
  DivElement _conversationIdCopy;
  DivElement _info;
  DivElement _tags;

  List<MessageView> _messageViews = [];

  ConversationPanelView() {
    conversationPanel = new DivElement()
      ..classes.add('conversation-panel')
      ..onClick.listen((_) => command(UIAction.deselectMessage, null));

    var conversationSummary = new DivElement()
      ..classes.add('conversation-summary');
    conversationPanel.append(conversationSummary);

    var title = new DivElement()
      ..classes.add('conversation-summary__title');
    conversationSummary.append(title);

    _conversationId = new DivElement()
      ..classes.add('conversation-summary__id');
    title.append(_conversationId);

    _conversationIdCopy = new DivElement()
      ..classes.add('conversation-summary__id-copy')
      ..title = 'Copy full conversation id'
      ..onClick.listen((_) => window.navigator.clipboard.writeText(_conversationIdCopy.dataset['copy-value']));
    title.append(_conversationIdCopy);

    _info = new DivElement()
      ..classes.add('conversation-summary__demographics');
    conversationSummary.append(_info);

    _tags = new DivElement()
      ..classes.add('conversation-summary__tags');
    conversationSummary.append(_tags);

    _messages = new DivElement()
      ..classes.add('messages');
    conversationPanel.append(_messages);
  }

  set deidentifiedPhoneNumber(String deidentifiedPhoneNumber) => _conversationIdCopy.dataset['copy-value'] = deidentifiedPhoneNumber;
  set deidentifiedPhoneNumberShort(String deidentifiedPhoneNumberShort) => _conversationId.text = deidentifiedPhoneNumberShort;
  set demographicsInfo(String demographicsInfo) => _info.text = demographicsInfo;

  void addMessage(MessageView message) {
    _messages.append(message.message);
    _messageViews.add(message);
    message.message.scrollIntoView();
  }

  void addTags(TagView tag) {
    _tags.append(tag.tag);
  }

  void removeTag(String tagId) {
    _tags.children.removeWhere((Element d) => d.dataset["id"] == tagId);
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
    _conversationId.text = '';
    _conversationIdCopy.dataset['copy-value'] = '';
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
  DivElement _messageBubble;
  DivElement _messageDateTime;
  DivElement _messageText;
  DivElement _messageTranslation;
  DivElement _messageTags;

  static MessageView selectedMessageView;

  MessageView(String text, DateTime dateTime, String conversationId, int messageIndex, {String translation = '', bool incoming = true, List<TagView> tags = const[]}) {
    message = new DivElement()
      ..classes.add('message')
      ..classes.add(incoming ? 'message--incoming' : 'message--outgoing')
      ..dataset['conversationId'] = conversationId
      ..dataset['messageIndex'] = '$messageIndex';

    _messageBubble = new DivElement()
      ..classes.add('message__bubble')
      ..onClick.listen((event) {
        event.preventDefault();
        event.stopPropagation();
        command(UIAction.selectMessage, new MessageData(conversationId, messageIndex));
      });
    message.append(_messageBubble);

    _messageDateTime = new DivElement()
      ..classes.add('message__datetime')
      ..text = _formatDateTime(dateTime);
    _messageBubble.append(_messageDateTime);

    _messageText = new DivElement()
      ..classes.add('message__text')
      ..text = text;
    _messageBubble.append(_messageText);

    _messageTranslation = new DivElement()
      ..classes.add('message__translation')
      ..contentEditable = 'true'
      ..text = translation
      ..onInput.listen((_) => command(UIAction.updateTranslation, new TranslationData(_messageTranslation.text, conversationId, messageIndex)))
      ..onKeyPress.listen((e) => e.stopPropagation());
    _messageBubble.append(_messageTranslation);

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

  void removeTag(String tagId) {
    _messageTags.children.removeWhere((e) => e.dataset["id"] == tagId);
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

final DateFormat _dateFormat = new DateFormat('E d MMM y');
final DateFormat _dateFormatNoYear = new DateFormat('E d MMM');
final DateFormat _hourFormat = new DateFormat('H:m');

String _formatDateTime(DateTime dateTime) {
  DateTime now = DateTime.now();
  DateTime localDateTime = dateTime.toLocal();

  if (_dateFormat.format(now) == _dateFormat.format(localDateTime)) {
    // localDateTime is today, return only time
    return _hourFormat.format(localDateTime);
  }
  if (_dateFormat.format(now.subtract(new Duration(days: 1))) == _dateFormat.format(localDateTime)) {
    // localDateTime is yesterday, return yesterday and the time
    return 'Yesterday, ${_hourFormat.format(localDateTime)}';
  }
  if (now.year == localDateTime.year) {
    // localDateTime is this year, return date without year and the time
    return '${_dateFormatNoYear.format(localDateTime)}, ${_hourFormat.format(localDateTime)}';
  }
  return '${_dateFormat.format(localDateTime)}, ${_hourFormat.format(localDateTime)}';
}

enum TagStyle {
  None,
  Green,
  Yellow,
  Red,
  Important,
}

abstract class TagView {
  DivElement tag;
  SpanElement _tagText;
  SpanElement _removeButton;

  TagView(String text, String tagId, TagStyle tagStyle) {
    tag = new DivElement()
      ..classes.add('tag')
      ..dataset['id'] = tagId;
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

    _tagText = new SpanElement()
      ..classes.add('tag__name')
      ..text = text;
    tag.append(_tagText);

    _removeButton = new SpanElement()
      ..classes.add('tag__remove');
    tag.append(_removeButton);
  }
}

class MessageTagView extends TagView {
  MessageTagView(String text, String tagId, TagStyle tagStyle) : super(text, tagId, tagStyle) {
    _removeButton.onClick.listen((_) {
      DivElement message = getAncestors(tag).firstWhere((e) => e.classes.contains('message'), orElse: () => null);
      command(UIAction.removeMessageTag, new MessageTagData(tagId, int.parse(message.dataset['message-index'])));
    });
  }
}

class ConversationTagView extends TagView {
  ConversationTagView(String text, String tagId, TagStyle tagStyle) : super(text, tagId, tagStyle) {
    _removeButton.onClick.listen((_) {
      DivElement messageSummary = getAncestors(tag).firstWhere((e) => e.classes.contains('conversation-summary'));
      command(UIAction.removeConversationTag, new ConversationTagData(tagId, messageSummary.dataset['id']));
    });
  }
}

class FilterMenuTagView extends TagView {
  FilterMenuTagView(String text, String tagId, TagStyle tagStyle) : super(text, tagId, tagStyle) {
    _removeButton.remove();
    tag.onClick.listen((_) {
      command(UIAction.addFilterTag, new FilterTagData(tagId));
    });
  }
}

class FilterTagView extends TagView {
  FilterTagView(String text, String tagId, TagStyle tagStyle) : super(text, tagId, tagStyle) {
    _removeButton..onClick.listen((_) {
      command(UIAction.removeFilterTag, new FilterTagData(tagId));
    });
  }
}

class ConversationListPanelView {
  DivElement conversationListPanel;
  DivElement _conversationPanelTitle;
  _ConversationListViewModel _conversationList;
  CheckboxInputElement _selectAllCheckbox;
  DivElement _loadSpinner;

  ConversationFilter conversationFilter;

  Map<String, ConversationSummary> _phoneToConversations = {};
  ConversationSummary activeConversation;

  ConversationListPanelView() {
    conversationListPanel = new DivElement()
      ..classes.add('conversation-list-panel');

    var panelHeader = new DivElement()
      ..classes.add('conversation-list-header');
    conversationListPanel.append(panelHeader);

    _selectAllCheckbox = new CheckboxInputElement()
      ..classes.add('conversation-list-header__checkbox')
      ..title = 'Select all conversations'
      ..checked = false
      ..onClick.listen((_) => _selectAllCheckbox.checked ? command(UIAction.enableMultiSelectMode, null) : command(UIAction.disableMultiSelectMode, null));
    panelHeader.append(_selectAllCheckbox);

    _conversationPanelTitle = new DivElement()
      ..classes.add('panel-title')
      ..classes.add('conversation-list-header__title')
      ..text = '0 conversations';
    panelHeader.append(_conversationPanelTitle);

    _loadSpinner = new DivElement()
      ..classes.add('load-spinner');
    conversationListPanel.append(_loadSpinner);

    _conversationList = new _ConversationListViewModel();
    conversationListPanel.append(_conversationList._conversationList);

    conversationFilter = new ConversationFilter();
    conversationListPanel.append(conversationFilter.conversationFilter);
  }

  void addConversation(ConversationSummary conversationSummary, [int position]) {
    _conversationList.addConversation(conversationSummary, position);
    _phoneToConversations[conversationSummary.deidentifiedPhoneNumber] = conversationSummary;
    _conversationPanelTitle.text = '${_phoneToConversations.length} conversations';
  }

  void selectConversation(String deidentifiedPhoneNumber) {
    activeConversation?._deselect();
    activeConversation = _phoneToConversations[deidentifiedPhoneNumber];
    activeConversation._select();
    _conversationList.selectConversation(activeConversation);
  }

  void clearConversationList() {
    _conversationList.clearConversations();
    _phoneToConversations.clear();
    _conversationPanelTitle.text = '${_phoneToConversations.length} conversations';
  }

  void checkConversation(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]._check();
  }

  void uncheckConversation(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]._uncheck();
  }

  void checkAllConversations() => _phoneToConversations.forEach((_, conversation) => conversation._check());
  void uncheckAllConversations() => _phoneToConversations.forEach((_, conversation) => conversation._uncheck());
  void showCheckboxes() => _phoneToConversations.forEach((_, conversation) => conversation._showCheckbox());
  void hideCheckboxes() => _phoneToConversations.forEach((_, conversation) => conversation._hideCheckbox());

  void hideLoadSpinner() {
    _loadSpinner.hidden = true;
  }

  void showLoadSpinner() {
    _loadSpinner.hidden = false;
  }
}

class ConversationFilter {
  DivElement conversationFilter;
  DivElement _tagsContainer;
  DivElement _tagsMenu;
  DivElement _tagsMenuContainer;

  ConversationFilter() {
    conversationFilter = new DivElement()
      ..classes.add('conversation-filter');

    var descriptionText = new DivElement()
      ..text = 'Filter conversations ▹';
    conversationFilter.append(descriptionText);

    _tagsMenu = new DivElement()
      ..classes.add('tags-menu');

    _tagsMenuContainer = new DivElement()
      ..classes.add('tags-menu__container');
    _tagsMenu.append(_tagsMenuContainer);

    conversationFilter.append(_tagsMenu);

    _tagsContainer = new DivElement()
      ..classes.add('tags-container');
    conversationFilter.append(_tagsContainer);
  }

  void addMenuTag(FilterMenuTagView tag) {
    _tagsMenuContainer.append(tag.tag);
  }

  void addFilterTag(FilterTagView tag) {
    _tagsContainer.append(tag.tag);
  }

  void removeFilterTag(String tagId) {
    _tagsContainer.children.removeWhere((Element d) => d.dataset["id"] == tagId);
  }

  void clearSelectedTags() {
    int tagsNo = _tagsContainer.children.length;
    for (int i = 0; i < tagsNo; i++) {
      _tagsContainer.firstChild.remove();
    }
    assert(_tagsContainer.children.length == 0);
  }

  void clearMenuTags() {
    int tagsNo = _tagsMenuContainer.children.length;
    for (int i = 0; i < tagsNo; i++) {
      _tagsMenuContainer.firstChild.remove();
    }
    assert(_tagsMenuContainer.children.length == 0);
  }
}

class ConversationSummary {
  DivElement _summaryElement;
  CheckboxInputElement _selectCheckbox;

  String deidentifiedPhoneNumber;
  String _text;
  bool _checked = false;
  bool _selected = false;

  // For debugging, track the number of [ConversationSummary] DOM elements
  static int _conversationSummaryDomCount = 0;

  ConversationSummary(this.deidentifiedPhoneNumber, this._text);

  DivElement get summaryElement => _summaryElement ??= _buildDivElement();

  DivElement _buildDivElement() {
    var conversationSummary = new DivElement()
      ..classes.add('conversation-list__item');

    _selectCheckbox = new CheckboxInputElement()
      ..classes.add('conversation-selector')
      ..title = 'Select conversation'
      ..checked = _checked
      ..style.visibility = 'hidden'
      ..onClick.listen((_) => _selectCheckbox.checked ? command(UIAction.selectConversation, new ConversationData(deidentifiedPhoneNumber))
                                                      : command(UIAction.deselectConversation, new ConversationData(deidentifiedPhoneNumber)));
    conversationSummary.append(_selectCheckbox);

    var summaryMessage = new DivElement()
      ..classes.add('summary-message')
      ..dataset['id'] = deidentifiedPhoneNumber
      ..text = _text
      ..onClick.listen((_) => command(UIAction.showConversation, new ConversationData(deidentifiedPhoneNumber)));
    if (_selected) conversationSummary.classes.add('conversation-list__item--selected');
    conversationSummary.append(summaryMessage);
    _conversationSummaryDomCount++;
    return conversationSummary;
  }

  void disposeSummaryElement() {
    if (_summaryElement != null) {
      _summaryElement.remove();
      _summaryElement = null;
      _conversationSummaryDomCount--;
    }
  }

  void _select() {
    _selected = true;
    if (_summaryElement != null) _summaryElement.classes.add('conversation-list__item--selected');
  }
  void _deselect() {
    _selected = false;
    if (_summaryElement != null) _summaryElement.classes.remove('conversation-list__item--selected');
  }
  void _check() {
    _checked = true;
    if (_selectCheckbox != null) _selectCheckbox.checked = true;
  }
  void _uncheck() {
    _checked = false;
    if (_selectCheckbox != null) _selectCheckbox.checked = false;
  }
  void _showCheckbox() {
    if (_selectCheckbox != null) _selectCheckbox.style.visibility = 'visible';
  }
  void _hideCheckbox() {
    if (_selectCheckbox != null) _selectCheckbox.style.visibility = 'hidden';
  }
}

class ReplyPanelView {
  DivElement replyPanel;
  DivElement _panelTitle;
  DivElement _replies;
  DivElement _replyList;
  DivElement _notes;
  TextAreaElement _notesTextArea;

  AddActionView _addReply;

  ReplyPanelView() {
    replyPanel = new DivElement()
      ..classes.add('reply-panel');

    _panelTitle = new DivElement()
      ..classes.add('panel-title')
      ..text = REPLY_PANEL_TITLE;
    replyPanel.append(_panelTitle);

    _replies = new DivElement()
      ..classes.add('replies')
      ..classes.add('action-list');
    replyPanel.append(_replies);

    _replyList = new DivElement();
    _replies.append(_replyList);

    _addReply = new AddReplyActionView(ADD_REPLY_INFO);
    _replies.append(_addReply.addAction);

    _notes = new DivElement()
      ..classes.add('notes-box');
    replyPanel.append(_notes);

    _notesTextArea = new TextAreaElement()
      ..classes.add('notes-box__textarea')
      ..contentEditable = 'true'
      ..onInput.listen((_) => command(UIAction.updateNote, new NoteData(_notesTextArea.value)))
      ..onKeyPress.listen((e) => e.stopPropagation());
    _notes.append(_notesTextArea);
  }

  set noteText(String text) => _notesTextArea.value = text;

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

  void disableReplies() {
    _replies.remove();
    _panelTitle.text = 'Notes';
    _notes.classes.toggle('notes-box--fullscreen', true);
  }

  void enableReplies() {
    _panelTitle.text = REPLY_PANEL_TITLE;
    replyPanel.insertBefore(_replies, _notes);
    _notes.classes.toggle('notes-box--fullscreen', false);
  }
}

class TagPanelView {
  DivElement tagPanel;
  DivElement _tags;
  DivElement _tagList;
  DivElement _statusPanel;
  Text _statusText;

  AddActionView _addTag;

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

    _addTag = new AddTagActionView(ADD_TAG_INFO);
    _tags.append(_addTag.addAction);

    _statusPanel = new DivElement();
    _statusText = new Text('loading...');
    tagPanel.append(_statusPanel
      ..classes.add('status-line')
      ..append(_statusText));
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
      ..classes.add('action__description')
      ..text = text;
    action.append(textElement);

    var buttonElement = new DivElement()
      ..classes.add('action__button')
      ..text = buttonText;
    action.append(buttonElement);
  }
}

class ReplyActionView extends ActionView {
  ReplyActionView(String text, String translation, String shortcut, int replyIndex, String buttonText) : super(text, shortcut, '$replyIndex', buttonText) {
    var descriptionElement = action.querySelector('.action__description')
      ..text = '';

    var actionText = new DivElement()
      ..classes.add('action__text')
      ..text = text;
    descriptionElement.append(actionText);

    var actionTranslation = new DivElement();
    actionTranslation
      ..classes.add('action__translation')
      ..contentEditable = 'true'
      ..text = translation
      ..onInput.listen((_) => command(UIAction.updateTranslation, new ReplyTranslationData(actionTranslation.text, replyIndex)))
      ..onKeyPress.listen((e) => e.stopPropagation());
    descriptionElement.append(actionTranslation);

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

abstract class AddActionView {
  DivElement addAction;
  DivElement _newActionBox;
  DivElement _newActionTextArea;
  DivElement _newActionTranslationLabel;
  DivElement _newActionTranslation;
  DivElement _newActionButton;

  AddActionView(String infoText) {
    addAction = new DivElement()
      ..classes.add('add-action');

    var button = new DivElement()
      ..classes.add('add-action__button')
      ..text = infoText
      ..onClick.listen((_) {
        addAction.append(_newActionBox);
        _newActionTextArea.focus();

        // Position cursor at the end
        // See https://stackoverflow.com/questions/1125292/how-to-move-cursor-to-end-of-contenteditable-entity/3866442#3866442
        var range = document.createRange()
          ..selectNodeContents(_newActionTextArea)
          ..collapse(false);
        window.getSelection()
          ..removeAllRanges()
          ..addRange(range);

        // Set a listener for hiding the box if the user clicks outside it
        var windowClickStream;
        windowClickStream = window.onMouseDown.listen((e) {
          var addActionBox = getAncestors(e.target).where((ancestor) => ancestor.classes.contains('add-action__box'));
          if (addActionBox.isNotEmpty) return; // click inside the box
          _newActionBox.remove();
          windowClickStream.cancel();
        });
      });
    addAction.append(button);

    _newActionBox = new DivElement()
      ..classes.add('add-action__box');

    _newActionTextArea = new DivElement()
      ..classes.add('add-action__textarea')
      ..contentEditable = 'true'
      ..text = ''
      ..onKeyPress.listen((e) => e.stopPropagation());
    _newActionBox.append(_newActionTextArea);

    _newActionTranslationLabel = new DivElement()
      ..text = 'Translation:'
      ..classes.add('add-action__translation-label');
    _newActionBox.append(_newActionTranslationLabel);

    _newActionTranslation = new DivElement()
      ..classes.add('add-action__translation')
      ..contentEditable = 'true'
      ..onKeyPress.listen((e) => e.stopPropagation());
    _newActionBox.append(_newActionTranslation);

    _newActionButton = new DivElement()
      ..classes.add('add-action__commit-button')
      ..text = 'Submit'
      ..onClick.listen((_) {
        _newActionBox.style.visibility = 'hidden';
        _newActionTextArea.text = '';
        _newActionTranslation.text = '';
      });
    _newActionBox.append(_newActionButton);
  }
}

class AddReplyActionView extends AddActionView {
  AddReplyActionView(String infoText) : super(infoText) {
    _newActionButton.onClick.listen((_) => command(UIAction.addNewSuggestedReply, new AddSuggestedReplyData(_newActionTextArea.text, _newActionTranslation.text)));
  }
}

class AddTagActionView extends AddActionView {
  AddTagActionView(String infoText) : super(infoText) {
    _newActionButton.onClick.listen((_) => command(UIAction.addNewTag, new AddTagData(_newActionTextArea.text)));
    // No translation for tags
    _newActionTranslation.remove();
    _newActionTranslationLabel.remove();
  }
}

class AuthHeaderView {
  DivElement authElement;
  DivElement _userPic;
  DivElement _userName;
  ButtonElement _signOutButton;
  ButtonElement _signInButton;

  AuthHeaderView() {
    authElement = new DivElement()
      ..classes.add('auth');

    _userPic = new DivElement()
      ..classes.add('user-pic');
    authElement.append(_userPic);

    _userName = new DivElement()
      ..classes.add('user-name');
    authElement.append(_userName);

    _signOutButton = new ButtonElement()
      ..text = 'Sign out'
      ..onClick.listen((_) => command(UIAction.signOutButtonClicked, null));
    authElement.append(_signOutButton);

    _signInButton = new ButtonElement()
      ..text = 'Sign in'
      ..onClick.listen((_) => command(UIAction.signInButtonClicked, null));
    authElement.append(_signInButton);
  }

  void signIn(String userName, userPicUrl) {
    // Set the user's profile pic and name
    _userPic.style.backgroundImage = 'url($userPicUrl)';
    _userName.text = userName;

    // Show user's profile pic, name and sign-out button.
    _userName.attributes.remove('hidden');
    _userPic.attributes.remove('hidden');
    _signOutButton.attributes.remove('hidden');

    // Hide sign-in button.
    _signInButton.setAttribute('hidden', 'true');
  }

  void signOut() {
    // Hide user's profile pic, name and sign-out button.
    _userName.attributes['hidden'] = 'true';
    _userPic.attributes['hidden'] = 'true';
    _signOutButton.attributes['hidden'] = 'true';

    // Show sign-in button.
    _signInButton.attributes.remove('hidden');
  }
}

class AuthMainView {
  DivElement authElement;
  ButtonElement _signInButton;

  final descriptionText1 = 'Sign in to Nook where you can manage SMS conversations.';
  final descriptionText2 = 'Please contact Africa\'s Voices for login details.';

  AuthMainView() {
    authElement = new DivElement()
      ..classes.add('auth-main');

    var logosContainer = new DivElement()
      ..classes.add('auth-main__logos');
    authElement.append(logosContainer);

    var avfLogo = new ImageElement(src: 'assets/africas-voices-logo.svg')
      ..classes.add('partner-logo')
      ..classes.add('partner-logo--avf');
    logosContainer.append(avfLogo);

    var unicefLogo = new ImageElement(src: 'assets/UNICEF-logo.svg')
      ..classes.add('partner-logo')
      ..classes.add('partner-logo--unicef');
    logosContainer.append(unicefLogo);

    var shortDescription = new DivElement()
      ..classes.add('project-description')
      ..append(new ParagraphElement()..text = descriptionText1)
      ..append(new ParagraphElement()..text = descriptionText2);
    authElement.append(shortDescription);

    _signInButton = new ButtonElement()
      ..text = 'Sign in'
      ..onClick.listen((_) => command(UIAction.signInButtonClicked, null));
    authElement.append(_signInButton);
  }
}

class UrlView {

  static const String queryFilterKey = 'filter';
  static const String queryDisableRepliesKey = 'disableReplies';

  List<String> get pageUrlFilterTags {
    var uri = Uri.parse(window.location.href);
    if (uri.queryParameters.containsKey(queryFilterKey)) {
      List<String> filterTags = uri.queryParameters[queryFilterKey].split(' ');
      filterTags.removeWhere((tag) => tag == "");
      return filterTags;
    }
    return [];
  }

  set pageUrlFilterTags(List<String> filterTags) {
    var uri = Uri.parse(window.location.href);
    Map<String, String> queryParameters = new Map.from(uri.queryParameters);
    queryParameters['filter'] = filterTags.join(' ');
    uri = uri.replace(queryParameters: queryParameters);
    window.history.pushState('', '', uri.toString());
  }

  bool get shouldDisableReplies {
    var uri = Uri.parse(window.location.href);
    if (uri.queryParameters.containsKey(queryDisableRepliesKey)) {
      return uri.queryParameters[queryDisableRepliesKey].toLowerCase() == 'true';
    }
    return false;
  }
}

class _ConversationListViewModel {
  /// The summaries to be displayed.
  final _summaries = <ConversationSummary>[];

  /// The DOM element used to display the summaries
  /// and typically containing only a subset of the summary elements.
  final _conversationList = new DivElement();

  /// The vertical scroll distance of the summary elements
  /// in the [_conversationList] in pixels.
  int _scrollLength = 0;

  /// The width of the [_conversationList] scrolling area in pixels
  /// or `null` if it has not been cached yet.
  int _scrollWidth = 10;

  /// When the width of the scrolling area changes, a delayed [Future] is
  /// created to recalculate [_scrollLength].
  Future _scrollLengthRecalc;

  _ConversationListViewModel() {
    _conversationList
      ..classes.add('conversation-list')
      ..onScroll.listen(_updateCachedElements);
  }

  void addConversation(ConversationSummary summary, int position) {
    if (position == null || position > _conversationList.children.length) {
      position = _conversationList.children.length;
    } else if (position < 0) {
      position = 0;
    }
    _summaries.insert(position, summary);
    if (position < _conversationList.children.length) {
      // Insert the summary element into the cached/visible DOM elements
      Node refChild = _conversationList.children[position];
      _conversationList.insertBefore(summary.summaryElement, refChild);
      _scrollLength += summary.summaryElement.clientHeight;
      showDebugStatus();
    } else {
      _updateCachedElements();
    }
  }

  void clearConversations() {
    for (var summary in _summaries) {
      summary.disposeSummaryElement();
    }
    assert(_conversationList.children.length == 0);
    _summaries.clear();
    _scrollLength = 0;
    showDebugStatus();
  }

  void selectConversation(ConversationSummary summary) {
    var position = _summaries.indexOf(summary);

    // Add additional elements to the DOM as necessary
    // so that the conversation can be selected.
    while (position >= _conversationList.children.length) {
      var summary = _summaries[_conversationList.children.length];
      _conversationList.append(summary.summaryElement);
    }

    if (position >= 0) {
      summary.summaryElement.scrollIntoView();
    }
  }

  /// Update the [ConversationSummary] elements cached/displayed in the DOM
  /// based on the scroll position "scrollTop",
  /// the length of the cached/displayed DOM elements "scrollLength",
  /// and the height of the scrolling area.
  void _updateCachedElements([_ignored_]) {
    if (_scrollWidth == null) {
      _scrollWidth = _conversationList.clientWidth;
    } else if (_scrollWidth != _conversationList.clientWidth) {
      // If the scroll area width changed, then recalculate the scroll length
      // because the item heights and thus the scroll length depends upon the scroll area width.
      _scrollLengthRecalc ??= new Future.delayed(const Duration(seconds: 2), () {
        _scrollLength = _conversationList.children.fold(0, (len, element) => len + element.clientHeight);
        _scrollWidth = _conversationList.clientWidth;
        _scrollLengthRecalc = null;
        showDebugStatus();
      });
    }

    var desiredScrollLength = _conversationList.scrollTop + 3 * _conversationList.clientHeight;
    while (_scrollLength < desiredScrollLength && _conversationList.children.length < _summaries.length) {
      var summary = _summaries[_conversationList.children.length];
      _conversationList.append(summary.summaryElement);
      _scrollLength += summary.summaryElement.clientHeight;
    }
    showDebugStatus();
  }

  /// When debugging, uncomment this code to show information in the status area
  void showDebugStatus() {
    var desiredScrollLength = _conversationList.scrollTop + 3 * _conversationList.clientHeight;
    showNormalStatus('${_conversationList.scrollTop}, $desiredScrollLength, $_scrollLength, $_scrollWidth, ${ConversationSummary._conversationSummaryDomCount}');
  }
}
