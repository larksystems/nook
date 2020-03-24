import "dart:async";

import 'package:firebase/firebase.dart' as firebase;

import 'controller.dart' as controller;
import 'logger.dart';
import 'model.dart';
import 'model_firebase.dart';
import 'platform_constants.dart' as platform_constants;
import 'pubsub.dart';

Logger log = new Logger('platform.dart');

const _SEND_TO_MULTI_IDS_ACTION = "send_to_multi_ids";

DocStorage _docStorage;
PubSubClient _pubsubInstance;

init() async {
  await platform_constants.init();

  firebase.initializeApp(
    apiKey: platform_constants.apiKey,
    authDomain: platform_constants.authDomain,
    databaseURL: platform_constants.databaseURL,
    projectId: platform_constants.projectId,
    storageBucket: platform_constants.storageBucket,
    messagingSenderId: platform_constants.messagingSenderId);

  // Firebase login
  firebaseAuth.onAuthStateChanged.listen((firebase.User user) async {
    if (user == null) { // User signed out
      _pubsubInstance = null;
      controller.command(controller.UIAction.userSignedOut, null);
      return;
    }
    // User signed in
    String photoURL = firebaseAuth.currentUser.photoURL;
    if (photoURL == null) {
      photoURL =  '/assets/user_image_placeholder.png';
    }
    _docStorage = FirebaseDocStorage(firebase.firestore());
    _pubsubInstance = new PubSubClient(platform_constants.publishUrl, user);
    controller.command(controller.UIAction.userSignedIn, new controller.UserData(user.displayName, user.email, photoURL));
  });
}

firebase.Auth get firebaseAuth => firebase.auth();

/// Signs the user in.
signIn() {
  var provider = new firebase.GoogleAuthProvider();
  firebaseAuth.signInWithPopup(provider);
}

/// Signs the user out.
signOut() {
  firebaseAuth.signOut();
}

/// Returns true if a user is signed-in.
bool isUserSignedIn() {
  return firebaseAuth.currentUser != null;
}

Future<void> sendMessage(String id, String message) {
  log.verbose("Sending message $id : $message");

  return sendMultiMessage([id], message);
}

Future<void> sendMultiMessage(List<String> ids, String message) {
  log.verbose("Sending multi-message $ids : $message");

  //  {
  //  "action" : "send_to_multi_ids"
  //  "ids" : [ "nook-uuid-23dsa" ],
  //  "message" : "🐱"
  //  }

  Map payload =
    {
      'action' : _SEND_TO_MULTI_IDS_ACTION,
      'ids' : ids,
      'message' : message
    };

  return _pubsubInstance.publish(platform_constants.smsTopic, payload);
}

void listenForSystemMessages(SystemMessageCollectionListener listener) =>
    SystemMessage.listen(_docStorage, listener);

void listenForConversationListShards(ConversationListShardCollectionListener listener) {
  ConversationListShard.listen(_docStorage, listener);
}

StreamSubscription listenForConversations(ConversationCollectionListener listener, String conversationListRoot) {
  return Conversation.listen(_docStorage, listener, collectionRoot: conversationListRoot);
}

void listenForConversationTags(TagCollectionListener listener) =>
    Tag.listen(_docStorage, listener, "/conversationTags");

void listenForMessageTags(TagCollectionListener listener) =>
    Tag.listen(_docStorage, listener, "/messageTags");

void listenForSuggestedReplies(SuggestedReplyCollectionListener listener) =>
    SuggestedReply.listen(_docStorage, listener);

Future<void> updateSuggestedReplyTranslation(SuggestedReply reply, String newText) {
  log.verbose("Updating suggested reply translation ${reply.suggestedReplyId}, '$newText'");
  return reply.setTranslation(_pubsubInstance, newText);
}

Future<void> addMessageTag(Conversation conversation, Message message, String tagId) {
  log.verbose("Adding tag $tagId to message in conversation ${conversation.docId}");
  return message.addTagId(_pubsubInstance, conversation, tagId);
}

Future<void> removeMessageTag(Conversation conversation, Message message, String tagId) {
  log.verbose("Removing tag $tagId from message in conversation ${conversation.docId}");
  return message.removeTagId(_pubsubInstance, conversation, tagId);
}

Future<void> setMessageTranslation(Conversation conversation, Message message, String translation) {
  log.verbose("Set translation for message in conversation ${conversation.docId}");
  return message.setTranslation(_pubsubInstance, conversation, translation);
}

Future<void> updateNotes(Conversation conversation, String updatedText) {
  log.verbose("Updating conversation notes for ${conversation.docId}");
  return conversation.setNotes(_pubsubInstance, updatedText);
}

Future<void> updateUnread(List<Conversation> conversations, bool newValue) {
  log.verbose("Updating unread=$newValue for ${
    conversations.length == 1
      ? conversations[0].docId
      : "${conversations.length} conversations"
  }");
  return Conversation.setUnreadForAll(_pubsubInstance, conversations, newValue);
}

Future<void> addConversationTag(Conversation conversation, String tagId) {
  log.verbose("Adding tag $tagId to ${conversation.docId}");
  return conversation.addTagId(_pubsubInstance, tagId);
}

Future<void> addConversationTag_forAll(List<Conversation> conversations, String tagId) {
  log.verbose("Adding tag $tagId to ${conversations.length} conversations");
  return Conversation.addTagIdToAll(_pubsubInstance, conversations, tagId);
}

Future<void> removeConversationTag(Conversation conversation, String tagId) {
  log.verbose("Removing tag $tagId from ${conversation.docId}");
  return conversation.removeTagId(_pubsubInstance, tagId);
}
