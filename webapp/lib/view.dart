import 'dart:html';

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
}

void initSignedOutView() {
  clearMain();

  querySelector('main')
    ..append(authMainView.authElement);
}

void clearMain() {
  conversationListPanelView.conversationListPanel.remove();
  conversationPanelView.conversationPanel.remove();
  replyPanelView.replyPanel.remove();
  tagPanelView.tagPanel.remove();
  authMainView.authElement.remove();
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
      ..classes.add('conversation-panel')
      ..onClick.listen((_) => command(UIAction.deselectMessage, null));

    var conversationSummary = new DivElement()
      ..classes.add('conversation-summary');
    conversationPanel.append(conversationSummary);

    _deidentifiedPhoneNumber = new DivElement()
      ..classes.add('conversation-summary__id');
    conversationSummary.append(_deidentifiedPhoneNumber);

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

  set deidentifiedPhoneNumber(String deidentifiedPhoneNumber) => _deidentifiedPhoneNumber.text = deidentifiedPhoneNumber;
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
  DivElement _messageBubble;
  DivElement _messageTags;
  DivElement _messageText;
  DivElement _messageTranslation;

  static MessageView selectedMessageView;

  MessageView(String text, String conversationId, int messageIndex, {String translation = '', bool incoming = true, List<TagView> tags = const[]}) {
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

enum TagColour {
  None,
  Green,
  Yellow,
  Red
}

abstract class TagView {
  DivElement tag;
  SpanElement _tagText;
  SpanElement _removeButton;

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
  MessageTagView(String text, String tagId, [TagColour tagColour = TagColour.None]) : super(text, tagId, tagColour) {
    _removeButton.onClick.listen((_) {
      DivElement message = getAncestors(tag).firstWhere((e) => e.classes.contains('message'), orElse: () => null);
      command(UIAction.removeMessageTag, new MessageTagData(tagId, int.parse(message.dataset['message-index'])));
    });
  }
}

class ConversationTagView extends TagView {
  ConversationTagView(String text, String tagId, [TagColour tagColour = TagColour.None]) : super(text, tagId, tagColour) {
    _removeButton.onClick.listen((_) {
      DivElement messageSummary = getAncestors(tag).firstWhere((e) => e.classes.contains('conversation-summary'));
      command(UIAction.removeConversationTag, new ConversationTagData(tagId, messageSummary.dataset['id']));
    });
  }
}

class FilterMenuTagView extends TagView {
  FilterMenuTagView(String text, String tagId, [TagColour tagColour = TagColour.None]) : super(text, tagId, tagColour) {
    _removeButton.remove();
    tag.onClick.listen((_) {
      command(UIAction.addFilterTag, new FilterTagData(tagId));
    });
  }
}

class FilterTagView extends TagView {
  FilterTagView(String text, String tagId, [TagColour tagColour = TagColour.None]) : super(text, tagId, tagColour) {
    _removeButton..onClick.listen((_) {
      command(UIAction.removeFilterTag, new FilterTagData(tagId));
    });
  }
}

class ConversationListPanelView {
  DivElement conversationListPanel;
  DivElement _conversationList;

  ConversationFilter conversationFilter;

  Map<String, ConversationSummary> _phoneToConversations = {};
  ConversationSummary activeConversation;

  ConversationListPanelView() {
    conversationListPanel = new DivElement()
      ..classes.add('conversation-list-panel');

    _conversationList = new DivElement()
      ..classes.add('message-list');
    conversationListPanel.append(_conversationList);

    conversationFilter = new ConversationFilter();
    conversationListPanel.append(conversationFilter.conversationFilter);
  }

  void addConversation(ConversationSummary conversationSummary, [int position]) {
    if (position == null || position >= _conversationList.children.length) {
      // Add at the end
      _conversationList.append(conversationSummary.conversationSummary);
      _phoneToConversations[conversationSummary.deidentifiedPhoneNumber] = conversationSummary;
      return;
    }
    // Add before an existing tag
    if (position < 0) {
      position = 0;
    }
    Node refChild = _conversationList.children[position];
    _conversationList.insertBefore(conversationSummary.conversationSummary, refChild);
    _phoneToConversations[conversationSummary.deidentifiedPhoneNumber] = conversationSummary;
  }

  void selectConversation(String deidentifiedPhoneNumber) {
    activeConversation?._deselect();
    activeConversation = _phoneToConversations[deidentifiedPhoneNumber];
    activeConversation._select();
    activeConversation.conversationSummary.scrollIntoView();
  }

  void clearConversationList() {
    int conversationsNo = _conversationList.children.length;
    for (int i = 0; i < conversationsNo; i++) {
      _conversationList.firstChild.remove();
    }
    assert(_conversationList.children.length == 0);
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
  DivElement conversationSummary;

  String deidentifiedPhoneNumber;

  ConversationSummary(this.deidentifiedPhoneNumber, String text) {
    conversationSummary = new DivElement()
      ..classes.add('summary-message')
      ..dataset['id'] = deidentifiedPhoneNumber
      ..text = text
      ..onClick.listen((_) => command(UIAction.selectConversation, new ConversationData(deidentifiedPhoneNumber)));
  }

  set text(String text) => conversationSummary.text = text;

  void _deselect() => conversationSummary.classes.remove('summary-message--selected');
  void _select() => conversationSummary.classes.add('summary-message--selected');
}

class ReplyPanelView {
  DivElement replyPanel;
  DivElement _replies;
  DivElement _replyList;
  DivElement _notes;
  DivElement _notesTextarea;

  AddActionView _addReply;

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

    _addReply = new AddReplyActionView(ADD_REPLY_INFO);
    _replies.append(_addReply.addAction);

    _notes = new DivElement()
      ..classes.add('notes-box');
    replyPanel.append(_notes);

    _notesTextarea = new DivElement()
      ..classes.add('notes-box__textarea')
      ..contentEditable = 'true'
      ..onInput.listen((_) => command(UIAction.updateNote, new NoteData(_notesTextarea.text)))
      ..onKeyPress.listen((e) => e.stopPropagation());
    _notes.append(_notesTextarea);
  }

  set noteText(String text) => _notesTextarea.text = text;

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
  DivElement _newActionTextarea;
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
        _newActionBox.style.visibility = 'visible';
        _newActionTextarea.focus();

        // Position cursor at the end
        // See https://stackoverflow.com/questions/1125292/how-to-move-cursor-to-end-of-contenteditable-entity/3866442#3866442
        var range = document.createRange()
          ..selectNodeContents(_newActionTextarea)
          ..collapse(false);
        window.getSelection()
          ..removeAllRanges()
          ..addRange(range);

        // Set a listener for hiding the box if the user clicks outside it
        var windowClickStream;
        windowClickStream = window.onMouseDown.listen((e) {
          var addActionBox = getAncestors(e.target).where((ancestor) => ancestor.classes.contains('add-action__box'));
          if (addActionBox.isNotEmpty) return; // click inside the box
          _newActionBox.style.visibility = 'hidden';
          windowClickStream.cancel();
        });
      });
    addAction.append(button);

    _newActionBox = new DivElement()
      ..classes.add('add-action__box')
      ..style.visibility = 'hidden';
    addAction.append(_newActionBox);

    _newActionTextarea = new DivElement()
      ..classes.add('add-action__textarea')
      ..contentEditable = 'true'
      ..text = ''
      ..onKeyPress.listen((e) => e.stopPropagation());
    _newActionBox.append(_newActionTextarea);

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
        _newActionTextarea.text = '';
        _newActionTranslation.text = '';
      });
    _newActionBox.append(_newActionButton);
  }
}

class AddReplyActionView extends AddActionView {
  AddReplyActionView(String infoText) : super(infoText) {
    _newActionButton.onClick.listen((_) => command(UIAction.addNewSuggestedReply, new AddSuggestedReplyData(_newActionTextarea.text, _newActionTranslation.text)));
  }
}

class AddTagActionView extends AddActionView {
  AddTagActionView(String infoText) : super(infoText) {
    _newActionButton.onClick.listen((_) => command(UIAction.addNewTag, new AddTagData(_newActionTextarea.text)));
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
}
