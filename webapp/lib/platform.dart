import "dart:async";

import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;

import 'controller.dart' as controller;
import 'logger.dart';
import 'model.dart';
import 'model_firebase.dart';
import 'platform_constants.dart' as platform_constants;
import 'pubsub.dart';

Logger log = new Logger('platform.dart');

const _SEND_TO_MULTI_IDS_ACTION = "send_to_multi_ids";

firestore.Firestore _firestoreInstance;
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
    _firestoreInstance = firebase.firestore();
    _docStorage = FirebaseDocStorage(_firestoreInstance);
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

Future<bool> sendMessage(String id, String message) {
  log.verbose("Sending message $id : $message");

  return sendMultiMessage([id], message);
}

Future<bool> sendMultiMessage(List<String> ids, String message) {
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

void listenForConversations(ConversationCollectionListener listener) {
  listenForUpdates<Conversation>(_docStorage, listener, "/${Conversation.collectionName}", (DocSnapshot conversation) {
    log.verbose("_firestoreConversationToModelConversation: ${conversation.id}");
    return Conversation.fromSnapshot(conversation);
  });
}

void listenForConversationTags(TagCollectionListener listener) =>
    Tag.listen(_docStorage, listener, "/conversationTags");

void listenForMessageTags(TagCollectionListener listener) =>
    Tag.listen(_docStorage, listener, "/messageTags");

void listenForSuggestedReplies(SuggestedReplyCollectionListener listener) =>
    SuggestedReply.listen(_docStorage, listener);

Future updateSuggestedReply(SuggestedReply reply) {
  log.verbose("Updating suggested Reply ${reply.suggestedReplyId}");

  return _firestoreInstance.doc("${SuggestedReply.collectionName}/${reply.suggestedReplyId}").update(
    data: {
      "shortcut" : reply.shortcut,
      "text" : reply.text,
      "translation" : reply.translation
    }
  );
}

Future updateConversationMessages(Conversation conversation) {
  log.verbose("Updating conversation messages for ${conversation.deidentifiedPhoneNumber.value}");
  return conversation.updateMessages(_docStorage, conversation.documentPath, conversation.messages).commit();
}

Future updateNotes(Conversation conversation) {
  log.verbose("Updating conversation notes for ${conversation.deidentifiedPhoneNumber.value}");
  return conversation.updateNotes(_docStorage, conversation.documentPath, conversation.notes).commit();
}

Future updateUnread(List<Conversation> conversations, bool newValue) async {
  log.verbose("Updating unread=$newValue for ${
    conversations.length == 1
      ? conversations[0].deidentifiedPhoneNumber.value
      : "${conversations.length} conversations"
  }");
  if (conversations.isEmpty) return null;
  for (var conversation in conversations) {
    await conversation.setUnread(_pubsubInstance, newValue);
  }
}

Future updateConversationTags(Conversation conversation) {
  log.verbose("Updating conversation tags for ${conversation.deidentifiedPhoneNumber.value}");
  return conversation.updateTagIds(_docStorage, conversation.documentPath, conversation.tagIds).commit();
}
