import "dart:convert";
import 'package:http/browser_client.dart';
import 'package:firebase/firebase.dart' as firebase;

import "logger.dart";
import 'mock_data.dart' as data;
import 'controller.dart' as controller;

Logger log = new Logger('platform_utils.dart');

const _SEND_TO_MULTI_IDS_ACTION = "send_to_multi_ids";


class PlatformUtils {
  String publishUrl;

  String _SMS_TOPIC;


  PlatformUtils(this.publishUrl, String todo_fix_arg_list) {
    final projectId = "nook-development"; // TODO load this from config
    firebase.initializeApp(
      apiKey: "AIzaSyB0XIxv0aTw3cwQlYc2Q_pxQ_XNVgLo9Yo",
      authDomain: "nook-development.firebaseapp.com",
      databaseURL: "https://nook-development.firebaseio.com",
      projectId: projectId,
      storageBucket: "nook-development.appspot.com",
      messagingSenderId: "504684479642");

    this._SMS_TOPIC = projectId + "-sms-channel-topic";

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

    String payload = json.encode(
      {
        'action' : _SEND_TO_MULTI_IDS_ACTION,
        'ids' : ids,
        'message' : message
      }
    );

    return _sendPubSubMessage(this._SMS_TOPIC, payload);
  }

  Future _sendPubSubMessage(String topic, String message) async {
    log.verbose("_sendPubSubMessage $topic $message");
    var client = new BrowserClient();
    var response = await client.post(publishUrl, body: json.encode({"topic":topic,"message": message }));

    log.verbose("_sendPubSubMessage response ${response.statusCode}, ${response.body}");
    return response.statusCode == 200;
  }

  Future loadConversations() {
    log.verbose('Loading conversations');

    return new Future.value(data.conversations);
  }


  Future loadConversationTags() {
    log.verbose('Loading conversation tags');

    return new Future.value(data.conversationTags);
  }

  Future loadMessageTags() {
    log.verbose('Loading message tags');

    return new Future.value(data.messageTags);
  }

  Future loadSuggestedReplies() {
    log.verbose('Loading suggested replies');

    return new Future.value(data.suggestedReplies);
  }

  Future updateConversation(Map conversationData) async {
    // TODO(mariana): implement commication with Firebase/PubSub here
  }
}
