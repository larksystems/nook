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

  ConversationPanelView() {
    conversationPanel = new DivElement();
    conversationPanel.classes.add('message-panel');

    var conversationSummary = new DivElement();
    conversationSummary.classes.add('message-summary');
    _personId = new DivElement();
    _personId.classes.add('message-summary__id');
    conversationSummary.append(_personId);
    _info = new DivElement();
    _info.classes.add('message-summary__demographics');
    conversationSummary.append(_info);
    conversationPanel.append(conversationSummary);

    _messages = new DivElement();
    _messages.classes.add('messages');
    conversationPanel.append(_messages);
  }

  set personId(String personId) => _personId.text = personId;
  set personInfo(String personInfo) => _info.text = personInfo;

  addMessage(MessageView message) {
    _messages.append(message.message);
  }
}

class MessageView {
  DivElement message;
  DivElement _message;
  DivElement _messageLabels;
  DivElement _messageText;
  DivElement _messageTranslation;

  MessageView(String content, String messageId, {String translation = '', bool incoming = true, List<LabelView> labels = const[]}) {
    message = new DivElement()
      ..classes.add('message-line')
      ..dataset['id'] = messageId;

    _message = new DivElement()
      ..classes.add('message')
      ..classes.add(incoming ? 'message--incoming' : 'message--outgoing');
    message.append(_message);

    _messageLabels = new DivElement()
      ..classes.add('message__labels');
    labels.forEach((label) => _messageLabels.append(label.label));
    _message.append(_messageLabels);

    _messageText = new DivElement()
      ..classes.add('message__text')
      ..classes.add(incoming ? 'message__text--incoming' : 'message__text--outgoing')
      ..text = content;
    _message.append(_messageText);

    _messageTranslation = new DivElement()
      ..classes.add('message__translation')
      ..classes.add(incoming ? 'message__translation--incoming' : 'message__translation--outgoing')
      ..contentEditable = 'true'
      ..text = translation
      ..onInput.listen((_) => command(UIAction.updateTranslation, new TranslationData(_messageTranslation.text, messageId)));
    _message.append(_messageTranslation);
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

class LabelView {
  DivElement label;

  LabelView(String text, String labelId) {
    label = new DivElement()
      ..classes.add('label')
      ..dataset['id'] = labelId;

    label.append(new SpanElement()..text = text);
    var removeButton = new SpanElement()
      ..classes.add('label__remove')
      ..text = 'x'
      ..onClick.listen((_) {
        DivElement message = getAncestors(label).firstWhere((e) => e.classes.contains('message-line'));
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
