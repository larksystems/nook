import "dart:convert";
import "dart:async";

import 'package:http/browser_client.dart';
import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;

import 'logger.dart';
import 'controller.dart' as controller;
import 'platform_constants.dart' as platform_constants;

import 'model.dart';

Logger log = new Logger('platform_utils.dart');

const _SEND_TO_MULTI_IDS_ACTION = "send_to_multi_ids";
const _MAX_BATCH_SIZE = 250;
firestore.Firestore _firestoreInstance;

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
  firebaseAuth.onAuthStateChanged.listen((firebase.User user) {
    if (user == null) { // User signed out
      controller.command(controller.UIAction.userSignedOut, null);
      return;
    }
    // User signed in
    String photoURL = firebaseAuth.currentUser.photoURL;
    if (photoURL == null) {
      photoURL =  '/assets/user_image_placeholder.png';
    }
    _firestoreInstance = firebase.firestore();
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

Future sendMessage(String id, String message) {
  log.verbose("Sending message $id : $message");

  return sendMultiMessage([id], message);
}

Future sendMultiMessage(List<String> ids, String message) {
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

  return _sendPubSubMessage(platform_constants.smsTopic, payload);
}

Future _sendPubSubMessage(String topic, Map payload) async {
  log.verbose("_sendPubSubMessage $topic $payload");
  var client = new BrowserClient();
  String body = json.encode({"topic":topic,"payload": payload });
  log.verbose("_sendPubSubMessage About to send: ${body}");

  var response = await client.post(platform_constants.publishUrl, body: body);

  log.verbose("_sendPubSubMessage response ${response.statusCode}, ${response.body}");
  return response.statusCode == 200;
}

void listenForConversations(ConversationCollectionListener listener) {
  listenForUpdates<Conversation>(_firestoreInstance, listener, "/${Conversation.collectionName}", (firestore.DocumentSnapshot conversation) {
    log.verbose("_firestoreConversationToModelConversation: ${conversation.id}");
    return Conversation.fromFirestore(conversation);
  });
}

void listenForConversationTags(TagCollectionListener listener) =>
    Tag.listen(_firestoreInstance, listener, "/conversationTags");

void listenForMessageTags(TagCollectionListener listener) =>
    Tag.listen(_firestoreInstance, listener, "/messageTags");

void listenForSuggestedReplies(SuggestedReplyCollectionListener listener) =>
    SuggestedReply.listen(_firestoreInstance, listener, "/suggestedReplies");

Future updateSuggestedReply(SuggestedReply reply) {
  log.verbose("Updating suggested Reply ${reply.suggestedReplyId}");

  return _firestoreInstance.doc("suggestedReplies/${reply.suggestedReplyId}").update(
    data: {
      "shortcut" : reply.shortcut,
      "text" : reply.text,
      "translation" : reply.translation
    }
  );
}

Future updateConversationMessages(Conversation conversation) {
  log.verbose("Updating conversation messages for ${conversation.deidentifiedPhoneNumber.value}");
  return conversation.updateMessages(_firestoreInstance, conversation.documentPath, conversation.messages).commit();
}

Future updateNotes(Conversation conversation) {
  log.verbose("Updating conversation notes for ${conversation.deidentifiedPhoneNumber.value}");
  return conversation.updateNotes(_firestoreInstance, conversation.documentPath, conversation.notes).commit();
}

Future updateUnread(List<Conversation> conversations, bool newValue) async {
  // TODO consider replacing this with pub/sub
  log.verbose("Updating unread=$newValue for ${
    conversations.length == 1
      ? conversations[0].deidentifiedPhoneNumber.value
      : "${conversations.length} conversations"
  }");
  if (conversations.isEmpty) return null;
  var batch = _firestoreInstance.batch();
  int batchSize = 0;
  for (var conversation in conversations) {
    conversation.updateUnread(_firestoreInstance, conversation.documentPath, newValue, batch);
    if (batchSize == _MAX_BATCH_SIZE) {
      await batch.commit();
      batch = _firestoreInstance.batch();
      batchSize = 0;
    }
  }
  return batch.commit();
}

Future updateConversationTags(Conversation conversation) {
  log.verbose("Updating conversation tags for ${conversation.deidentifiedPhoneNumber.value}");
  return conversation.updateTagIds(_firestoreInstance, conversation.documentPath, conversation.tagIds).commit();
}
