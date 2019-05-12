import 'dart:html';
import 'view.dart';

void init() {
  // Populate conversation with some data
  ConversationPanelView conversation = new ConversationPanelView();
  conversation.personId = 'KGD6192830172';
  conversation.personInfo = '23 years old unmarried female, East';
  print(querySelector('main'));
  querySelector('.message-panel').remove();
  querySelector('main').insertBefore(conversation.conversationPanel, querySelector('.reply-panel'));

  conversation.addMessage(
    new MessageView(
      'Buna prietene',
      '0000',
      translation: 'Hi there my friend',
      incoming: true,
      labels: [
        new LabelView('label1', '0000-1'),
        new LabelView('label2', '0000-2')
      ])
  );
  conversation.addMessage(
    new MessageView(
      'Salut',
      '0001',
      translation: 'Hey',
      incoming: false)
  );
  conversation.addMessage(
    new MessageView(
      'First of all, thank you for all your work, it\'s really great to see this being done',
      '0003',
      labels: [
        new LabelView('label1', '0000-1'),
        new LabelView('label2', '0000-2')
      ])
  );
  conversation.addMessage(
    new MessageView(
      'De asemenea, ma bucur tare mult ca pot sa vorbesc cu tine, cred ca e f important ca cineva asculta.',
      '0004',
      translation: 'Also, I\'m super happy that I can talk with you, I think it\'s really important someone listens to this.')
  );
  conversation.addMessage(
    new MessageView(
      'Thank you for your message, what\'s your gender?',
      '0005',
      translation: 'Hey',
      incoming: false)
  );
  conversation.addMessage(
    new MessageView(
      'Female',
      '0006',
      incoming: true,
      labels: [
        new LabelView('gender', '0006-1'),
      ])
  );
  conversation.addMessage(
    new MessageView(
      'How old are you?',
      '0007',
      incoming: false)
  );
  conversation.addMessage(
    new MessageView(
      '23',
      '0008',
      incoming: true,
      labels: [
        new LabelView('age', '0008-1'),
      ])
  );
  conversation.addMessage(
    new MessageView(
      'Which area do you live in?',
      '0009',
      incoming: false)
  );
  conversation.addMessage(
    new MessageView(
      'East',
      '0010',
      incoming: true,
      labels: [
        new LabelView('location', '0010-1'),
      ])
  );
  conversation.addMessage(
    new MessageView(
      'Are you married?',
      '0011',
      incoming: false)
  );
  conversation.addMessage(
    new MessageView(
      'No',
      '0012',
      incoming: true,
      labels: [
        new LabelView('married', '0012-1'),
      ])
  );
  conversation.addMessage(
    new MessageView(
      'Thank you for your time',
      '0013',
      incoming: false)
  );
  conversation.addMessage(
    new MessageView(
      'Thank you too!',
      '0014',
      incoming: true)
  );

  // Populate the conversation list with some data
  ConversationListPanelView conversationList = new ConversationListPanelView();
  querySelector('.message-list').remove();
  querySelector('main').insertBefore(conversationList.conversationListPanel, conversation.conversationPanel);

  conversationList.addConversation(new ConversationSummary('abg', 'This is the starting message of a longer conversation'));
  conversationList.addConversation(new ConversationSummary("ynx", "Hi there, I'm 24 and I think this is a good idea"));
  conversationList.addConversation(new ConversationSummary("ahd", "First of all, thank you for all your work, it's really great to see this being done"));
  conversationList.addConversation(new ConversationSummary("asd", "Are you listening?"));
  conversationList.addConversation(new ConversationSummary("oia", "18"));
  conversationList.addConversation(new ConversationSummary("pao", "Hi"));
  conversationList.addConversation(new ConversationSummary("pas", "M"));
  conversationList.addConversation(new ConversationSummary("bka", "Buna prietene"));
  conversationList.addConversation(new ConversationSummary("pgj", "I'm a guy"));
  conversationList.addConversation(new ConversationSummary("ahd", "I messaged you before, but I didn't receive a reply. Is anyone there?"));
  conversationList.addConversation(new ConversationSummary("alh", "71"));
  conversationList.addConversation(new ConversationSummary("xho", "Male"));
  conversationList.addConversation(new ConversationSummary("bas", "Hello, it's great to hear from you"));
  conversationList.addConversation(new ConversationSummary("vbl", "I'm looking for places to stay"));
  conversationList.addConversation(new ConversationSummary("oah", "Female"));
  conversationList.addConversation(new ConversationSummary("bal", "There are many people here"));
  conversationList.addConversation(new ConversationSummary("pha", "I don't know"));
  conversationList.addConversation(new ConversationSummary("mba", "I'm 35"));
  conversationList.addConversation(new ConversationSummary("ksa", "Do you get these?"));
  conversationList.addConversation(new ConversationSummary("zho", "F"));
}
