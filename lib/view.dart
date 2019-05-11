import 'dart:html';

import 'dom_utils.dart';
import 'logger.dart';
import 'viewmodel.dart';


Logger log = new Logger('view.dart');

class ConversationPanelView {
  // HTML elements
  DivElement conversationPanel;
  DivElement _messages;
  DivElement _personId;
  DivElement _info;
  DivElement _tags;

  ConversationPanelView() {
    conversationPanel = new DivElement();
    conversationPanel.classes.add('message-panel');

    var conversationSummary = new DivElement()
      ..classes.add('message-summary');
    conversationPanel.append(conversationSummary);

    _personId = new DivElement()
      ..classes.add('message-summary__id');
    conversationSummary.append(_personId);

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

  set personId(String personId) => _personId.text = personId;
  set personInfo(String personInfo) => _info.text = personInfo;

  addMessage(MessageView message) {
    _messages.append(message.message);
  }

  addTags(LabelView label) {
    _tags.append(label.label);
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

  ConversationListPanelView() {
    conversationListPanel = new DivElement();
    conversationListPanel.classes.add('message-list');
  }

  void addConversation(ConversationSummary conversationSummary, [int position]) {
    if (position == null || position >= conversationListPanel.children.length) {
      // Add at the end
      conversationListPanel.append(conversationSummary.conversationSummary);
      return;
    }
    // Add before an existing label
    if (position < 0) {
      position = 0;
    }
    Node refChild = conversationListPanel.children[position];
    conversationListPanel.insertBefore(conversationSummary.conversationSummary, refChild);
  }
}

class ConversationSummary {
  DivElement conversationSummary;

  ConversationSummary(String personId, String content) {
    conversationSummary = new DivElement()
      ..classes.add('summary-message')
      ..dataset['id'] = personId
      ..text = content
      ..onClick.listen((_) => command(UIAction.selectConversation, new ConversationData(personId)));
  }

  set content(String text) => conversationSummary.text = text;
}
