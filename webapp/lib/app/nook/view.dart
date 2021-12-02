import 'dart:html';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:svg' as svg;

import 'package:intl/intl.dart';
import 'package:katikati_ui_lib/components/accordion/accordion.dart';
import 'package:katikati_ui_lib/components/tabs/tabs.dart';
import 'package:katikati_ui_lib/components/url_view/url_view.dart';
import 'package:katikati_ui_lib/utils/datetime.dart';
import 'package:katikati_ui_lib/components/tooltip/tooltip.dart';
import 'package:katikati_ui_lib/components/nav/button_links.dart';
import 'package:katikati_ui_lib/components/messages/freetext_message_send.dart';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/model/model.dart';
import 'package:katikati_ui_lib/components/conversation/conversation_item.dart';
import 'package:katikati_ui_lib/components/conversation/new_conversation_modal.dart';
import 'package:katikati_ui_lib/components/user_presence/user_presence_indicator.dart';
import 'package:katikati_ui_lib/components/scroll_indicator/scroll_indicator.dart';
import 'package:katikati_ui_lib/components/tag/tag.dart';
import 'package:katikati_ui_lib/components/turnline/turnline.dart' as tl;
import 'package:katikati_ui_lib/components/button/button.dart' as buttons;
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:nook/view.dart';
import 'package:nook/app/utils.dart';

import 'controller.dart';
import 'dom_utils.dart';
import 'lazy_list_view_model.dart';

const ENABLE_NEW_CONVERSTION = false;

Logger log = new Logger('view.dart');

NookPageView _view;

class NookPageView extends PageView {
  OtherLoggedInUsers otherLoggedInUsers;
  ConversationListSelectHeader conversationListSelectView;
  ConversationListPanelView conversationListPanelView;
  ConversationIdFilter conversationIdFilter;
  Map<TagFilterType, ConversationFilter> conversationFilter;
  ConversationPanelView conversationPanelView;
  ReplyPanelView replyPanelView;
  TagPanelView tagPanelView;
  TurnlinePanelView turnlinePanelView;
  NotesPanelView notesPanelView;
  UrlView urlView;
  TabsView tabsView;

  NookPageView(NookController controller) : super(controller) {
    _view = this;

    otherLoggedInUsers = new OtherLoggedInUsers();
    conversationListSelectView = new ConversationListSelectHeader();
    conversationListPanelView = new ConversationListPanelView();
    conversationPanelView = new ConversationPanelView();
    replyPanelView = new ReplyPanelView();
    tagPanelView = new TagPanelView();
    turnlinePanelView = new TurnlinePanelView();
    notesPanelView = new NotesPanelView();
    urlView = new UrlView();

    tabsView = new TabsView([]);

    conversationFilter = {
      TagFilterType.include: conversationListPanelView.conversationIncludeFilter,
      TagFilterType.exclude: conversationListPanelView.conversationExcludeFilter,
      TagFilterType.lastInboundTurn: conversationListPanelView.conversationTurnsFilter
    };
    conversationIdFilter = conversationListPanelView.conversationIdFilter;

    document.onKeyDown.listen((event) {
      if (ignoreShortcut(event)) return;
      appController.command(UIAction.keyPressed, new KeyPressData(event.key, event.altKey || event.ctrlKey || event.metaKey || event.shiftKey));
    });
  }

  void initSignedInView(String displayName, String photoUrl) {
    super.initSignedInView(displayName, photoUrl);

    var conversationListColumn = DivElement()..classes = ["nook-column-wrapper", "nook-column-wrapper--conversation-list"];
    var messagesViewColumn = DivElement()..classes = ["nook-column-wrapper", "nook-column-wrapper--messages-view"];
    var tabsViewColumn = DivElement()..classes = ["nook-column-wrapper", "nook-column-wrapper--tabs-view"];

    mainElement
      ..append(conversationListColumn)
      ..append(messagesViewColumn)
      ..append(tabsViewColumn);

    conversationListColumn.append(conversationListPanelView.conversationListPanel);
    messagesViewColumn.append(conversationPanelView.conversationPanel);
    tabsViewColumn.append(tabsView.renderElement);

    bodyElement.append(snackbarView.snackbarElement);

    showNormalStatus('signed in');

    HttpRequest.getString('/assets/latest_commit_hash.json').then((latestCommitHashConfigJson) {
      var latestCommitHash = (json.decode(latestCommitHashConfigJson) as Map)['latestCommitHash'];
      showNormalStatus('signed in: ${latestCommitHash.substring(0, 8)}...');
    }, onError: (_) { /* Do nothing */ });

    var links = ButtonLinksView(navLinks, window.location.pathname);

    navHeaderView.navContent = new DivElement()
      ..style.display = 'flex'
      ..append(links.renderElement)
      ..append(conversationListSelectView.panel);
    navHeaderView.navViewElement.insertBefore(otherLoggedInUsers.loggedInUsers, navHeaderView.navViewElement.querySelector('.nav__auth_header'));
  }

  void initSignedOutView() {
    super.initSignedOutView();
    showNormalStatus('signed out');
  }

  void showPanels(bool showReplyPanel, bool enableEditNotesPanel, bool showTagPanel, bool tagMessagesEnabled, bool tagConversationsEnabled, bool showTurnlinePanel, String defaultTab) {
    List<TabView> tabsToSet = [];

    if (showReplyPanel) {
      var standardMessagesTab = TabView('standard_messages', "Standard messages", replyPanelView.replyPanel);
      tabsToSet.add(standardMessagesTab);
    }

    if (showTagPanel) {
      var tagsTab = TabView('tag', "Tags", tagPanelView.tagPanel);
      tabsToSet.add(tagsTab);
      tagPanelView.enableTagging(tagMessagesEnabled, tagConversationsEnabled, false);
    }

    if (showTurnlinePanel) {
      var turnlineTab = TabView('turnline', "Turnline", turnlinePanelView.turnlinePanel);
      tabsToSet.add(turnlineTab);
    }

    if (enableEditNotesPanel) {
      var notesTab = TabView('notes', "Notes", notesPanelView.notesPanel);
      tabsToSet.add(notesTab);
      notesPanelView.enableEditableNotes(enableEditNotesPanel);
    }

    tabsView.setTabs(tabsToSet);

    if (showReplyPanel && defaultTab == 'standard_messages') {
      tabsView.selectTab(defaultTab);
    } else if (showTagPanel && defaultTab == 'tag') {
      tabsView.selectTab(defaultTab);
    } else if (showTurnlinePanel && defaultTab == 'turnline') {
      tabsView.selectTab(defaultTab);
    } else if (enableEditNotesPanel && defaultTab == 'notes') {
      tabsView.selectTab(defaultTab);
    }

  }

  bool sendingMultiMessagesUserConfirmation(int noMessages) {
    return window.confirm('Are you sure you want to send $noMessages SMS message${noMessages == 1 ? "" : "s" }?');
  }

  bool taggingMultiConversationsUserConfirmation(int noConversations) {
    return window.confirm('Are you sure you want to tag $noConversations conversation${noConversations == 1 ? "" : "s" }?');
  }

  bool sendingManualMessageUserConfirmation(String messageText) {
    return window.confirm('Are you sure you want to send the following message?\n\n$messageText');
  }

  bool sendingManualMultiMessageUserConfirmation(String messageText, int noMessages) {
    return window.confirm('Are you sure you want to send the following message to $noMessages conversation${noMessages == 1 ? "" : "s" }?\n\n$messageText');
  }

  bool sendingMultiMessageGroupUserConfirmation(int noMessages, int noConversations) {
    return window.confirm('Are you sure you want to send $noMessages SMS message${noMessages == 1 ? "" : "s" } to $noConversations conversation${noConversations == 1 ? "" : "s" }?');
  }

  void showNormalStatus(String text) {
    tagPanelView._statusText.text = text;
    tagPanelView._statusPanel.classes.remove('status-line-warning');
  }

  void showWarningStatus(String text) {
    tagPanelView._statusText.text = text;
    tagPanelView._statusPanel.classes.add('status-line-warning');
  }
}



void makeEditable(Element element, {void onChange(e), void onEnter(e)}) {
  element
    ..contentEditable = 'true'
    ..onBlur.listen((e) {
      if (onChange != null) onChange(e);
    })
    ..onKeyUp.listen((e) {
      if (onEnter != null && e.keyCode == KeyCode.ENTER) {
        onEnter(e);
      }
    });
}

const REPLY_PANEL_TITLE = 'Standard messages';
const NOTES_PANEL_TITLE = 'Notes';
const TAG_PANEL_TITLE = 'Tags';
const ADD_REPLY_INFO = 'Add new suggested response';
const ADD_TAG_INFO = 'Add new tag';

class ConversationPanelView with AutomaticSuggestionIndicator {
  // HTML elements
  DivElement conversationPanel;
  DivElement _conversationSummary;
  DivElement _messages;
  DivElement _conversationWarning;
  DivElement _conversationId;
  DivElement _conversationIdCopy;
  DivElement _info;
  DivElement _tags;
  FreetextMessageSendView _freetextMessageSendView;
  DivElement _suggestedMessages;
  DivElement _suggestedMessagesActions;

  List<MessageView> _messageViews = [];
  Map<String, MessageView> _messageViewsMap = {};
  List<SuggestedMessageView> _suggestedMessageViews = [];

  bool _scrolledToBottom = true;
  SpanElement _newMessageIndicator;

  DivElement get messages => _messages;

  ConversationPanelView() {
    conversationPanel = new DivElement()
      ..classes.add('conversation-panel')
      ..onClick.listen((_) {
        _view.appController.command(UIAction.deselectConversationSummary, null);
        _view.appController.command(UIAction.deselectMessage, null);
        _view.appController.command(UIAction.deselectMessageTag, null);
        _view.appController.command(UIAction.deselectConversationTag, null);
      });

    _conversationSummary = new DivElement()
      ..classes.add('conversation-summary');
    _conversationSummary.onClick.listen((e) {
      e.stopPropagation(); // to stop immediate deselection
      _view.appController.command(UIAction.selectConversationSummary, new ConversationData(_conversationIdCopy.dataset['copy-value']));
    });
    conversationPanel.append(_conversationSummary);

    var title = new DivElement()
      ..classes.add('conversation-summary__title');
    _conversationSummary.append(title);

    _conversationWarning = new DivElement()
      ..classes.add('conversation-summary__warning')
      ..classes.add('hidden');
    title.append(_conversationWarning);

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
    _conversationSummary.append(_info);

    _tags = new DivElement()
      ..classes.add('conversation-summary__tags');
    _conversationSummary.append(_tags);

    _messages = new DivElement()
      ..classes.add('messages');
    _messages.onScroll.listen((e) {
      if (_messages.scrollTop == _messages.scrollHeight - _messages.offsetHeight) {
        _newMessageIndicator.classes.toggle("hidden", true);
        _scrolledToBottom = true;
      } else {
        _scrolledToBottom = false;
      }
    });
    conversationPanel.append(_messages);

    _freetextMessageSendView = FreetextMessageSendView("", maxLength: _view.appController.MESSAGE_MAX_LENGTH)..onSend.listen((messageText) {
      _view.appController.command(UIAction.sendManualMessage, new ManualReplyData(messageText));
    });
    conversationPanel.append(_freetextMessageSendView.renderElement);

    var suggestedMessagesPanel = DivElement()
      ..classes.add('suggested-message-panel');
    conversationPanel.append(suggestedMessagesPanel);

    _suggestedMessages = DivElement()
      ..classes.add('suggested-message-panel__messages');
    suggestedMessagesPanel.append(_suggestedMessages);

    _suggestedMessagesActions = DivElement()
      ..classes.add('suggested-message-panel__actions')
      ..classes.add('hidden');
    suggestedMessagesPanel.append(_suggestedMessagesActions);

    var sendSuggestedMessages = DivElement()
      ..text = SEND_SUGGESTED_REPLY_BUTTON_TEXT
      ..classes.add('suggested-message-panel__action')
      ..onClick.listen((_) => _view.appController.command(UIAction.confirmSuggestedMessages, null));
    _suggestedMessagesActions.append(sendSuggestedMessages);

    var deleteSuggestedMessages = DivElement()
      ..text = DELETE_SUGGESTED_REPLY_BUTTON_TEXT
      ..classes.add('action--delete')
      ..classes.add('suggested-message-panel__action')
      ..onClick.listen((_) => _view.appController.command(UIAction.rejectSuggestedMessages, null));
    _suggestedMessagesActions.append(deleteSuggestedMessages);

    _suggestedMessagesActions.append(automaticSuggestionIndicator..classes.add('absolute'));

    _newMessageIndicator = SpanElement()
      ..classes.add('messages__new-message-indicator')
      ..classes.add('hidden')
      ..innerText = "New messages ↓";
    _newMessageIndicator.onClick.listen((e) {
      _messages.scrollTop = _messages.scrollHeight;
      _newMessageIndicator.classes.toggle("hidden", true);
    });
    conversationPanel.append(_newMessageIndicator);
  }

  set deidentifiedPhoneNumber(String deidentifiedPhoneNumber) => _conversationIdCopy.dataset['copy-value'] = deidentifiedPhoneNumber;
  set deidentifiedPhoneNumberShort(String deidentifiedPhoneNumberShort) => _conversationId.text = deidentifiedPhoneNumberShort;
  set demographicsInfo(String demographicsInfo) => _info.text = demographicsInfo;

  void addMessage(MessageView message) {
    _messages.append(message.renderElement);
    _messageViews.add(message);
    _messageViewsMap[message.messageId] = message;
    message.renderElement.scrollIntoView();
  }

  void padOrTrimMessageViews(int count) {
    if (_messageViews.length == count) return;
    if (_messageViews.length > count) {
      for (int i = _messageViews.length - 1; i >= count; --i) {
        _messages.children.removeAt(i);
        _messageViews.removeAt(i);
      }
      return;
    }

    for (int i = _messageViews.length; i < count; i++) {
      MessageView message = new MessageView('', DateTime.now(), '', '$i');
      _messages.append(message.renderElement);
      _messageViews.add(message);
    }
  }

  void updateMessage(MessageView message, int index) {
    if (index >= _messageViews.length) {
      _messages.append(message.renderElement);
      _messageViews.add(message);
      _messageViewsMap[message.messageId] = message;
      return;
    }
    _messages.children[index] = message.renderElement;
    _messageViews[index] = message;
    _messageViewsMap[message.messageId] = message;
  }

  void addTags(TagView tag) {
    _tags.append(tag.renderElement);
  }

  void removeTag(String tagId) {
    _tags.children.removeWhere((Element d) => d.dataset["id"] == tagId);
  }

  void markTagSelected(String tagId, bool selected) {
    _tags.children
        .where((Element t) => t.dataset["id"] == tagId)
        .forEach((Element t) => t.classes.toggle("tag--selected", selected));
  }

  void removeTags() {
    int tagsNo = _tags.children.length;
    for (int i = 0; i < tagsNo; i++) {
      _tags.firstChild.remove();
    }
  }

  void selectMessage(int index) {
    _messageViews[index]._select();
  }

  void deselectMessage() {
    MessageView._deselect();
  }

  void selectConversationSummary() {
    _conversationSummary.classes.toggle("conversation-summary--selected", true);
  }

  void deselectConversationSummary() {
    _conversationSummary.classes.toggle("conversation-summary--selected", false);
  }

  MessageView messageViewAtIndex(int index) {
    return _messageViews[index];
  }

  MessageView messageViewWithId(String id) {
    return _messageViewsMap[id];
  }

  void clear() {
    _conversationId.text = '';
    _conversationIdCopy.dataset['copy-value'] = '';
    _info.text = '';
    _messageViews = [];
    _messageViewsMap = {};
    _suggestedMessageViews = [];
    removeTags();
    clearNewMessageBox();
    clearWarning();
    setSuggestedMessages([]);

    int messagesNo = _messages.children.length;
    for (int i = 0; i < messagesNo; i++) {
      _messages.firstChild.remove();
    }
  }

  void updateDateSeparators() {
    String lastDate = '';
    for (var messageView in _messageViews) {
      String dateString = messageView._dateSeparator.formattedDateString;
      if (lastDate != dateString) {
        messageView._dateSeparator.show();
      } else {
        messageView._dateSeparator.hide();
      }
      lastDate = dateString;
    }
  }

  void clearNewMessageBox() {
    _freetextMessageSendView.clear();
  }

  void showCustomMessageBox(bool show) {
    // todo: convert to hide / show method under FreetextMessageSendView
    if (show) {
      _freetextMessageSendView.renderElement.classes.remove('hidden');
    } else {
      _freetextMessageSendView.renderElement.classes.add('hidden');
    }
  }

  void enableEditableTranslations(bool enable) {
    for (var messageView in _messageViews) {
      messageView.enableEditableTranslations(enable);
    }
  }

  void showWarning(String explanation) {
    _conversationWarning.title = explanation;
    _conversationWarning.classes.remove('hidden');
  }

  void clearWarning() {
    _conversationWarning.title = '';
    _conversationWarning.classes.add('hidden');
  }

  void setSuggestedMessages(List<SuggestedMessageView> messages) {
    _suggestedMessages.children.clear();
    for (var message in messages) {
      _suggestedMessages.append(message.message);
    }
    _suggestedMessagesActions.classes.toggle('hidden', _suggestedMessages.children.isEmpty);
  }

  void handleNewMessage() {
    if (_scrolledToBottom) {
      _messages.scrollTop = _messages.scrollHeight;
      return;
    }

    _newMessageIndicator.classes.toggle("hidden", false);
    _newMessageIndicator.style.top = "${_messages.offsetHeight + _messages.offsetTop - 30}px";
  }
}

class DateSeparatorView {
  DateTime _dateTime;

  DivElement renderElement;
  SpanElement _dateElement;

  String get formattedDateString => _getDaysAgoSinceToday(_dateTime);
  set dateTime (DateTime dateTime) {
    this._dateTime = dateTime;
    _dateElement.innerText = formattedDateString;
  }

  DateSeparatorView(this._dateTime) {
    renderElement = DivElement()..className = 'messages-date-separator__wrapper';
    _dateElement = SpanElement()
      ..className = 'messages-date-separator'
      ..innerText = formattedDateString;
    renderElement.append(_dateElement);
  }

  void hide() {
    renderElement.setAttribute('hidden', 'true');
  }

  void show() {
    renderElement.removeAttribute('hidden');
  }

  String _getDaysAgoSinceToday(DateTime dateTime) {
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final differenceDays = today.difference(date).inDays;
    final DateFormat formatter = DateFormat('MMM yyyy');

    if (differenceDays < 1) {
      return "Today";
    } else if (differenceDays == 1) {
      return "Yesterday";
    } else {
      return formatter.format(dateTime);
    }
  }
}

class MessageView {
  DivElement renderElement;
  DivElement _message;
  DivElement _messageBubble;
  DivElement _messageStatus;
  DivElement _messageDateTime;
  DivElement _messageText;
  DivElement _messageTranslation;
  DivElement _messageTags;
  buttons.Button _addTag;
  DateSeparatorView _dateSeparator;

  String messageId;

  static MessageView selectedMessageView;

  MessageView(String text, DateTime dateTime, String conversationId, this.messageId, {String translation = '', bool incoming = true, List<TagView> tags = const[], MessageStatus status = null}) {
    _dateSeparator = DateSeparatorView(dateTime);

    _message = new DivElement()
      ..classes.add('message')
      ..classes.add(incoming ? 'message--incoming' : 'message--outgoing')
      ..dataset['conversationId'] = conversationId
      ..dataset['messageId'] = messageId;

    renderElement = new DivElement()
      ..append(_dateSeparator.renderElement)
      ..append(_message);

    _messageBubble = new DivElement()
      ..classes.add('message__bubble')
      ..onClick.listen((event) {
        event.preventDefault();
        event.stopPropagation();
        _view.appController.command(UIAction.selectMessage, new MessageData(conversationId, messageId));
      });

    _messageStatus = new DivElement()
      ..classes.add('message__status');
    _messageBubble.append(_messageStatus);

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
      ..text = translation;
    _messageBubble.append(_messageTranslation);

    _messageTags = new DivElement()
      ..classes.add('message__tags')
      ..classes.toggle('message__tags--outgoing', !incoming)
      ..classes.add('hover-parent');
    tags.forEach((tag) => _messageTags.append(tag.renderElement));

    if (incoming) {
      _message.append(_messageBubble);
      _message.append(_messageTags);
    } else {
      _message.append(_messageTags);
      _message.append(_messageBubble);
    }

    _addTag = buttons.Button(buttons.ButtonType.add, onClick: (e) {
      e.stopPropagation();
      _view.appController.command(UIAction.selectMessage, new MessageData(conversationId, messageId));
      _view.appController.command(UIAction.startAddNewTagInline, new MessageData(conversationId, messageId));
    });
    _addTag.renderElement.classes
      ..add('tag__add')
      ..add('button--hover-only');
    _messageTags.append(_addTag.renderElement);

    setStatus(status);
  }

  void set text(String value) => _messageText.text = value;
  set translation(String translation) => _messageTranslation.text = translation;
  void set datetime(DateTime value) {
    _messageDateTime.text = _formatDateTime(value);
    _dateSeparator.dateTime = value;
  }

  void addNewTag(NewTagViewWithSuggestions tag) {
    _messageTags.insertBefore(tag.renderElement, _addTag.renderElement);
    tag.renderElement.scrollIntoView();
  }

  void addTag(TagView tag, [int position]) {
    if (position == null || position >= _messageTags.children.length) {
      // Add at the end
      _messageTags.insertBefore(tag.renderElement, _addTag.renderElement);
      tag.renderElement.scrollIntoView();
      return;
    }
    // Add before an existing tag
    if (position < 0) {
      position = 0;
    }
    Node refChild = _messageTags.children[position];
    _messageTags.insertBefore(tag.renderElement, refChild);
    tag.renderElement.scrollIntoView();
  }

  void removeTag(String tagId) {
    _messageTags.children.removeWhere((e) => e.dataset["id"] == tagId);
  }

  void markSelectedTag(String tagId, bool selected) {
    _messageTags.children
        .where((Element t) => t.dataset["id"] == tagId)
        .forEach((Element t) => t.classes.toggle("tag--selected", selected));
  }

  void _select() {
    MessageView._deselect();
    _message.classes.add('message--selected');
    selectedMessageView = this;
  }

  static void _deselect() {
    selectedMessageView?._message?.classes?.remove('message--selected');
    selectedMessageView = null;
  }

  void setStatus(MessageStatus status) {
    // clear any previous status
    _messageStatus.text = '';
    _message.classes.removeAll([
      'message--pending',
      'message--failed',
      'message--unknown',
      ]);

    switch (status) {
      case MessageStatus.confirmed:
        // default is confirmed, nothing to do
        break;
      case MessageStatus.pending:
        _message.classes.add('message--pending');
        _messageStatus.text = '[Pending]';
        _dateSeparator.hide();
        break;
      case MessageStatus.failed:
        _message.classes.add('message--failed');
        _messageStatus.text = '[Failed]';
        break;
      case MessageStatus.unknown:
      default:
        _message.classes.add('message--unknown');
        _messageStatus.text = '[$status]';
        break;
    }
  }

  void enableEditableTranslations(bool enable) {
    // Just replace the translation HTML element with new one and call [makeEditable] on it if editable.
    String translation = _messageTranslation.text;
    _messageTranslation.remove();
    _messageTranslation = new DivElement()
      ..classes.add('message__translation')
      ..text = translation;
    if (enable) {
      makeEditable(_messageTranslation, onChange: (_) {
        _view.appController.command(UIAction.updateTranslation,
                new TranslationData(
                    _messageTranslation.text,
                    _message.dataset['conversationId'],
                    _message.dataset['messageId']));
      });
    }
    _messageBubble.append(_messageTranslation);
  }
}

class SuggestedMessageView {
  DivElement message;
  DivElement _messageBubble;
  DivElement _messageText;
  DivElement _messageTranslation;

  SuggestedMessageView(String text, {String translation = ''}) {
    message = new DivElement()
      ..classes.add('message')
      ..classes.add('message--suggested');

    _messageBubble = new DivElement()
      ..classes.add('message__bubble');
    message.append(_messageBubble);

    _messageText = new DivElement()
      ..classes.add('message__text')
      ..text = text;
    _messageBubble.append(_messageText);

    _messageTranslation = new DivElement()
      ..classes.add('message__translation')
      ..text = translation;
    _messageBubble.append(_messageTranslation);
  }
}

final DateFormat _dateFormat = new DateFormat('E d MMM y');
final DateFormat _dateFormatNoYear = new DateFormat('E d MMM');
final DateFormat _hourFormat = new DateFormat('hh:mm a');

String _formatDateTime(DateTime dateTime) {
  DateTime now = DateTime.now();
  DateTime localDateTime = dateTime; // TODO: EB Adjust to local timezone well before passing to this function

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

class MessageTagView extends TagView {
  MessageTagView(String text, String tagId, TagStyle tagStyle, {bool actionsBeforeTagText = false, bool highlight = false}) : super(text, tagId, tagStyle: tagStyle, deletable: true, actionsBeforeText: actionsBeforeTagText) {
    onDelete = () {
      markPending(true);
      DivElement message = getAncestors(renderElement).firstWhere((e) => e.classes.contains('message'), orElse: () => null);
      _view.appController.command(UIAction.removeMessageTag, new MessageTagData(tagId, message.dataset['messageId']));
    };

    onSelect = () {
      DivElement message = getAncestors(renderElement).firstWhere((e) => e.classes.contains('message'), orElse: () => null);
      _view.appController.command(UIAction.selectMessageTag, new MessageTagData(tagId, message.dataset['messageId']));
    };

    markHighlighted(highlight);
  }
}

class SuggestedMessageTagView extends TagView {
  SuggestedMessageTagView(String text, String tagId, TagStyle tagStyle, {bool actionsBeforeTagText = false, bool highlight = false}) : super(text, tagId, tagStyle: tagStyle, acceptable: true, deletable: true, suggested: true, actionsBeforeText: actionsBeforeTagText) {

    onDelete = () {
      markPending(true);
      DivElement message = getAncestors(renderElement).firstWhere((e) => e.classes.contains('message'), orElse: () => null);
      _view.appController.command(UIAction.rejectMessageTag, new MessageTagData(tagId, message.dataset['messageId']));
    };

    onAccept = () {
      markPending(true);
      DivElement message = getAncestors(renderElement).firstWhere((e) => e.classes.contains('message'), orElse: () => null);
        _view.appController.command(UIAction.confirmMessageTag, new MessageTagData(tagId, message.dataset['messageId']));
    };

    markHighlighted(highlight);
  }
}

class ConversationTagView extends TagView {
  ConversationTagView(String text, String tagId, TagStyle tagStyle) : super(text, tagId, tagStyle: tagStyle, deletable: true) {
    onDelete = () {
      markPending(true);
      DivElement messageSummary = getAncestors(renderElement).firstWhere((e) => e.classes.contains('conversation-summary'));
      _view.appController.command(UIAction.removeConversationTag, new ConversationTagData(tagId, messageSummary.dataset['id']));
    };

    onSelect = () {
      DivElement messageSummary = getAncestors(renderElement).firstWhere((e) => e.classes.contains('conversation-summary'));
      _view.appController.command(UIAction.selectConversationTag, new ConversationTagData(tagId, messageSummary.dataset['id']));
    };
  }
}

class SuggestedConversationTagView extends TagView {
  SuggestedConversationTagView(String text, String tagId, TagStyle tagStyle) : super(text, tagId, tagStyle: tagStyle, deletable: true, acceptable: true, suggested: true) {
    onDelete = () {
      markPending(true);
      DivElement messageSummary = getAncestors(renderElement).firstWhere((e) => e.classes.contains('conversation-summary'));
      _view.appController.command(UIAction.rejectConversationTag, new ConversationTagData(tagId, messageSummary.dataset['id']));
    };

    onAccept = () {
      markPending(true);
      DivElement messageSummary = getAncestors(renderElement).firstWhere((e) => e.classes.contains('conversation-summary'));
      _view.appController.command(UIAction.confirmConversationTag, new ConversationTagData(tagId, messageSummary.dataset['id']));
    };
  }
}

mixin AutomaticSuggestionIndicator {
  Element get automaticSuggestionIndicator => Element.html('<i class="fas fa-robot automated-action-indicator"></i>');
}

class EditableTagView extends NewTagViewWithSuggestions {
  EditableTagView(List<TagSuggestion> suggestions, String messageId, {DivElement boundingElement}) : super(suggestions, boundingElement: boundingElement) {
    onNewTag = (value) {
      _view.appController.command(UIAction.saveNewTagInline, new SaveTagData(value, model.generateTagId()));
    };

    onAcceptSuggestion = (tagId) {
      _view.appController.command(UIAction.addTag, new TagData(tagId));
      _view.appController.command(UIAction.cancelAddNewTagInline);
    };

    onCancel = () {
      _view.appController.command(UIAction.cancelAddNewTagInline);
    };
  }
}

class FilterMenuTagView extends TagView {
  TagFilterType _filterType;
  FilterMenuTagView(String text, String tagId, TagStyle tagStyle, TagFilterType filterType) : super(text, tagId, tagStyle: tagStyle) {
    onSelect = () {
      handleClicked(tagId);
    };
    _filterType = filterType;
  }

  void handleClicked(String tagId) {
    _view.appController.command(UIAction.addFilterTag, new FilterTagData(tagId, _filterType));
  }
}

class FilterTagView extends TagView {
  TagFilterType _filterType;
  FilterTagView(String text, String tagId, TagStyle tagStyle, TagFilterType filterType, {bool deletable = true}) : super(text, tagId, tagStyle: tagStyle, deletable: deletable) {
    _filterType = filterType;
    onDelete = () {
      _view.appController.command(UIAction.removeFilterTag, new FilterTagData(tagId, _filterType));
    };
  }
}

// A drop down to select which conversation list to display
class ConversationListSelectHeader {
  DivElement panel;
  SelectElement _selectElement;
  List<ConversationListShard> _shards;

  ConversationListSelectHeader() {
    panel = new DivElement()
      ..classes.add('conversation-list-select-header')
      ..style.display = 'none';

    panel.append(
      new SpanElement()
        ..classes.add('conversation-list-select-label')
        ..text = 'Conversation List:');

    panel.append(
      _selectElement = new SelectElement()
        ..classes.add('conversation-list-select')
        ..add(OptionElement(data: '... loading conversation lists ...'), null)
        ..onChange.listen(shardSelected));
  }

  void updateConversationLists(List<ConversationListShard> shards) {
    // TODO Consider displaying summary information about each shard... e.g. # of unread conversations
    if (_shards == null) {
      _selectElement.options.first.remove();
      _shards = [];
      if (shards.isEmpty) {
        _shards.add(ConversationListShard()..name = 'nook_conversations');
      } else {
        _shards.addAll(shards);
      }
      if (_shards.length > 1) {
        _selectElement.add(OptionElement(
            data: 'Select the conversations to be displayed',
            value: ConversationListData.NONE
        ), null);
      }
      for (var shard in _shards) {
        _selectElement.add(OptionElement(
            data: shard.displayName,
            value: shard.conversationListRoot
        ), null);
      }
      if (_shards.length > 1) {
        _view.conversationListSelectView.panel.style.visibility = 'visible';
      }
    } else {
      bool shardingHasChanged = false;
      for (var newShard in shards) {
        shardingHasChanged = true;
        int optionIndex = _shards.length > 1 ? 1 : 0;
        for (int shardIndex = 0; shardIndex < _shards.length; ++shardIndex) {
          if (_shards[shardIndex].docId == newShard.docId) {
            shardingHasChanged = false;
            var oldOption = _selectElement.options[optionIndex];
            var isSelected = oldOption.selected;
            oldOption.replaceWith(OptionElement(
                data: newShard.displayName,
                value: newShard.conversationListRoot,
                selected: isSelected
            ));
            _shards[shardIndex] = newShard;
            break;
          }
          ++optionIndex;
        }
        if (shardingHasChanged) {
          break;
        }
      }
      if (shardingHasChanged) {
        // TODO Prevent all user changes until page is refreshed and display a system message indicating as much
      }
    }
  }

  void shardSelected([Event event]) {
    _view.appController.command(UIAction.selectConversationList, ConversationListData(_selectElement.value));
  }

  void selectShard(String shard) {
    _selectElement.value = shard;
  }
}

class ConversationListPanelView {
  DivElement conversationListPanel;
  SpanElement _conversationPanelTitle;
  ChangeSortOrderActionView _changeSortOrder;
  LazyListViewModel _conversationList;
  CheckboxInputElement _selectAllCheckbox;
  ImageElement _loadSpinner;
  DivElement _selectConversationListMessage;

  NewConversationModal _newConversationModal;

  ConversationIdFilter conversationIdFilter;
  ConversationIncludeFilter conversationIncludeFilter;
  ConversationExcludeFilter conversationExcludeFilter;
  ConversationTurnsFilter conversationTurnsFilter;

  Map<String, ConversationSummary> _phoneToConversations = {};
  ConversationSummary activeConversation;

  String _lastAddedConversationDateSeparatorString = "";
  bool _showDateSeparator = true;

  int _totalConversations = 0;
  void set totalConversations(int v) {
    _totalConversations = v;
    _conversationPanelTitle.text = _conversationPanelTitleText;
  }
  String get _conversationPanelTitleText => '${_conversationList?.numberOfItems}/${_totalConversations}';

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
      ..onClick.listen((_) => _selectAllCheckbox.checked ? _view.appController.command(UIAction.selectAllConversations, null) : _view.appController.command(UIAction.deselectAllConversations, null));
    panelHeader.append(_selectAllCheckbox);

    _conversationPanelTitle = new SpanElement()
      // ..classes.add('panel-title')
      ..classes.add('conversation-list-header__title')
      ..text = _conversationPanelTitleText;
    panelHeader.append(SpanElement()..className = 'far fa-comments');
    panelHeader.append(_conversationPanelTitle);

    if (ENABLE_NEW_CONVERSTION) {
      _newConversationModal = NewConversationModal()
        ..onSubmit = (List<NewConversationFormData> conversations) => _view.appController.command(UIAction.addNewConversations, NewConversationsData(conversations));
      panelHeader.append(_newConversationModal.renderElement);
    }

    _changeSortOrder = ChangeSortOrderActionView();
    panelHeader.append(new DivElement()
      ..classes.add('conversation-list-header__sort-order')
      ..append(_changeSortOrder.renderElement));

    _loadSpinner = new ImageElement()
      ..classes.add('load-spinner')
      ..src = "/packages/katikati_ui_lib/components/brand_asset/logos/loading.svg";
    conversationListPanel.append(_loadSpinner);

    _selectConversationListMessage = new DivElement()
      ..classes.add('select-conversation-list-message')
      ..append(SpanElement()..text = "Select a conversation list above")
      ..hidden = true;
    conversationListPanel.append(_selectConversationListMessage);

    var conversationListElement = new DivElement()
      ..classes.add('conversation-list');
    _conversationList = new LazyListViewModel(conversationListElement, onAddItemCallback: _onAddConversation);
    conversationListPanel.append(conversationListElement);

    var panelFilters = new DivElement()
      ..classes.add('conversation-list-filters');
    conversationListPanel.append(panelFilters);

    conversationIdFilter = new ConversationIdFilter();
    panelFilters.append(conversationIdFilter.conversationFilter);

    conversationIncludeFilter = new ConversationIncludeFilter();
    panelFilters.append(conversationIncludeFilter.conversationFilter);

    conversationExcludeFilter = new ConversationExcludeFilter();
    panelFilters.append(conversationExcludeFilter.conversationFilter);

    conversationTurnsFilter = new ConversationTurnsFilter();
    panelFilters.append(conversationTurnsFilter.conversationFilter);
  }

  void _onAddConversation(ConversationSummary item) {
    var currentDateSeparatorString = dateStringForSeparator(item._dateTime);
    if (!_showDateSeparator) {
      item._toggleDateSeparator(false);
      return;
    }

    item._toggleDateSeparator((_lastAddedConversationDateSeparatorString == "" || currentDateSeparatorString != _lastAddedConversationDateSeparatorString));
    _lastAddedConversationDateSeparatorString = currentDateSeparatorString;
  }

  void updateConversationList(Set<Conversation> conversations, UIConversationSort sortOrder) {
    Set<String> conversationUuids = Set<String>();
    for (Conversation c in conversations) {
      conversationUuids.add(c.docId);
    }
    List<ConversationSummary> conversationSummaries = [];
    for (var conversation in conversations) {
      ConversationSummary summary = _phoneToConversations[conversation.docId];
      if (summary == null) {
        summary = new ConversationSummary(conversation.docId, "", false, ConversationItemStatus.normal, dateTime: conversation.messages.isEmpty ? null : conversation.messages.last.datetime);
      }
      updateConversationSummary(summary, conversation, sortOrder);
      _phoneToConversations[summary.deidentifiedPhoneNumber] = summary;
      conversationSummaries.add(summary);
    }
    ConversationSummary selectedConversation = _phoneToConversations[controller.activeConversation?.docId];
    _conversationList.setItems(conversationSummaries, selectedConversation);
    _conversationPanelTitle.text = _conversationPanelTitleText;
  }

  void updateConversationStatus(String conversationDocId, ConversationItemStatus status) {
    ConversationSummary summary = _phoneToConversations[conversationDocId];
    if (summary != null) {
      summary._updateStatus(status);
    }
  }

  void updateConversationSummary(ConversationSummary summary, Conversation conversation, UIConversationSort sortOrder) {
    var messageText = conversation.messages.isEmpty ? "No messages yet" : conversation.messages.last?.text;
    var messageDateTime = conversation.messages.isEmpty ? null : conversation.messages.last?.datetime;

    if (sortOrder == UIConversationSort.mostRecentInMessageFirst) {
      messageDateTime = conversation.mostRecentMessageInbound == null ? null : conversation.mostRecentMessageInbound.datetime;
    }

    bool hasPendingMessages = false;
    bool hasFailedMessages = false;
    if (conversation.messages.isNotEmpty) {
      Message lastMessage = conversation.messages.last;
      hasPendingMessages = lastMessage.status == MessageStatus.pending;
      hasFailedMessages = lastMessage.status == MessageStatus.failed;
    }

    summary
      .._updateText(messageText)
      .._updateDateTime(messageDateTime)
      .._updateStatus(hasFailedMessages ? ConversationItemStatus.failed : hasPendingMessages ? ConversationItemStatus.pending : ConversationItemStatus.normal);
    conversationNeedsReply(conversation) ? summary._markUnread() : summary._markRead();
  }

  void closeNewConversationModal() {
    _newConversationModal.closeModal();
  }

  void selectConversation(String deidentifiedPhoneNumber) {
    if (activeConversation?.deidentifiedPhoneNumber == deidentifiedPhoneNumber) return;
    activeConversation?._deselect();
    activeConversation = _phoneToConversations[deidentifiedPhoneNumber];
    activeConversation._select();
    _conversationList.selectItem(activeConversation);
    _view.appController.command(UIAction.markConversationRead, ConversationData(deidentifiedPhoneNumber));
  }

  void showWarning(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?._showWarning(true);
  }

  void clearWarning(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?._showWarning(false);
  }

  void showOtherUserPresence(String userId, String deidentifiedPhoneNumber, bool recent) {
    _phoneToConversations[deidentifiedPhoneNumber]?.showOtherUserPresence(userId, recent);
  }

  void clearOtherUserPresence(String userId, String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?.hideOtherUserPresence(userId);
  }

  void clearConversationList() {
    _conversationList.clearItems();
    _phoneToConversations.clear();
    _conversationPanelTitle.text = _conversationPanelTitleText;
  }

  void markConversationRead(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?._markRead();
  }

  void markConversationUnread(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?._markUnread();
  }

  void changeConversationSortOrder(UIConversationSort conversationSort) {
    _changeSortOrder.updateSelectElement(conversationSort);
    _showDateSeparator = conversationSort != UIConversationSort.alphabeticalById;
    _lastAddedConversationDateSeparatorString = "";
  }

  void checkConversation(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?._check();
  }

  void uncheckConversation(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?._uncheck();
  }

  void checkAllConversations() => _phoneToConversations.forEach((_, conversation) => conversation._check());
  void uncheckAllConversations() => _phoneToConversations.forEach((_, conversation) => conversation._uncheck());
  void showCheckboxes(bool show) {
    _selectAllCheckbox.hidden = !show;
    _phoneToConversations.forEach((_, conversation) => conversation._showCheckbox(show));
  }

  void uncheckSelectAllCheckbox() => _selectAllCheckbox.checked = false;

  void hideLoadSpinner() {
    _loadSpinner.hidden = true;
  }

  void showLoadSpinner() {
    hideSelectConversationListMessage();
    _loadSpinner.hidden = false;
  }


  void hideSelectConversationListMessage() {
    _selectConversationListMessage.hidden = true;
  }

  void showSelectConversationListMessage() {
    hideLoadSpinner();
    _selectConversationListMessage.hidden = false;
  }
}

class ConversationFilter {
  DivElement conversationFilter;
  DivElement _descriptionText;
  DivElement _tagsContainer;
  DivElement _tagsMenu;
  DivElement _tagsMenuWrapper;
  Accordion _tagAccordion;

  ConversationFilter() {
    conversationFilter = new DivElement()
      ..classes.add('conversation-filter');

    _descriptionText = new DivElement()
      ..text = 'Filter conversations ▹';
    conversationFilter.append(_descriptionText);

    _tagsMenu = new DivElement()
      ..classes.add('tags-menu');
    conversationFilter.append(_tagsMenu);

    var tagsMenuBox = new DivElement()
      ..classes.add('tags-menu__box');
    _tagsMenu.append(tagsMenuBox);

    var hoverButtress = new svg.SvgElement.svg(
      '<svg x="0px" y="0px" viewBox="0 0 50 120"><path d="M0,120 C15,120 50,10 50,0 L50,120Z" fill="white" stroke="white"/></svg>',
      validator: new NodeValidatorBuilder()..allowSvg()
    );
    hoverButtress.classes.add('tags-menu__buttress');
    tagsMenuBox.append(hoverButtress);

    _tagsMenuWrapper = new DivElement()
      ..classes.add('tags-menu__wrapper');
    tagsMenuBox.append(_tagsMenuWrapper);

    _tagsContainer = new DivElement()
      ..classes.add('tags-container');
    conversationFilter.append(_tagsContainer);

    _tagAccordion = Accordion([]);
    _tagsMenuWrapper.append(_tagAccordion.renderElement);
  }

  void addMenuTag(FilterMenuTagView tag, String category) {

    if (_tagAccordion.queryItem(category) == null) {
      var tagGroup = AccordionItem(category, DivElement()..innerText = category, DivElement()..className = 'tags-menu__container', false, dataId: category);
      _tagAccordion.appendItem(tagGroup);
    }

    var currentAccordion = _tagAccordion.queryItem(category);
    currentAccordion.bodyElement.append(tag.renderElement);

    // todo: potentially move this computation to onExpand
    // recompute the grid
    var wasHidden = !currentAccordion.isOpen;
    if (wasHidden) {
      currentAccordion.expand();
    }
    List<num> widths = currentAccordion.bodyElement.querySelectorAll('.tag__text').toList().map((e) => e.getBoundingClientRect().width).toList();
    if (wasHidden) {
      currentAccordion.collapse();
    }
    if (widths.isEmpty) {
      widths.add(1);
    }
    num totalGridWidth = widths.fold(0, (previousValue, width) => previousValue + width);
    num avgGridWidth = totalGridWidth / widths.length;
    num colSpacing = 10;
    num minColWidth = math.min(avgGridWidth + 2 * colSpacing, 138);
    num containerWidth = _tagsMenuWrapper.getBoundingClientRect().width;
    num columnWidth = containerWidth / (containerWidth / minColWidth).floor() - colSpacing;
    currentAccordion.bodyElement.dataset['width'] = "${columnWidth}";
    currentAccordion.bodyElement.style.setProperty('grid-template-columns', 'repeat(auto-fill, ${columnWidth}px)');
  }

  void removeMenuTag(FilterMenuTagView tag, String category) {
    _tagAccordion.items.forEach((accordion) {
      accordion.bodyElement.children.removeWhere((element) => accordion.id == category && element.dataset["id"] == tag.renderElement.dataset["id"]);
    });
  }

  void addFilterTag(FilterTagView tag) {
    _tagsContainer.append(tag.renderElement);
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
    int tagsNo = _tagsMenuWrapper.children.length;
    for (int i = 0; i < tagsNo; i++) {
      _tagsMenuWrapper.firstChild.remove();
    }
    assert(_tagsMenuWrapper.children.length == 0);
  }

  void showFilter(bool show) {
    this.conversationFilter.classes.toggle('hidden', !show);
  }
}

class ConversationIncludeFilter extends ConversationFilter {
  ConversationIncludeFilter() {
    _descriptionText.text = 'Show conversations with all these tags ▹';
  }
}

class ConversationExcludeFilter extends ConversationFilter {
  ConversationExcludeFilter() {
    _descriptionText.text = 'Hide conversations with any of these tags ▹';
  }
}

class ConversationTurnsFilter extends ConversationFilter{
  ConversationTurnsFilter() : super () {
    _descriptionText.text = 'Show conversations with all these last inbound turn tags ▹';
  }
}

class ConversationIdFilter {
  DivElement conversationFilter;
  SpanElement _descriptionText;
  TextInputElement _idInput;

  ConversationIdFilter() {
    conversationFilter = new DivElement()
      ..classes.add('conversation-filter')
      ..classes.add('conversation-filter--id-filter');

    _descriptionText = new SpanElement()
      ..classes.add('conversation-filter__description')
      ..text = 'Filter by ID:';
    conversationFilter.append(_descriptionText);

    _idInput = new TextInputElement()
      ..classes.add('conversation-filter__input')
      ..placeholder = 'Enter conversation ID'
      ..onChange.listen((_) {
        _view.appController.command(UIAction.updateConversationIdFilter, new ConversationIdFilterData(_idInput.value));
      });
    conversationFilter.append(_idInput);
  }

  set filter(String text) => _idInput.value = text;

  void showFilter(bool show) {
    this.conversationFilter.classes.toggle('hidden', !show);
  }
}

class ConversationSummary with LazyListViewItem, UserPresenceIndicator {
  ConversationItemView _conversationItem;

  CheckboxInputElement _selectCheckbox;

  String deidentifiedPhoneNumber;
  String _text;
  DateTime _dateTime;
  bool _unread;
  bool _checked = false;
  bool _selected = false;
  bool _checkboxHidden = true;
  bool _warning = false;
  ConversationItemStatus _status;

  // HACK(mariana): This should get extracted from the model as it gets computed there for the single conversation view
  String get _shortDeidentifiedPhoneNumber => deidentifiedPhoneNumber.split('uuid-')[1].split('-')[0];
  ConversationReadStatus get readStatus => _unread ? ConversationReadStatus.unread : ConversationReadStatus.read;

  Map<String, bool> _presentUsers = {};

  ConversationSummary(this.deidentifiedPhoneNumber, this._text, this._unread, this._status, {DateTime dateTime}) {
    _dateTime = dateTime;
    otherUserPresenceIndicator = new DivElement()..classes.add('conversation-list__user-indicators')..classes.add('user-indicators');
  }

  Element buildElement() {
    _conversationItem = ConversationItemView(_shortDeidentifiedPhoneNumber, _text, _status, readStatus, checkEnabled: !_checkboxHidden, defaultSelected: _selected, dateTime: _dateTime)
      ..onCheck.listen((_) {
        _view.appController.command(UIAction.selectConversation, new ConversationData(deidentifiedPhoneNumber));
      })
      ..onUncheck.listen((_) {
        _view.appController.command(UIAction.deselectConversation, new ConversationData(deidentifiedPhoneNumber));
      })
      ..onSelect.listen((_) {
        _view.appController.command(UIAction.showConversation, new ConversationData(deidentifiedPhoneNumber));
      });

    if (_warning) {
      _conversationItem.setWarnings(Set.from([ConversationWarning.notInFilterResults]));
    }

    elementOrNull = _conversationItem.renderElement;
    return _conversationItem.renderElement;
  }

  @override
  void disposeElement() {
    if (_selectCheckbox != null) {
      _selectCheckbox.remove();
      _selectCheckbox = null;
    }
    super.disposeElement();
  }

  void _select() {
    _selected = true;
    _conversationItem?.select();
  }

  void _deselect() {
    _selected = false;
    _conversationItem?.unselect();
  }

  void _markRead() {
    _unread = false;
    _conversationItem?.markAsRead();
  }

  void _markUnread() {
    _unread = true;
    _conversationItem?.markAsUnread();
  }

  void _check() {
    _checked = true;
    _conversationItem?.check();
  }

  void _uncheck() {
    _checked = false;
    _conversationItem?.uncheck();
  }

  void _updateText(String text) {
    _text = text;
    _conversationItem?.updateMessage(text);
  }

  void _updateDateTime(DateTime dateTime) {
    _dateTime = dateTime;
    _conversationItem?.updateDateTime(_dateTime);
  }

  void _toggleDateSeparator(bool show) {
    _conversationItem?.toggleDateSeparator(show);
  }

  void _updateStatus(ConversationItemStatus status) {
    _status = status;
    _conversationItem?.updateStatus(status);
  }

  void _showCheckbox(bool show) {
    // todo: figure out this
    _checkboxHidden = !show;
    _conversationItem?.enableCheckbox(show);
  }

  void _showWarning(bool show) {
    _warning = show;
    if(show) {
      _conversationItem?.setWarnings(Set.from([ConversationWarning.notInFilterResults]));
    } else {
      _conversationItem?.resetWarnings();
    }
  }

  @override
  void hideOtherUserPresence(String userId) {
    super.hideOtherUserPresence(userId);
    if (_presentUsers.isEmpty) {
      otherUserPresenceIndicator.remove();
    }
  }

  @override
  void showOtherUserPresence(String userId, bool recent) {
    if (_presentUsers.isEmpty) {
      _conversationItem.conversationItem.append(otherUserPresenceIndicator);
    }
    super.showOtherUserPresence(userId, recent);
  }
}

class OtherLoggedInUsers with UserPresenceIndicator {
  DivElement loggedInUsers;

  OtherLoggedInUsers() {
    loggedInUsers = new DivElement()
      ..classes.add('header__other-users');

    otherUserPresenceIndicator = new DivElement()
      ..classes.add('user-indicators');

    loggedInUsers.append(otherUserPresenceIndicator);
  }

  @override
  void showOtherUserPresence(String userId, bool recent) {
    super.showOtherUserPresence(userId, recent);

    var userIndicator = otherUserPresenceIndicator.querySelector('[data-id="$userId"]');
    userIndicator.onClick.listen((event) => _view.appController.command(UIAction.goToUser, OtherUserData(userId)));
  }
}

class NotesPanelView {
  DivElement notesPanel;
  DivElement _notes;
  TextAreaElement _notesTextArea;

  NotesPanelView() {
    notesPanel = DivElement()
      ..classes.add('notes-panel');
    _notes = DivElement()
      ..classes.add('notes-box');

    _notesTextArea = TextAreaElement()
      ..classes.add('notes-box__textarea');
    _notes.append(_notesTextArea);

    notesPanel.append(_notes);
  }

  set noteText(String text) => _notesTextArea.value = text;

  void enableEditableNotes(bool enable) {
    // Just replace the notes HTML element with new one and call [makeEditable] on it, or disable it.
    var text = _notesTextArea.value;
    _notesTextArea.remove();
    _notesTextArea = new TextAreaElement()
      ..classes.add('notes-box__textarea')
      ..placeholder = "Notes..."
      ..value = text;
    if (enable) {
      makeEditable(_notesTextArea, onChange: (_) {
        _view.appController.command(UIAction.updateNote, new NoteData(_notesTextArea.value));
      });
    } else {
      _notesTextArea.disabled = true;
    }
    _notes.append(_notesTextArea);
  }
}

class TurnlinePanelView {
  DivElement turnlinePanel;

  TurnlinePanelView() {
    turnlinePanel = DivElement()
      ..classes.add('turnline-panel');
  }

  void set turnlines(List<tl.Turnline> value) {
    turnlinePanel.children.clear();
    for (var turnline in value) {
      turnlinePanel.append(turnline.renderElement);
    }
  }
}

class ReplyPanelView {
  DivElement replyPanel;
  DivElement _panelTitle;
  SelectElement _replyCategories;
  DivElement _replies;
  DivElement _replyList;
  AddActionView _addReply;
  List<ActionView> _replyViews;
  ScrollOverflowIndicator _repliesScrollContainer;

  ReplyPanelView() {
    replyPanel = new DivElement()
      ..classes.add('reply-panel');

    _panelTitle = new DivElement()
      ..classes.add('panel-title')
      ..classes.add('panel-title--multiple-cols');
    replyPanel.append(_panelTitle);

    _replyCategories = new SelectElement();
    _replyCategories.onChange.listen((_) => _view.appController.command(UIAction.updateSuggestedRepliesCategory, new UpdateSuggestedRepliesCategoryData(_replyCategories.value)));

    _panelTitle
      ..append(new DivElement()..text = REPLY_PANEL_TITLE)
      ..append(_replyCategories);

    _replies = new DivElement()
      ..classes.add('replies')
      ..classes.add('action-list');
    _repliesScrollContainer = ScrollOverflowIndicator();
    _repliesScrollContainer.setContent(_replies);
    replyPanel.append(_repliesScrollContainer.container);

    _replyList = new DivElement();
    _replies.append(_replyList);

    // TODO(mariana): support adding replies
    // _addReply = new AddReplyActionView(ADD_REPLY_INFO);
    // _replies.append(_addReply.addAction);

    _replyViews = [];
  }

  set selectedCategory(String category) {
    int index = _replyCategories.children.indexWhere((Element option) => (option as OptionElement).value == category);
    if (index == -1) {
      _view.showWarningStatus("Couldn't find $category in list of suggested replies category, using first");
      _replyCategories.selectedIndex = 0;
      _view.appController.command(UIAction.updateSuggestedRepliesCategory, new UpdateSuggestedRepliesCategoryData(_replyCategories.value));
      return;
    }
    _replyCategories.selectedIndex = index;
  }

  set categories(List<String> categories) {
    _replyCategories.children.clear();
    for (var category in categories) {
      _replyCategories.append(
        new OptionElement()
          ..value = category
          ..text = category);
    }
  }

  void addReply(ActionView action) {
    _replyViews.add(action);
    _replyList.append(action.action);
    _repliesScrollContainer.updateShadows();
  }

  void clear() {
    int repliesNo = _replyList.children.length;
    for (int i = 0; i < repliesNo; i++) {
      _replyList.firstChild.remove();
    }
    _replyViews.clear();
    assert(_replyList.children.length == 0);
  }

  void showShortcuts(bool show) {
    for (var view in _replyViews) {
      view.showShortcut(show);
    }
  }

  void showButtons(bool show) {
    for (var view in _replyViews) {
      view.showButtons(show);
    }
  }

  void disableReplies() {
    _replies.remove();
    _panelTitle
      ..children.clear()
      ..append(new DivElement()..text = NOTES_PANEL_TITLE);
  }

  void enableReplies() {
    _panelTitle
      ..children.clear()
      ..append(new DivElement()..text = REPLY_PANEL_TITLE)
      ..append(_replyCategories);
    replyPanel.append(_replies);
  }

}

class TagGroupView extends AccordionItem {
  String _groupName;
  DivElement _header;
  DivElement _body;
  DivElement _tagsContainer;
  Map<String, TagView> tagViewsById;

  TagGroupView(String id, this._groupName, this._header, this._body) : super(id, _header, _body, false) {
    _groupName = _groupName ?? '';

    var groupName = DivElement()..innerText = _groupName;
    _header.append(groupName);

    _tagsContainer = DivElement()..classes.add('tags-group__tags');
    _body.append(_tagsContainer);
    tagViewsById = {};
  }

  void addTags(Map<String, TagView> tags) {
    for (var tag in tags.keys) {
      _tagsContainer.append(tags[tag].renderElement);
      tagViewsById[tag] = tags[tag];
    }
  }
}

class TagPanelView {
  DivElement tagPanel;
  DivElement _instruction;
  Accordion _tagGroups;
  DivElement _statusPanel;
  Text _statusText;

  TagPanelView() {
    tagPanel = new DivElement()
      ..classes.add('tag-panel');

    var panelTitle = new DivElement()
      ..classes.add('panel-title');
    tagPanel.append(panelTitle);

    _instruction = new DivElement()
      ..classes.add('panel-instruction')
      ..text = "Select a conversation or a message to tag";
    panelTitle.append(_instruction);

    _tagGroups = Accordion([]);
    tagPanel.append(_tagGroups.renderElement);

    _statusPanel = new DivElement();
    _statusText = new Text('loading...');
    tagPanel.append(_statusPanel
      ..classes.add('status-line')
      ..append(_statusText));
  }

  void addTagGroup(TagGroupView tagGroupView) {
    _tagGroups.appendItem(tagGroupView);
  }

  void clear() {
    _tagGroups.clear();
  }

  void enableTagging(bool messageEnabled, bool conversationEnabled, bool selected) {
    if (!messageEnabled && !conversationEnabled) {
      _instruction.innerText = "You do not have permissions to tag messages or conversations. Please contact your admin.";
      return;
    }

    if (selected) {
      _instruction.innerText = "Click to add the tag to the selected conversation or message";
    } else {
      _instruction.innerText = "Select a conversation or a message to tag";
    }
  }
}

abstract class ActionView {
  DivElement action;
  void showShortcut(bool show);
  void showButtons(bool show);
}

class ReplyActionView implements ActionView {
  DivElement action;
  DivElement _shortcutElement;
  DivElement _textElement;
  DivElement _translationElement;
  List<DivElement> _buttonElements;

  String _text;
  String _translation;

  String get text => _text;
  String get translation => _translation;

  ReplyActionView(this._text, this._translation, String shortcut, String replyId, String buttonText) {
    action = new DivElement()
      ..classes.add('action')
      ..dataset['id'] = "${replyId}";

    _shortcutElement = new DivElement()
      ..classes.add('action__shortcut')
      ..text = shortcut;
    action.append(_shortcutElement);

    var textTranslationWrapper = new DivElement()
      ..style.flex = '1 1 auto';
    action.append(textTranslationWrapper);

    _buttonElements = [];

    { // Add text
      var textWrapper = new DivElement()
        ..classes.add('action__description');
      textTranslationWrapper.append(textWrapper);

      _textElement = new DivElement()
        ..classes.add('action__text')
        ..text = _text;
      textWrapper.append(_textElement);

      var buttonElement = new DivElement()
        ..classes.add('action__button')
        ..classes.add('action__button--float')
        ..text = '$buttonText (${controller.projectConfiguration["firstLanguage"] ?? "lang 1"})';
      buttonElement.onClick.listen((_) => _view.appController.command(UIAction.sendMessage, new ReplyData(replyId)));
      buttonElement.onMouseEnter.listen((event) => highlightText(true));
      buttonElement.onMouseLeave.listen((event) => highlightText(false));
      if (_text.isNotEmpty) {
        textWrapper.append(buttonElement);
        _buttonElements.add(buttonElement);
      } else {
        _textElement
          ..classes.add('action__text--placeholder')
          ..text = 'No message text provided';
      }
    }

    { // Add translation
      var translationWrapper = new DivElement()
        ..classes.add('action__description');
      textTranslationWrapper.append(translationWrapper);

      _translationElement = new DivElement()
        ..classes.add('action__translation')
        ..text = _translation;
      translationWrapper.append(_translationElement);

      var buttonElement = new DivElement()
        ..classes.add('action__button')
        ..classes.add('action__button--float')
        ..text = '$buttonText (${controller.projectConfiguration["secondLanguage"] ?? "lang 2"})';
      buttonElement.onClick.listen((_) => _view.appController.command(UIAction.sendMessage, new ReplyData(replyId, replyWithTranslation: true)));
      buttonElement.onMouseEnter.listen((event) => highlightTranslation(true));
      buttonElement.onMouseLeave.listen((event) => highlightTranslation(false));
      if (_translation.isNotEmpty) {
        translationWrapper.append(buttonElement);
        _buttonElements.add(buttonElement);
      } else {
        _translationElement
          ..classes.add('action__text--placeholder')
          ..text = 'No message translation provided';
      }
    }
  }

  void showShortcut(bool show) {
    _shortcutElement.classes.toggle('hidden', !show);
  }

  void showButtons(bool show) {
    _buttonElements.forEach((button) => button.classes.toggle('hidden', !show));
  }

  void highlightText(bool highlight) {
    _textElement.classes.toggle('action__text--bold', highlight);
  }

  void fadeText(bool fade) {
    _textElement.classes.toggle('action__text--faded', fade);
  }

  void highlightTranslation(bool highlight) {
    _translationElement.classes.toggle('action__translation--bold', highlight);
  }
}

class ReplyActionGroupView implements ActionView {
  DivElement action;
  List<DivElement> _buttonElements;
  List<ReplyActionView> replies;

  ReplyActionGroupView(String groupId, String groupDescription, String buttonText, this.replies) {
    action = new DivElement()
      ..classes.add('action')
      ..classes.add('action--group')
      ..dataset['id'] = groupId;

    var textWrapper = new DivElement()
      ..classes.add('action__group__description');
    action.append(textWrapper);

    var textElement = new DivElement()
      ..classes.add('action__group__text')
      ..text = groupDescription;
    textWrapper.append(textElement);

    _buttonElements = [];

    var buttonGroup = new DivElement()
      ..classes.add('action__group__buttons');
    textWrapper.append(buttonGroup);

    var sendButton = new DivElement()
      ..classes.add('action__button')
      ..classes.add('action__button--flex')
      ..text = '$buttonText (${controller.projectConfiguration["firstLanguage"] ?? "lang 1"})';
    sendButton.onClick.listen((_) => _view.appController.command(UIAction.sendMessageGroup, new GroupReplyData(groupId)));
    sendButton.onMouseEnter.listen((event) {
      sendButton.scrollIntoView(); // this is to stabilize the view around the button
      replies.forEach((reply) => reply.highlightText(true));
    });
    sendButton.onMouseLeave.listen((event) => replies.forEach((reply) => reply.highlightText(false)));
    var emptyTexts = replies.any((reply) => reply.text.isEmpty);
    if (!emptyTexts) {
      buttonGroup.append(sendButton);
      _buttonElements.add(sendButton);
    }

    var sendTranslationButton = new DivElement()
      ..classes.add('action__button')
      ..classes.add('action__button--flex')
      ..text = '$buttonText (${controller.projectConfiguration["secondLanguage"] ?? "lang 2"})';
    sendTranslationButton.onClick.listen((_) => _view.appController.command(UIAction.sendMessageGroup, new GroupReplyData(groupId, replyWithTranslation: true)));
    sendTranslationButton.onMouseEnter.listen((event) {
      sendTranslationButton.scrollIntoView(); // this is to stabilize the view around the button
      replies.forEach((reply) => reply.highlightTranslation(true));
    });
    sendTranslationButton.onMouseLeave.listen((event) => replies.forEach((reply) => reply.highlightTranslation(false)));
    var emptyTranslations = replies.any((reply) => reply.translation.isEmpty);
    if (!emptyTranslations) {
      buttonGroup.append(sendTranslationButton);
      _buttonElements.add(sendTranslationButton);
    }

    var repliesWrapper = new DivElement()
      ..classes.add('action__group__wrapper');
    for (var reply in replies) {
      repliesWrapper.append(reply.action);
    }
    action.append(repliesWrapper);
  }

  void showShortcut(bool show) {
    for (var reply in replies) {
      reply.showShortcut(show);
    }
  }

  void showButtons(bool show) {
    _buttonElements.forEach((button) => button.classes.toggle('hidden', !show));
  }

  void showButtonsRecursive(bool show) {
    _buttonElements.forEach((button) => button.classes.toggle('hidden', !show));
    for (var reply in replies) {
      reply.showButtons(show);
    }
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
      ..text = '';
    makeEditable(_newActionTextArea);
    _newActionBox.append(_newActionTextArea);

    _newActionTranslationLabel = new DivElement()
      ..text = 'Translation:'
      ..classes.add('add-action__translation-label');
    _newActionBox.append(_newActionTranslationLabel);

    _newActionTranslation = new DivElement()
      ..classes.add('add-action__translation');
    makeEditable(_newActionTranslation);
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

class ChangeSortOrderActionView {
  DivElement renderElement;
  SelectElement _selectOrder;

  ChangeSortOrderActionView() {
    renderElement = DivElement();
    _selectOrder = SelectElement()
      ..className = "conversation-sort-order__select"
      ..append(OptionElement(value: 'most_recent_message', data: 'Recent message'))
      ..append(OptionElement(value: 'most_recent_inbound', data: 'Recent inbound message', selected: true))
      ..append(OptionElement(value: 'alphabetically', data: 'Conversation ID alphabetically'))
      ..onChange.listen(_changeSortOrder);
    renderElement.append(SpanElement()..className = "fas fa-sort-amount-down");
    renderElement.append(_selectOrder);
  }

  void _changeSortOrder(Event e) {
    switch ((e.currentTarget as SelectElement).value) {
      case 'alphabetically':
        _view.appController.command(UIAction.changeConversationSortOrder, ConversationSortOrderData(UIConversationSort.alphabeticalById));
        break;
      case 'most_recent_message':
        _view.appController.command(UIAction.changeConversationSortOrder, ConversationSortOrderData(UIConversationSort.mostRecentMessageFirst));
        break;
      case 'most_recent_inbound':
      default:
        _view.appController.command(UIAction.changeConversationSortOrder, ConversationSortOrderData(UIConversationSort.mostRecentInMessageFirst));
        break;
    }
  }

  void updateSelectElement(UIConversationSort sortOrder) {
    switch (sortOrder) {
      case UIConversationSort.mostRecentInMessageFirst:
        _selectOrder.selectedIndex = 1;
        break;
      case UIConversationSort.alphabeticalById:
        _selectOrder.selectedIndex = 2;
        break;
      case UIConversationSort.mostRecentMessageFirst:
      default:
        _selectOrder.selectedIndex = 0;
        break;
    }
  }
}

class HelpIndicatorTooltip {
  DivElement renderElement;

  HelpIndicatorTooltip(String tooltip, TooltipPosition position) {
    var questionIcon = SpanElement()..className = "fas fa-info";
    var tooltip = Tooltip(questionIcon, "This tag cannot be removed from the filter. Please contact your admin if you have any questions.", position: position);
    renderElement = tooltip.renderElement..classes.add("tag-tooltip");
  }
}
