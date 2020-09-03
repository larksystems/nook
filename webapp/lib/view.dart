import 'dart:async';
import 'dart:html';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:svg' as svg;

import 'package:intl/intl.dart';

import 'controller.dart';
import 'dom_utils.dart';
import 'logger.dart';
import 'model.dart';
import 'lazy_list_view_model.dart';


Logger log = new Logger('view.dart');

ConversationListSelectHeader conversationListSelectView;
ConversationListPanelView conversationListPanelView;
ConversationIdFilter conversationIdFilter;
Map<TagFilterType, ConversationFilter> conversationFilter;
ConversationPanelView conversationPanelView;
ReplyPanelView replyPanelView;
TagPanelView tagPanelView;
AuthHeaderView authHeaderView;
AuthMainView authMainView;
UrlView urlView;
SnackbarView snackbarView;
BannerView bannerView;

void init() {
  conversationListSelectView = new ConversationListSelectHeader();
  conversationListPanelView = new ConversationListPanelView();
  conversationPanelView = new ConversationPanelView();
  replyPanelView = new ReplyPanelView();
  tagPanelView = new TagPanelView();
  authHeaderView = new AuthHeaderView();
  authMainView = new AuthMainView();
  urlView = new UrlView();
  snackbarView = new SnackbarView();
  bannerView = new BannerView();

  conversationFilter = {
    TagFilterType.include: conversationListPanelView.conversationIncludeFilter,
    TagFilterType.exclude: conversationListPanelView.conversationExcludeFilter,
    TagFilterType.lastInboundTurn: conversationListPanelView.conversationTurnsFilter
  };
  conversationIdFilter = conversationListPanelView.conversationIdFilter;

  querySelector('header')
      ..insertAdjacentElement('beforeBegin', bannerView.bannerElement)
      ..append(conversationListSelectView.panel)
      ..append(authHeaderView.authElement);

  document.onKeyDown.listen(
    (event) => command(UIAction.keyPressed,
                       new KeyPressData(event.key, event.altKey || event.ctrlKey || event.metaKey || event.shiftKey)));
}

void initSignedInView() {
  clearMain();

  querySelector('main')
    ..append(conversationListPanelView.conversationListPanel)
    ..append(conversationPanelView.conversationPanel)
    ..append(replyPanelView.replyPanel)
    ..append(tagPanelView.tagPanel)
    ..append(snackbarView.snackbarElement);
  showNormalStatus('signed in');

  HttpRequest.getString('assets/latest_commit_hash.json').then((latestCommitHashConfigJson) {
    var latestCommitHash = (json.decode(latestCommitHashConfigJson) as Map)['latestCommitHash'];
    showNormalStatus('signed in: ${latestCommitHash.substring(0, 8)}...');
  }, onError: (_) { /* Do nothing */ });
}

void initSignedOutView() {
  conversationListSelectView.panel.style.visibility = 'hidden';
  clearMain();

  querySelector('main').append(authMainView.authElement);
  showNormalStatus('signed out');
}

void clearMain() {
  conversationListPanelView.conversationListPanel.remove();
  conversationPanelView.conversationPanel.remove();
  replyPanelView.replyPanel.remove();
  tagPanelView.tagPanel.remove();
  authMainView.authElement.remove();
  snackbarView.snackbarElement.remove();
}

var layouts = {
  'true-true':   {"conversationListPanel": "w-20", "conversationPanel": "w-40", "replyPanel": "w-25", "tagPanel": "w-15"},
  'true-false':  {"conversationListPanel": "w-25", "conversationPanel": "w-45", "replyPanel": "w-30", "tagPanel": "w-0" },
  'false-true':  {"conversationListPanel": "w-30", "conversationPanel": "w-50", "replyPanel": "w-0" , "tagPanel": "w-20"},
  'false-false': {"conversationListPanel": "w-35", "conversationPanel": "w-65", "replyPanel": "w-0" , "tagPanel": "w-0" },
};

var layout = ['1', '1'];

void showPanels(showReplyPanel, showTagPanel) {
  replyPanelView.replyPanel.classes.toggle('hidden', !showReplyPanel);
  tagPanelView.tagPanel.classes.toggle('hidden', !showTagPanel);

  String layoutKey = '$showReplyPanel-$showTagPanel';

  // Remove previous w-* classes
  conversationListPanelView.conversationListPanel.classes.removeWhere((element) => element.startsWith('w-'));
  conversationPanelView.conversationPanel.classes.removeWhere((element) => element.startsWith('w-'));
  replyPanelView.replyPanel.classes.removeWhere((element) => element.startsWith('w-'));
  tagPanelView.tagPanel.classes.removeWhere((element) => element.startsWith('w-'));

  // Set the classes based on the new layout
  conversationListPanelView.conversationListPanel.classes.toggle(layouts[layoutKey]['conversationListPanel'], true);
  conversationPanelView.conversationPanel.classes.toggle(layouts[layoutKey]['conversationPanel'], true);
  replyPanelView.replyPanel.classes.toggle(layouts[layoutKey]['replyPanel'], true);
  tagPanelView.tagPanel.classes.toggle(layouts[layoutKey]['tagPanel'], true);
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

void showNormalStatus(String text) {
  tagPanelView._statusText.text = text;
  tagPanelView._statusPanel.classes.remove('status-line-warning');
}

void showWarningStatus(String text) {
  tagPanelView._statusText.text = text;
  tagPanelView._statusPanel.classes.add('status-line-warning');
}

void makeEditable(Element element, {void onChange(), void onEnter()}) {
  element
    ..contentEditable = 'true'
    ..onBlur.listen((e) {
      if (onChange != null) onChange();
      e.stopPropagation();
    })
    ..onKeyDown.listen((e) => e.stopPropagation())
    ..onKeyUp.listen((e) => e.stopPropagation())
    ..onKeyPress.listen((e) {
      e.stopPropagation();
      if (onEnter != null && e.keyCode == KeyCode.ENTER) {
        e.stopImmediatePropagation();
        onEnter();
      }
    });
}

const REPLY_PANEL_TITLE = 'Suggested responses';
const TAG_PANEL_TITLE = 'Tags';
const ADD_REPLY_INFO = 'Add new suggested response';
const ADD_TAG_INFO = 'Add new tag';
const MARK_UNREAD_INFO = 'Mark unread';
const MARK_SELECTED_UNREAD_INFO = 'Mark selected unread';

class ConversationPanelView {
  // HTML elements
  DivElement conversationPanel;
  DivElement _messages;
  DivElement _conversationWarning;
  DivElement _conversationId;
  DivElement _conversationIdCopy;
  DivElement _info;
  DivElement _tags;
  DivElement _newMessageBox;
  TextAreaElement _newMessageTextArea;
  AfterDateFilterView _afterDateFilterView;

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
    conversationSummary.append(_info);

    _tags = new DivElement()
      ..classes.add('conversation-summary__tags');
    conversationSummary.append(_tags);

    _messages = new DivElement()
      ..classes.add('messages');
    conversationPanel.append(_messages);

    _newMessageBox = new DivElement()
      ..classes.add('new-message-box');
    conversationPanel.append(_newMessageBox);

    _newMessageTextArea = new TextAreaElement()
      ..classes.add('new-message-box__textarea');
    makeEditable(_newMessageTextArea, onChange: () {
      if (_newMessageTextArea.value.length >= SMS_MAX_LENGTH) {
        _newMessageTextArea.classes.toggle('warning-background', true);
        return;
      }
      _newMessageTextArea.classes.toggle('warning-background', false);
    });
    _newMessageBox.append(_newMessageTextArea);

    var buttonElement = new DivElement()
      ..classes.add('new-message-box__send-button')
      ..text = SEND_REPLY_BUTTON_TEXT
      ..onClick.listen((_) {
        if (_newMessageTextArea.value.length >= SMS_MAX_LENGTH) {
          showWarningStatus('Message needs to be under $SMS_MAX_LENGTH characters.');
          return;
        }
        command(UIAction.sendManualMessage, new ManualReplyData(_newMessageTextArea.value));
      });
    _newMessageBox.append(buttonElement);

    _afterDateFilterView = AfterDateFilterView();
    conversationPanel.append(_afterDateFilterView.panel);
  }

  set deidentifiedPhoneNumber(String deidentifiedPhoneNumber) => _conversationIdCopy.dataset['copy-value'] = deidentifiedPhoneNumber;
  set deidentifiedPhoneNumberShort(String deidentifiedPhoneNumberShort) => _conversationId.text = deidentifiedPhoneNumberShort;
  set demographicsInfo(String demographicsInfo) => _info.text = demographicsInfo;

  void addMessage(MessageView message) {
    _messages.append(message.message);
    _messageViews.add(message);
    message.message.scrollIntoView();
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
      MessageView message = new MessageView('', DateTime.now(), '', i);
      _messages.append(message.message);
      _messageViews.add(message);
    }
  }

  void updateMessage(MessageView message, int index) {
    if (index >= _messageViews.length) {
      _messages.append(message.message);
      _messageViews.add(message);
      return;
    }
    _messages.children[index] = message.message;
    _messageViews[index] = message;
  }

  void addTags(TagView tag) {
    _tags.append(tag.tag);
  }

  void removeTag(String tagId) {
    _tags.children.removeWhere((Element d) => d.dataset["id"] == tagId);
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

  MessageView messageViewAtIndex(int index) {
    return _messageViews[index];
  }

  void clear() {
    _conversationId.text = '';
    _conversationIdCopy.dataset['copy-value'] = '';
    _info.text = '';
    _messageViews = [];
    removeTags();
    clearNewMessageBox();
    clearWarning();

    int messagesNo = _messages.children.length;
    for (int i = 0; i < messagesNo; i++) {
      _messages.firstChild.remove();
    }
  }

  void clearNewMessageBox() {
    _newMessageTextArea?.value = '';
  }

  void showCustomMessageBox(bool show) {
    if (show) {
      _newMessageBox.classes.remove('hidden');
    } else {
      _newMessageBox.classes.add('hidden');
    }
  }

  void enableEditableTranslations(bool enable) {
    for (var messageView in _messageViews) {
      messageView.enableEditableTranslations(enable);
    }
  }

  void showAfterDateFilterPrompt(TagFilterType filterType, DateTime dateTime) {
    _afterDateFilterView.showPrompt(filterType, dateTime);
  }

  void showWarning(String explanation) {
    _conversationWarning.title = explanation;
    _conversationWarning.classes.remove('hidden');
  }

  void clearWarning() {
    _conversationWarning.title = '';
    _conversationWarning.classes.add('hidden');
  }
}

class AfterDateFilterView {
  DivElement panel;
  TextAreaElement _textArea;

  TagFilterType _currentFilterType;

  AfterDateFilterView() {
    _textArea = new TextAreaElement()
      ..classes.add('after-date-prompt__textarea');
    makeEditable(_textArea, onEnter: () => applyFilter());

    panel = DivElement()
      ..classes.add('after-date-prompt')
      ..append(SpanElement()
        ..classes.add('after-date-prompt__prompt-text')
        ..text = 'Enter "after date" filter as yyyy-mm-dd hh:')
      ..append(_textArea)
      ..append(_addButton('Apply')..onClick.listen(applyFilter))
      ..append(_addButton('Cancel')..onClick.listen(hidePrompt));
  }

  DivElement _addButton(String text) {
    return DivElement()
      ..classes.add('after-date-prompt__button')
      ..append(SpanElement()
        ..classes.add('after-date-prompt__button-text')
        ..text = text);
  }

  void showPrompt(TagFilterType filterType, DateTime dateTime) {
    _currentFilterType = filterType;
    dateTime ??= DateTime.now();
    // TODO populate the fields with dateTime
    panel.classes.add('after-date-prompt__visible');
    _textArea
      ..text = _afterDateFilterFormat.format(dateTime)
      ..setSelectionRange(5, _textArea.text.length)
      ..focus();
  }

  void applyFilter([_]) {
    DateTime dateTime;
    try {
      dateTime = parseAfterDateFilterText(_textArea.value);
    } on FormatException catch (e) {
      command(UIAction.showSnackbar, new SnackbarData("Invalid date/time format: ${e.message}", SnackbarNotificationType.error));
      return;
    }
    command(UIAction.updateAfterDateFilter, new AfterDateFilterData(AFTER_DATE_TAG_ID, _currentFilterType, dateTime));
    hidePrompt();
  }

  void hidePrompt([_]) {
    panel.classes.remove('after-date-prompt__visible');
    _currentFilterType = null;
  }

  DateTime parseAfterDateFilterText(String text) {
    text = text.trim();
    if (text.length < 4) throw FormatException('Expected 4 digit year');
    int year = int.tryParse(text.substring(0, 4));
    if (year == null) throw FormatException('Invalid 4 digit year');
    int index = 4;

    int nextGroup() {
      while (true) {
        if (index == text.length) return null;
        var ch = text.codeUnitAt(index);
        if (0x30 <= ch && ch <= 0x39) break;
        ++index;
      }
      int end = index + 1;
      if (end < text.length) {
        var ch = text.codeUnitAt(index);
        if (0x30 <= ch && ch <= 0x39) ++end;
      }
      var value = int.tryParse(text.substring(index, end));
      index = end;
      return value;
    }

    int month = nextGroup() ?? 1;
    int day = nextGroup() ?? 1;
    int hour = nextGroup() ?? 12;
    return new DateTime(year, month, day, hour);
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

  MessageView(String text, DateTime dateTime, String conversationId, int messageIndex, {String translation = '', bool incoming = true, List<TagView> tags = const[], MessageStatus status = null}) {
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
      ..text = translation;
    _messageBubble.append(_messageTranslation);

    _messageTags = new DivElement()
      ..classes.add('message__tags');
    tags.forEach((tag) => _messageTags.append(tag.tag));
    message.append(_messageTags);

    setStatus(status);
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

  void setStatus(MessageStatus status) {
    // TODO handle more types of status

    if (status == MessageStatus.pending)
      message.classes.add('message--pending');
    else
      message.classes.remove('message--pending');

    if (status == MessageStatus.failed)
      message.classes.add('message--failed');
    else
      message.classes.remove('message--failed');
  }

  void enableEditableTranslations(bool enable) {
    // Just replace the translation HTML element with new one and call [makeEditable] on it if editable.
    String translation = _messageTranslation.text;
    _messageTranslation.remove();
    _messageTranslation = new DivElement()
      ..classes.add('message__translation')
      ..text = translation;
    if (enable) {
      makeEditable(_messageTranslation, onChange: () {
        command(UIAction.updateTranslation,
                new TranslationData(
                    _messageTranslation.text,
                    message.dataset['conversationId'],
                    int.parse(message.dataset['messageIndex'])));
      });
    }
    _messageBubble.append(_messageTranslation);
  }
}

final DateFormat _dateFormat = new DateFormat('E d MMM y');
final DateFormat _dateFormatNoYear = new DateFormat('E d MMM');
final DateFormat _hourFormat = new DateFormat('HH:mm');

String _formatDateTime(DateTime dateTime) {
  DateTime now = DateTime.now();
  return dateTime.toIso8601String(); // HACK(mariana): Temporary fix to have a sortable timestamp for each message
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
      ..text = text
      ..title = text;
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
  TagFilterType _filterType;
  FilterMenuTagView(String text, String tagId, TagStyle tagStyle, TagFilterType filterType) : super(text, tagId, tagStyle) {
    _removeButton.remove();
    _tagText
      ..classes.add('clickable')
      ..onClick.listen((_) {
        handleClicked(tagId);
      });
    _filterType = filterType;
  }

  void handleClicked(String tagId) {
    command(UIAction.addFilterTag, new FilterTagData(tagId, _filterType));
  }
}

class FilterTagView extends TagView {
  TagFilterType _filterType;
  FilterTagView(String text, String tagId, TagStyle tagStyle, TagFilterType filterType) : super(text, tagId, tagStyle) {
    _removeButton.onClick.listen((_) => handleClicked(tagId));
    _filterType = filterType;
  }

  void handleClicked(String tagId) {
    command(UIAction.removeFilterTag, new FilterTagData(tagId, _filterType));
  }
}

const AFTER_DATE_TAG_ID = "after-date";
final DateFormat _afterDateFilterFormat = DateFormat('yyyy.MM.dd HH:mm');

class AfterDateFilterMenuTagView extends FilterMenuTagView {
  AfterDateFilterMenuTagView(TagFilterType filterType) : super("after date", AFTER_DATE_TAG_ID, TagStyle.None, filterType);

  @override
  void handleClicked(String tagId) {
    command(UIAction.promptAfterDateFilter, new AfterDateFilterData(tagId, _filterType));
  }
}

class AfterDateFilterTagView extends FilterTagView {
  AfterDateFilterTagView(DateTime dateTime, TagFilterType filterType) : super(filterText(dateTime), AFTER_DATE_TAG_ID, TagStyle.None, filterType);

  static String filterText(DateTime dateTime) {
    return "after date ${_afterDateFilterFormat.format(dateTime)}";
  }

  @override
  void handleClicked(String tagId) {
    command(UIAction.updateAfterDateFilter, new AfterDateFilterData(tagId, _filterType, null));
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
      ..style.visibility = 'hidden';

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
        conversationListSelectView.panel.style.visibility = 'visible';
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
    command(UIAction.selectConversationList, ConversationListData(_selectElement.value));
  }

  void selectShard(String shard) {
    _selectElement.value = shard;
  }
}

class ConversationListPanelView {
  DivElement conversationListPanel;
  DivElement _conversationPanelTitle;
  MarkUnreadActionView _markUnread;
  LazyListViewModel _conversationList;
  CheckboxInputElement _selectAllCheckbox;
  DivElement _loadSpinner;
  DivElement _selectConversationListMessage;

  ConversationIdFilter conversationIdFilter;
  ConversationIncludeFilter conversationIncludeFilter;
  ConversationExcludeFilter conversationExcludeFilter;
  ConversationTurnsFilter conversationTurnsFilter;

  Map<String, ConversationSummary> _phoneToConversations = {};
  ConversationSummary activeConversation;

  int _totalConversations = 0;
  void set totalConversations(int v) {
    _totalConversations = v;
    _conversationPanelTitle.text = _conversationPanelTitleText;
  }
  String get _conversationPanelTitleText => '${_phoneToConversations.length}/${_totalConversations} conversations';

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
      ..onClick.listen((_) => _selectAllCheckbox.checked ? command(UIAction.selectAllConversations, null) : command(UIAction.deselectAllConversations, null));
    panelHeader.append(_selectAllCheckbox);

    _conversationPanelTitle = new DivElement()
      ..classes.add('panel-title')
      ..classes.add('conversation-list-header__title')
      ..text = _conversationPanelTitleText;
    panelHeader.append(_conversationPanelTitle);

    _markUnread = MarkUnreadActionView();
    panelHeader.append(new DivElement()
      ..classes.add('conversation-list-header__mark-unread')
      ..append(_markUnread.markUnreadAction));

    _loadSpinner = new DivElement()
      ..classes.add('load-spinner');
    conversationListPanel.append(_loadSpinner);

    _selectConversationListMessage = new DivElement()
      ..classes.add('select-conversation-list-message')
      ..append(SpanElement()..text = "Select a conversation list above")
      ..hidden = true;
    conversationListPanel.append(_selectConversationListMessage);

    var conversationListElement = new DivElement()
      ..classes.add('conversation-list');
    _conversationList = new LazyListViewModel(conversationListElement);
    conversationListPanel.append(conversationListElement);

    conversationIdFilter = new ConversationIdFilter();
    conversationListPanel.append(conversationIdFilter.conversationFilter);

    conversationIncludeFilter = new ConversationIncludeFilter();
    conversationListPanel.append(conversationIncludeFilter.conversationFilter);

    conversationExcludeFilter = new ConversationExcludeFilter();
    conversationListPanel.append(conversationExcludeFilter.conversationFilter);

    conversationTurnsFilter = new ConversationTurnsFilter();
    conversationListPanel.append(conversationTurnsFilter.conversationFilter);
  }

  void updateConversationList(Set<Conversation> conversations) {
    Set<String> uuidSets = Set<String>();
    for (Conversation c in conversations) {
      uuidSets.add(c.docId);
    }
    _phoneToConversations.removeWhere((String uuid, ConversationSummary summary) {
      if (uuidSets.contains(uuid)) return false;
      _conversationList.removeItem(summary);
      return true;
    });
    List<ConversationSummary> conversationsToAdd = [];
    for (var conversation in conversations) {
      ConversationSummary summary = _phoneToConversations[conversation.docId];
      if (summary != null) {
        updateConversationSummary(summary, conversation);
        continue;
      }
      summary = new ConversationSummary(
          conversation.docId,
          conversation.messages.first.text,
          conversation.unread);
      conversationsToAdd.add(summary);
    }
    _conversationList.appendItems(conversationsToAdd);
    for (var conversation in conversationsToAdd) {
      _phoneToConversations[conversation.deidentifiedPhoneNumber] = conversation;
    }
    _conversationPanelTitle.text = _conversationPanelTitleText;
  }

  void addOrUpdateConversation(Conversation conversation) {
    ConversationSummary summary = _phoneToConversations[conversation.docId];
    if (summary != null) {
      updateConversationSummary(summary, conversation);
      return;
    }
    summary = new ConversationSummary(
        conversation.docId,
        conversation.messages.first.text,
        conversation.unread);
    _conversationList.addItem(summary, null);
    _phoneToConversations[summary.deidentifiedPhoneNumber] = summary;
    _conversationPanelTitle.text = _conversationPanelTitleText;
  }

  void updateConversationSummary(ConversationSummary summary, Conversation conversation) {
    conversation.unread ? summary._markUnread() : summary._markRead();
  }

  void selectConversation(String deidentifiedPhoneNumber) {
    activeConversation?._deselect();
    activeConversation = _phoneToConversations[deidentifiedPhoneNumber];
    activeConversation._select();
    _conversationList.selectItem(activeConversation);
    command(UIAction.markConversationRead, ConversationData(deidentifiedPhoneNumber));
  }

  void showWarning(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?._showWarning(true);
  }

  void clearWarning(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]?._showWarning(false);
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
    _markUnread.multiSelectMode(show);
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
  Map<String, List<FilterMenuTagView>> _tagGroups;
  Map<String, DivElement> _tagGroupsContainers;

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

    _tagGroupsContainers = {};
    _tagGroups = {};
  }

  void addMenuTag(FilterMenuTagView tag, String category) {
    _tagGroups.putIfAbsent(category, () => []).add(tag);
    _tagGroupsContainers.putIfAbsent(category, () {
      var newContainerTitle = new DivElement()
        ..classes.add('tags-menu__group-name')
        ..text = category;
      _tagsMenuWrapper.append(newContainerTitle);

      var newContainer = new DivElement()
        ..classes.add('tags-menu__container');
      _tagsMenuWrapper.append(newContainer);

      var separator = new DivElement()
        ..classes.add('tags-menu__group-separator');
      _tagsMenuWrapper.append(separator);

      newContainerTitle.onClick.listen((event) {
          newContainer.classes.toggle('hidden');
          newContainerTitle.classes.toggle('folded');
      });
      // Start off folded
      newContainer.classes.toggle('hidden', true);
      newContainerTitle.classes.toggle('folded', true);

      return newContainer;
    }).append(tag.tag);
    _tagGroupsContainers[category].style.display = 'block'; // briefly override any display settings to make sure we can compute getBoundingClientRect()
    List<num> widths = _tagGroupsContainers[category].querySelectorAll('.tag__name').toList().map((e) => e.getBoundingClientRect().width).toList();
    _tagGroupsContainers[category].style.display = ''; // clear inline display settings
    num avgGridWidth = widths.fold(0, (previousValue, width) => previousValue + width);
    avgGridWidth = avgGridWidth / widths.length;
    num colSpacing = 10;
    num minColWidth = math.min(avgGridWidth + 2 * colSpacing, 138);
    num containerWidth = _tagsMenuWrapper.getBoundingClientRect().width;
    num columnWidth = containerWidth / (containerWidth / minColWidth).floor() - colSpacing;
    _tagGroupsContainers[category].style.setProperty('grid-template-columns', 'repeat(auto-fill, ${columnWidth}px)');
  }

  void modifyMenuTag(FilterMenuTagView tag, String category) {
    int index = _tagGroups[category].indexWhere((t) => t.tag.dataset["id"] == tag.tag.dataset["id"]);
    _tagGroups[category][index].tag.remove();
    _tagGroups[category].removeAt(index);
    _tagGroups[category].insert(index, tag);
    _tagGroupsContainers[category].children.insert(index, tag.tag);
  }

  void removeMenuTag(FilterMenuTagView tag, String category) {
    int index = _tagGroups[category].indexWhere((t) => t.tag.dataset["id"] == tag.tag.dataset["id"]);
    _tagGroups[category][index].tag.remove();
    _tagGroups[category].removeAt(index);
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
  DivElement _descriptionText;
  TextInputElement _idInput;

  ConversationIdFilter() {
    conversationFilter = new DivElement()
      ..classes.add('conversation-filter')
      ..classes.add('conversation-filter--id-filter');

    _descriptionText = new DivElement()
      ..classes.add('conversation-filter__description')
      ..text = 'Filter by ID:';
    conversationFilter.append(_descriptionText);

    _idInput = new TextInputElement()
      ..classes.add('conversation-filter__input')
      ..placeholder = 'Enter conversation ID';
    makeEditable(_idInput, onChange: () {
      command(UIAction.updateConversationIdFilter, new ConversationIdFilterData(_idInput.value));
    });
    conversationFilter.append(_idInput);
  }

  set filter(String text) => _idInput.value = text;

  void showFilter(bool show) {
    this.conversationFilter.classes.toggle('hidden', !show);
  }
}

class ConversationSummary with LazyListViewItem {
  CheckboxInputElement _selectCheckbox;

  String deidentifiedPhoneNumber;
  String _text;
  bool _unread;
  bool _checked = false;
  bool _selected = false;
  bool _checkboxHidden = true;
  bool _warning = false;

  ConversationSummary(this.deidentifiedPhoneNumber, this._text, this._unread);

  Element buildElement() {
    var conversationSummary = new DivElement()
      ..classes.add('conversation-list__item');

    _selectCheckbox = new CheckboxInputElement()
      ..classes.add('conversation-selector')
      ..title = 'Select conversation'
      ..checked = _checked
      ..hidden = _checkboxHidden
      ..onClick.listen((_) => _selectCheckbox.checked ? command(UIAction.selectConversation, new ConversationData(deidentifiedPhoneNumber))
                                                      : command(UIAction.deselectConversation, new ConversationData(deidentifiedPhoneNumber)));
    conversationSummary.append(_selectCheckbox);

    var summaryMessage = new DivElement()
      ..classes.add('summary-message')
      ..dataset['id'] = deidentifiedPhoneNumber
      ..onClick.listen((_) => command(UIAction.showConversation, new ConversationData(deidentifiedPhoneNumber)));
    if (_selected) conversationSummary.classes.add('conversation-list__item--selected');
    if (_unread) conversationSummary.classes.add('conversation-list__item--unread');
    if (_warning) conversationSummary.classes.add('conversation-list__item--warning');
    summaryMessage
      ..append(
        new DivElement()
          ..classes.add('summary-message__id')
          ..text = _shortDeidentifiedPhoneNumber)
      ..append(
        new DivElement()
          ..classes.add('summary-message__text')
          ..text = _text);
    conversationSummary.append(summaryMessage);
    return conversationSummary;
  }

  // HACK(mariana): This should get extracted from the model as it gets computed there for the single conversation view
  String get _shortDeidentifiedPhoneNumber => deidentifiedPhoneNumber.split('uuid-')[1].split('-')[0];

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
    elementOrNull?.classes?.add('conversation-list__item--selected');
  }
  void _deselect() {
    _selected = false;
    elementOrNull?.classes?.remove('conversation-list__item--selected');
  }
  void _markRead() {
    _unread = false;
    elementOrNull?.classes?.remove('conversation-list__item--unread');
  }
  void _markUnread() {
    _unread = true;
    elementOrNull?.classes?.add('conversation-list__item--unread');
  }
  void _check() {
    _checked = true;
    if (_selectCheckbox != null) _selectCheckbox.checked = true;
  }
  void _uncheck() {
    _checked = false;
    if (_selectCheckbox != null) _selectCheckbox.checked = false;
  }
  void _showCheckbox(bool show) {
    _checkboxHidden = !show;
    if (_selectCheckbox != null) _selectCheckbox.hidden = !show;
  }
  void _showWarning(bool show) {
    _warning = show;
    elementOrNull?.classes?.toggle('conversation-list__item--warning', show);
  }
}

class ReplyPanelView {
  DivElement replyPanel;
  DivElement _panelTitle;
  SelectElement _replyCategories;
  DivElement _replies;
  DivElement _replyList;
  DivElement _notes;
  TextAreaElement _notesTextArea;

  AddActionView _addReply;
  List<ReplyActionView> _replyViews;

  ReplyPanelView() {
    replyPanel = new DivElement()
      ..classes.add('reply-panel');

    var _panelTitle = new DivElement()
      ..classes.add('panel-title')
      ..classes.add('panel-title--multiple-cols');
    replyPanel.append(_panelTitle);

    _replyCategories = new SelectElement();
    _replyCategories.onChange.listen((_) => command(UIAction.updateSuggestedRepliesCategory, new UpdateSuggestedRepliesCategoryData(_replyCategories.value)));

    _panelTitle
      ..append(new DivElement()..text = REPLY_PANEL_TITLE)
      ..append(_replyCategories);

    _replies = new DivElement()
      ..classes.add('replies')
      ..classes.add('action-list');
    replyPanel.append(_replies);

    _replyList = new DivElement();
    _replies.append(_replyList);

    // TODO(mariana): support adding replies
    // _addReply = new AddReplyActionView(ADD_REPLY_INFO);
    // _replies.append(_addReply.addAction);

    _notes = new DivElement()
      ..classes.add('notes-box');
    replyPanel.append(_notes);

    _notesTextArea = new TextAreaElement()
      ..classes.add('notes-box__textarea');
    _notes.append(_notesTextArea);

    _replyViews = [];
  }

  set noteText(String text) => _notesTextArea.value = text;

  set selectedCategory(String category) {
    int index = _replyCategories.children.indexWhere((Element option) => (option as OptionElement).value == category);
    if (index == -1) {
      showWarningStatus("Couldn't find $category in list of suggested replies category, using first");
      _replyCategories.selectedIndex = 0;
      command(UIAction.updateSuggestedRepliesCategory, new UpdateSuggestedRepliesCategoryData(_replyCategories.value));
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
    _panelTitle.children.clear();
    _panelTitle.text = 'Notes';
    _notes.classes.toggle('notes-box--fullscreen', true);
  }

  void enableReplies() {
    _panelTitle
      ..append(new DivElement()..text = REPLY_PANEL_TITLE)
      ..append(_replyCategories);
    replyPanel.insertBefore(_replies, _notes);
    _notes.classes.toggle('notes-box--fullscreen', false);
  }

  void enableEditableNotes(bool enable) {
    // Just replace the notes HTML element with new one and call [makeEditable] on it, or disable it.
    var text = _notesTextArea.value;
    _notesTextArea.remove();
    _notesTextArea = new TextAreaElement()
      ..classes.add('notes-box__textarea')
      ..value = text;
    if (enable) {
      makeEditable(_notesTextArea, onChange: () {
        command(UIAction.updateNote, new NoteData(_notesTextArea.value));
      });
    } else {
      _notesTextArea.disabled = true;
    }
    _notes.append(_notesTextArea);
  }
}

class TagPanelView {
  DivElement tagPanel;
  SelectElement _tagGroups;
  DivElement _tags;
  DivElement _tagList;
  DivElement _statusPanel;
  InputElement _hideTagsCheckbox;
  Text _statusText;

  AddActionView _addTag;
  List<TagActionView> _tagViews;

  TagPanelView() {
    tagPanel = new DivElement()
      ..classes.add('tag-panel');

    var panelTitle = new DivElement()
      ..classes.add('panel-title');
    tagPanel.append(panelTitle);

    _tagGroups = new SelectElement()
      ..onChange.listen((_) => command(UIAction.updateDisplayedTagsGroup, new UpdateTagsGroupData(_tagGroups.value)));

    _hideTagsCheckbox = new InputElement(type: 'checkbox')
      ..checked = true
      ..onChange.listen((_) => command(UIAction.hideAgeTags, new ToggleData(_hideTagsCheckbox.checked)));

    panelTitle
      ..append(_tagGroups)
      ..append(
        new DivElement()
          ..append(_hideTagsCheckbox)
          ..append(new SpanElement()..text = 'Hide demog tags'));

    _tags = new DivElement()
      ..classes.add('tags')
      ..classes.add('action-list');
    tagPanel.append(_tags);

    _tagList = new DivElement();
    _tags.append(_tagList);

    // TODO(mariana): support adding tags
    // _addTag = new AddTagActionView(ADD_TAG_INFO);
    // _tags.append(_addTag.addAction);

    _statusPanel = new DivElement();
    _statusText = new Text('loading...');
    tagPanel.append(_statusPanel
      ..classes.add('status-line')
      ..append(_statusText));

    _tagViews = [];
  }

  set selectedGroup(String group) {
    int index = _tagGroups.children.indexWhere((Element option) => (option as OptionElement).value == group);
    if (index == -1) {
      showWarningStatus("Couldn't find $group in list of tag groups, using first");
      _tagGroups.selectedIndex = 0;
      command(UIAction.updateDisplayedTagsGroup, new UpdateTagsGroupData(_tagGroups.value));
      return;
    }
    _tagGroups.selectedIndex = index;
  }

  set groups(List<String> groups) {
    _tagGroups.children.clear();
    for (var group in groups) {
      _tagGroups.append(
        new OptionElement()
          ..value = group
          ..text = group);
    }
  }

  void addTag(ActionView action) {
    _tagViews.add(action);
    _tagList.append(action.action);
  }

  void clear() {
    int tagsNo = _tagList.children.length;
    for (int i = 0; i < tagsNo; i++) {
      _tagList.firstChild.remove();
    }
    assert(_tagList.children.length == 0);
  }

  void showShortcuts(bool show) {
    for (var view in _tagViews) {
      view.showShortcut(show);
    }
  }

  void showButtons(bool show) {
    for (var view in _tagViews) {
      view.showButtons(show);
    }
  }
}

class ActionView {
  DivElement action;
  DivElement _shortcutElement;
  List<DivElement> _buttonElements;

  ActionView(String text, String shortcut, String actionId, String buttonText) {
    action = new DivElement()
      ..classes.add('action')
      ..dataset['id'] = actionId;

    _shortcutElement = new DivElement()
      ..classes.add('action__shortcut')
      ..text = shortcut;
    action.append(_shortcutElement);

    var textElement = new DivElement()
      ..classes.add('action__description')
      ..text = text;
    action.append(textElement);

    var buttonElement = new DivElement()
      ..classes.add('action__button')
      ..classes.add('action__button--float')
      ..text = buttonText;
    action.append(buttonElement);
    _buttonElements = [buttonElement];
  }

  void showShortcut(bool show) {
    if (show) {
      _shortcutElement.classes.remove('hidden');
    } else {
      _shortcutElement.classes.add('hidden');
    }
  }

  void showButtons(bool show) {
    if (show) {
      _buttonElements.forEach((element) => element.classes.remove('hidden'));
    } else {
      _buttonElements.forEach((element) => element.classes.add('hidden'));
    }
  }
}

class ReplyActionView extends ActionView {

  ReplyActionView(String text, String translation, String shortcut, int replyIndex, String buttonText) : super(text, shortcut, '$replyIndex', buttonText) {
    action.children.clear();

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
        ..style.position = 'relative';
      textTranslationWrapper.append(textWrapper);

      var descriptionElement = new DivElement()
        ..classes.add('action__description');
      textWrapper.append(descriptionElement);

      var textElement = new DivElement()
        ..classes.add('action__text')
        ..text = text;
      descriptionElement.append(textElement);

      var buttonElement = new DivElement()
        ..classes.add('action__button')
        ..classes.add('action__button--float')
        ..text = '$buttonText (En)'; // TODO(mariana): These project-specific preferences should be read from a project config file
      buttonElement.onClick.listen((_) => command(UIAction.sendMessage, new ReplyData(replyIndex)));
      textWrapper.append(buttonElement);
      _buttonElements.add(buttonElement);
    }

    { // Add translation
      var translationWrapper = new DivElement()
        ..style.position = 'relative';
      textTranslationWrapper.append(translationWrapper);

      var descriptionElement = new DivElement()
        ..classes.add('action__description');
      translationWrapper.append(descriptionElement);

      var translationElement = new DivElement()
        ..classes.add('action__translation')
        ..text = translation;
      descriptionElement.append(translationElement);

      var buttonElement = new DivElement()
        ..classes.add('action__button')
        ..classes.add('action__button--float')
        ..text = '$buttonText (Swa)'; // TODO(mariana): These project-specific preferences should be read from a project config file
      buttonElement.onClick.listen((_) => command(UIAction.sendMessage, new ReplyData(replyIndex, replyWithTranslation: true)));
      translationWrapper.append(buttonElement);
      _buttonElements.add(buttonElement);
    }
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

class MarkUnreadActionView {
  DivElement markUnreadAction;

  MarkUnreadActionView() {
    markUnreadAction = new DivElement()
      ..classes.add('add-action__button')
      ..onClick.listen(markConversationsUnread);
    multiSelectMode(false);
  }

  void markConversationsUnread([_]) {
    command(UIAction.markConversationUnread, ConversationData(activeConversation.docId));
  }

  void multiSelectMode(bool enabled) {
    if (enabled) {
      markUnreadAction
        ..title = 'Mark selected conversations unread'
        ..text = MARK_SELECTED_UNREAD_INFO;
    } else {
      markUnreadAction
        ..title = 'Mark current conversation unread'
        ..text = MARK_UNREAD_INFO;
    }
  }
}

class AuthHeaderView {
  DivElement authElement;
  DivElement _userPic;
  DivElement _userName;
  ButtonElement _signOutButton;

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
  }

  void signIn(String userName, userPicUrl) {
    // Set the user's profile pic and name
    _userPic.style.backgroundImage = 'url($userPicUrl)';
    _userName.text = userName;

    // Show user's profile pic, name and sign-out button.
    _userName.attributes.remove('hidden');
    _userPic.attributes.remove('hidden');
    _signOutButton.attributes.remove('hidden');
  }

  void signOut() {
    // Hide user's profile pic, name and sign-out button.
    _userName.attributes['hidden'] = 'true';
    _userPic.attributes['hidden'] = 'true';
    _signOutButton.attributes['hidden'] = 'true';
  }
}

class AuthMainView {
  DivElement authElement;

  final descriptionText1 = 'Sign in to Nook where you can manage SMS conversations.';

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

    var shortDescription = new DivElement()
      ..classes.add('project-description')
      ..append(new ParagraphElement()..text = descriptionText1);
    authElement.append(shortDescription);

    for (var domain in SignInDomain.values) {
      var signInButton = new ButtonElement()
        ..text = "Sign in with ${signInDomainsInfo[domain]['displayName']}"
        ..onClick.listen((_) => command(UIAction.signInButtonClicked, new SignInData(domain)));
      authElement.append(signInButton);
    }
  }
}

class UrlView {

  static const String queryDisableRepliesKey = 'disableReplies';
  static const String queryConversationListKey = 'conversation-list';
  static const String queryConversationIdKey = 'conversation-id';
  static const String queryConversationIdFilterKey = 'conversation-id-filter';

  String getQueryTagFilterKey(TagFilterType type) {
    switch (type) {
      case TagFilterType.include:
        return 'filter'; // TODO(mariana): this should be updated to 'include-filter' but we keep it 'filter for backwards compatibility
      case TagFilterType.exclude:
        return 'exclude-filter';
      case TagFilterType.lastInboundTurn:
        return 'last-inbound-turn-filter';
    }
    throw 'Trying to read an unknown filter type: $type';
  }

  String getQueryAfterDateFilterKey(TagFilterType type) {
    switch (type) {
      case TagFilterType.include:
        return 'include-after-date';
      case TagFilterType.exclude:
        return 'exclude-after-date';
      default:
        throw 'Trying to read an unknown filter type: $type';
    }
  }

  List<String> getPageUrlFilterTags(TagFilterType type) {
    var queryFilterKey = getQueryTagFilterKey(type);
    var uri = Uri.parse(window.location.href);
    if (uri.queryParameters.containsKey(queryFilterKey)) {
      List<String> filterTags = uri.queryParameters[queryFilterKey].split(' ');
      filterTags.removeWhere((tag) => tag == "");
      return filterTags;
    }
    return [];
  }

  void setPageUrlFilterTags(TagFilterType type, List<String> filterTags) {
    var queryFilterKey = getQueryTagFilterKey(type);
    var uri = Uri.parse(window.location.href);
    Map<String, String> queryParameters = new Map.from(uri.queryParameters);
    if (filterTags == null || filterTags.isEmpty) {
      queryParameters.remove(queryFilterKey);
    } else {
      queryParameters[queryFilterKey] = filterTags.join(' ');
    }
    uri = uri.replace(queryParameters: queryParameters);
    window.history.pushState('', '', uri.toString());
  }

  String getPageUrlConversationList() {
    var uri = Uri.parse(window.location.href);
    if (uri.queryParameters.containsKey(queryConversationListKey)) {
      return uri.queryParameters[queryConversationListKey];
    }
    return null;
  }

  void setPageUrlConversationList(String conversationListId) {
    var uri = Uri.parse(window.location.href);
    Map<String, String> queryParameters = new Map.from(uri.queryParameters);
    if (conversationListId == null) {
      queryParameters.remove(queryConversationListKey);
    } else {
      queryParameters[queryConversationListKey] = conversationListId;
    }
    uri = uri.replace(queryParameters: queryParameters);
    window.history.pushState('', '', uri.toString());
  }

  String getPageUrlConversationId() {
    var uri = Uri.parse(window.location.href);
    if (uri.queryParameters.containsKey(queryConversationIdKey)) {
      return uri.queryParameters[queryConversationIdKey];
    }
    return null;
  }

  void setPageUrlConversationId(String conversationId) {
    var uri = Uri.parse(window.location.href);
    Map<String, String> queryParameters = new Map.from(uri.queryParameters);
    if (conversationId == null) {
      queryParameters.remove(queryConversationIdKey);
    } else {
      queryParameters[queryConversationIdKey] = conversationId;
    }
    uri = uri.replace(queryParameters: queryParameters);
    window.history.pushState('', '', uri.toString());
  }

  DateTime getPageUrlFilterAfterDate(TagFilterType type) {
    var queryFilterKey = getQueryAfterDateFilterKey(type);
    var uri = Uri.parse(window.location.href);
    if (uri.queryParameters.containsKey(queryFilterKey)) {
      String afterDateFilter = uri.queryParameters[queryFilterKey];
      try {
        return _afterDateFilterFormat.parse(afterDateFilter);
      } on FormatException catch (e) {
        command(UIAction.showSnackbar, new SnackbarData("Invalid date/time format for filter in URL: ${e.message}", SnackbarNotificationType.error));
        return null;
      }
    }
    return null;
  }

  void setPageUrlFilterAfterDate(TagFilterType type, DateTime afterDateFilter) {
    var queryFilterKey = getQueryAfterDateFilterKey(type);
    var uri = Uri.parse(window.location.href);
    Map<String, String> queryParameters = new Map.from(uri.queryParameters);
    if (afterDateFilter == null) {
      queryParameters.remove(queryFilterKey);
    } else {
      queryParameters[queryFilterKey] = _afterDateFilterFormat.format(afterDateFilter);
    }
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

  String getPageUrlFilterConversationId() {
    var uri = Uri.parse(window.location.href);
    if (uri.queryParameters.containsKey(queryConversationIdFilterKey)) {
      return uri.queryParameters[queryConversationIdFilterKey];
    }
    return null;
  }

  void setPageUrlFilterConversationId(String conversationIdFilter) {
    var uri = Uri.parse(window.location.href);
    Map<String, String> queryParameters = new Map.from(uri.queryParameters);
    if (conversationIdFilter == null) {
      queryParameters.remove(queryConversationIdFilterKey);
    } else {
      queryParameters[queryConversationIdFilterKey] = conversationIdFilter;
    }
    uri = uri.replace(queryParameters: queryParameters);
    window.history.pushState('', '', uri.toString());
  }

}

class SnackbarView {
  DivElement snackbarElement;
  DivElement _contents;

  /// How many seconds the snackbar will be displayed on screen before disappearing.
  static const SECONDS_ON_SCREEN = 3;

  /// The length of the animation in milliseconds.
  /// This must match the animation length set in snackbar.css
  static const ANIMATION_LENGTH_MS = 200;

  SnackbarView() {
    snackbarElement = new DivElement()
      ..id = 'snackbar'
      ..classes.add('hidden')
      ..title = 'Click to close notification.'
      ..onClick.listen((_) => hideSnackbar());

    _contents = new DivElement()
      ..classes.add('contents');
    snackbarElement.append(_contents);
  }

  showSnackbar(String message, SnackbarNotificationType type) {
    _contents.text = message;
    snackbarElement.classes.remove('hidden');
    snackbarElement.setAttribute('type', type.toString().replaceAll('SnackbarNotificationType.', ''));
    new Timer(new Duration(seconds: SECONDS_ON_SCREEN), () => hideSnackbar());
  }

  hideSnackbar() {
    snackbarElement.classes.toggle('hidden', true);
    snackbarElement.attributes.remove('type');
    // Remove the contents after the animation ends
    new Timer(new Duration(milliseconds: ANIMATION_LENGTH_MS), () => _contents.text = '');
  }
}

class BannerView {
  DivElement bannerElement;
  DivElement _contents;

  /// The length of the animation in milliseconds.
  /// This must match the animation length set in banner.css
  static const ANIMATION_LENGTH_MS = 200;

  BannerView() {
    bannerElement = new DivElement()
      ..id = 'banner'
      ..classes.add('hidden');

    _contents = new DivElement()
      ..classes.add('contents');
    bannerElement.append(_contents);
  }

  showBanner(String message) {
    _contents.text = message;
    bannerElement.classes.remove('hidden');
  }

  hideBanner() {
    bannerElement.classes.add('hidden');
    // Remove the contents after the animation ends
    new Timer(new Duration(milliseconds: ANIMATION_LENGTH_MS), () => _contents.text = '');
  }
}
