import 'dart:async';
import 'dart:html';

import 'package:intl/intl.dart';

import 'controller.dart';
import 'dom_utils.dart';
import 'logger.dart';
import 'model.dart';
import 'lazy_list_view_model.dart';


Logger log = new Logger('view.dart');

ConversationListSelectHeader conversationListSelectView;
ConversationListPanelView conversationListPanelView;
ConversationFilter get conversationFilter => conversationListPanelView.conversationFilter;
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

  querySelector('header')
      ..insertAdjacentElement('beforeBegin', bannerView.bannerElement)
      ..append(conversationListSelectView.panel)
      ..append(authHeaderView.authElement);

  document.onKeyDown.listen((event) => command(UIAction.keyPressed, new KeyPressData(event.key)));
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

void showTagPanel(bool show) {
  if (show) {
    tagPanelView.tagPanel.classes.toggle('hidden', false);
    conversationListPanelView.conversationListPanel.classes.add('w-20');
    conversationPanelView.conversationPanel.classes.add('w-40');
    replyPanelView.replyPanel.classes.add('w-25');
    tagPanelView.tagPanel.classes.add('w-15');
    return;
  }
  tagPanelView.tagPanel.classes.toggle('hidden', true);
  conversationListPanelView.conversationListPanel.classes.add('w-25');
  conversationPanelView.conversationPanel.classes.add('w-45');
  replyPanelView.replyPanel.classes.add('w-30');
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
    ..onInput.listen((e) {
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
    if (!currentConfig.sendCustomMessagesEnabled) {
      showCustomMessageBox(false);
    }
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
    clearNewMessageBox();

    int tagsNo = _tags.children.length;
    for (int i = 0; i < tagsNo; i++) {
      _tags.firstChild.remove();
    }

    int messagesNo = _messages.children.length;
    for (int i = 0; i < messagesNo; i++) {
      _messages.firstChild.remove();
    }
  }

  void clearNewMessageBox() {
    _newMessageTextArea?.value = '';
  }

  void showCustomMessageBox(bool show) {
    _newMessageBox.classes.toggle('hidden', !show);
  }

  void showAfterDateFilterPrompt(DateTime dateTime) {
    _afterDateFilterView.showPrompt(dateTime);
  }
}

class AfterDateFilterView {
  DivElement panel;
  TextAreaElement _textArea;

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

  void showPrompt(DateTime dateTime) {
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
      snackbarView.showSnackbar("Invalid date/time format: ${e.message}", SnackbarNotificationType.error);
      return;
    }
    command(UIAction.updateAfterDateFilter, new AfterDateFilterData(AFTER_DATE_TAG_ID, dateTime));
    hidePrompt();
  }

  void hidePrompt([_]) {
    panel.classes.remove('after-date-prompt__visible');
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
    makeEditable(_messageTranslation, onChange: () {
      command(UIAction.updateTranslation, new TranslationData(_messageTranslation.text, conversationId, messageIndex));
    });
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
    if (status == MessageStatus.failed)
      message.classes.add('message--failed');
    else
      message.classes.remove('message--failed');
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
  FilterMenuTagView(String text, String tagId, TagStyle tagStyle) : super(text, tagId, tagStyle) {
    _removeButton.remove();
    tag.onClick.listen((_) {
      handleClicked(tagId);
    });
  }

  void handleClicked(String tagId) {
    command(UIAction.addFilterTag, new FilterTagData(tagId));
  }
}

class FilterTagView extends TagView {
  FilterTagView(String text, String tagId, TagStyle tagStyle) : super(text, tagId, tagStyle) {
    _removeButton.onClick.listen((_) => handleClicked(tagId));
  }

  void handleClicked(String tagId) {
    command(UIAction.removeFilterTag, new FilterTagData(tagId));
  }
}

const AFTER_DATE_TAG_ID = "after-date";
final DateFormat _afterDateFilterFormat = DateFormat('yyyy.MM.dd HH:mm');

class AfterDateFilterMenuTagView extends FilterMenuTagView {
  AfterDateFilterMenuTagView() : super("after date", AFTER_DATE_TAG_ID, TagStyle.None);

  @override
  void handleClicked(String tagId) {
    command(UIAction.promptAfterDateFilter, new AfterDateFilterData(tagId));
  }
}

class AfterDateFilterTagView extends FilterTagView {
  AfterDateFilterTagView(DateTime dateTime) : super(filterText(dateTime), AFTER_DATE_TAG_ID, TagStyle.None);

  static String filterText(DateTime dateTime) {
    return "after date ${_afterDateFilterFormat.format(dateTime)}";
  }

  @override
  void handleClicked(String tagId) {
    command(UIAction.updateAfterDateFilter, new AfterDateFilterData(tagId, null));
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
      shardSelected();
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
}

class ConversationListPanelView {
  DivElement conversationListPanel;
  DivElement _conversationPanelTitle;
  MarkUnreadActionView _markUnread;
  LazyListViewModel _conversationList;
  CheckboxInputElement _selectAllCheckbox;
  DivElement _loadSpinner;
  DivElement _selectConversationListMessage;

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
      ..onClick.listen((_) => _selectAllCheckbox.checked ? command(UIAction.selectAllConversations, null) : command(UIAction.deselectAllConversations, null));
    panelHeader.append(_selectAllCheckbox);

    _conversationPanelTitle = new DivElement()
      ..classes.add('panel-title')
      ..classes.add('conversation-list-header__title')
      ..text = '0 conversations';
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

    conversationFilter = new ConversationFilter();
    conversationListPanel.append(conversationFilter.conversationFilter);

    currentConfig.sendMultiMessageEnabled ? showCheckboxes() : hideCheckboxes();
  }

  void updateConversationList(Set<Conversation> conversations) {
    _phoneToConversations.removeWhere((String uuid, ConversationSummary summary) {
      if (conversations.any((c) => c.docId == uuid)) return false;
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
    _conversationPanelTitle.text = '${_phoneToConversations.length} conversations';
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
    _conversationPanelTitle.text = '${_phoneToConversations.length} conversations';
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

  void clearConversationList() {
    _conversationList.clearItems();
    _phoneToConversations.clear();
    _conversationPanelTitle.text = '${_phoneToConversations.length} conversations';
  }

  void markConversationRead(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]._markRead();
  }

  void markConversationUnread(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]._markUnread();
  }

  void checkConversation(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]._check();
  }

  void uncheckConversation(String deidentifiedPhoneNumber) {
    _phoneToConversations[deidentifiedPhoneNumber]._uncheck();
  }

  void checkAllConversations() => _phoneToConversations.forEach((_, conversation) => conversation._check());
  void uncheckAllConversations() => _phoneToConversations.forEach((_, conversation) => conversation._uncheck());
  void showCheckboxes() {
    _selectAllCheckbox.hidden = false;
    _phoneToConversations.forEach((_, conversation) => conversation._showCheckbox());
    _markUnread.multiSelectMode(true);
  }
  void hideCheckboxes() {
    _selectAllCheckbox.hidden = true;
    _phoneToConversations.forEach((_, conversation) => conversation._hideCheckbox());
    _markUnread.multiSelectMode(false);
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

class ConversationSummary with LazyListViewItem {
  CheckboxInputElement _selectCheckbox;

  String deidentifiedPhoneNumber;
  String _text;
  bool _unread;
  bool _checked = false;
  bool _selected = false;
  bool _checkboxHidden = true;

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
    currentConfig.sendMultiMessageEnabled ? _showCheckbox() : _hideCheckbox();
    conversationSummary.append(_selectCheckbox);

    var summaryMessage = new DivElement()
      ..classes.add('summary-message')
      ..dataset['id'] = deidentifiedPhoneNumber
      ..onClick.listen((_) => command(UIAction.showConversation, new ConversationData(deidentifiedPhoneNumber)));
    if (_selected) conversationSummary.classes.add('conversation-list__item--selected');
    if (_unread) conversationSummary.classes.add('conversation-list__item--unread');
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
  void _showCheckbox() {
    _checkboxHidden = false;
    if (_selectCheckbox != null) _selectCheckbox.hidden = false;
  }
  void _hideCheckbox() {
    _checkboxHidden = true;
    if (_selectCheckbox != null) _selectCheckbox.hidden = true;
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

    _addReply = new AddReplyActionView(ADD_REPLY_INFO);
    _replies.append(_addReply.addAction);

    _notes = new DivElement()
      ..classes.add('notes-box');
    replyPanel.append(_notes);

    _notesTextArea = new TextAreaElement()
      ..classes.add('notes-box__textarea');
    makeEditable(_notesTextArea, onChange: () {
      command(UIAction.updateNote, new NoteData(_notesTextArea.value));
    });
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

  void showShortcuts(bool value) {
    for (var view in _replyViews) {
      view.showShortcut(value);
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
}

class TagPanelView {
  DivElement tagPanel;
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
      ..classes.add('panel-title')
      ..classes.add('panel-title--multiple-cols');
    tagPanel.append(panelTitle);

    _hideTagsCheckbox = new InputElement(type: 'checkbox')
      ..checked = true
      ..onChange.listen((_) => command(UIAction.hideAgeTags, new ToggleData(_hideTagsCheckbox.checked)));

    panelTitle
      ..append(
        new DivElement()..text = TAG_PANEL_TITLE)
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

    _addTag = new AddTagActionView(ADD_TAG_INFO);
    _tags.append(_addTag.addAction);

    _statusPanel = new DivElement();
    _statusText = new Text('loading...');
    tagPanel.append(_statusPanel
      ..classes.add('status-line')
      ..append(_statusText));

    _tagViews = [];
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

  void showShortcuts(bool value) {
    for (var view in _tagViews) {
      view.showShortcut(value);
    }
  }
}

class ActionView {
  DivElement action;
  DivElement _shortcutElement;

  ActionView(String text, String shortcut, String actionId, String buttonText) {
    action = new DivElement()
      ..classes.add('action')
      ..dataset['id'] = actionId;

    _shortcutElement = new DivElement()
      ..classes.add('action__shortcut')
      ..text = shortcut;
    showShortcut(currentConfig.keyboardShortcutsEnabled);
    action.append(_shortcutElement);

    var textElement = new DivElement()
      ..classes.add('action__description')
      ..text = text;
    action.append(textElement);

    var buttonElement = new DivElement()
      ..classes.add('action__button')
      ..text = buttonText;
    action.append(buttonElement);
  }

  void showShortcut(bool value) {
    _shortcutElement.classes.toggle('hidden', !value);
  }
}

class ReplyActionView extends ActionView {
  ReplyActionView(String text, String translation, String shortcut, int replyIndex, String buttonText) : super(text, shortcut, '$replyIndex', buttonText) {
    action.children.clear();

    _shortcutElement = new DivElement()
      ..classes.add('action__shortcut')
      ..text = shortcut;
    showShortcut(currentConfig.keyboardShortcutsEnabled);
    action.append(_shortcutElement);

    var textTranslationWrapper = new DivElement()
      ..style.flex = '1 1 auto';
    action.append(textTranslationWrapper);

    { // Add text
      var textWrapper = new DivElement()
        ..style.display = 'flex';
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
    }

    { // Add translation
      var translationWrapper = new DivElement()
        ..style.display = 'flex';
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

enum SnackbarNotificationType {
  info,
  success,
  warning,
  error
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
