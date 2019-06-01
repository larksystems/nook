import "dart:convert";
import "dart:async";

import 'package:http/browser_client.dart';
import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;

import 'logger.dart';
import 'mock_data.dart' as data;
import 'controller.dart' as controller;
import 'platform_constants.dart' as platform_constants;

import 'model.dart';

Logger log = new Logger('platform_utils.dart');

const _SEND_TO_MULTI_IDS_ACTION = "send_to_multi_ids";
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
      controller.command(controller.UIAction.userSignedIn, new controller.UserData(user.displayName, user.email, photoURL));

      _firestoreInstance = firebase.firestore();
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

  Future loadConversations() {
    log.verbose('Loading conversations');

    return new Future.value(data.conversations);
  }
  
  typedef TagsUpdatedListener(List<Tag> tags);
  Tag _firestoreTagToModelTag(firestore.DocumentSnapshot tag) {
    var data = tag.data();
    return new Tag()
        ..shortcut = data["shortcut"]
        ..tagId = tag.id
        ..text = data["text"]
        ..type = data["type"] == "important" ? TagType.Important : TagType.Normal; // TODO: Generalise
  }
  
  
  void listenForConversationTags(TagsUpdatedListener listener) => _listenForTags(listener, "/conversationTags");
  void listenForMessageTags(TagsUpdatedListener listener) => _listenForTags(listener, "/messageTags");

  void _listenForTags(TagsUpdatedListener listener, String tagCollectionRoot) async {
    log.verbose('Loading tags from $tagCollectionRoot');
    log.verbose("Root of query: $tagCollectionRoot");

    _firestoreInstance.collection(tagCollectionRoot).onSnapshot.listen((querySnapshot) {
      // No need to process local writes to Firebase
      if (querySnapshot.metadata.hasPendingWrites) {
        log.verbose("Skipping processing of local changes");
        return;
      }

      log.verbose("Starting processing ${querySnapshot.docChanges().length} tags.");

      List<Tag> ret = [];
      querySnapshot.docChanges().forEach((documentChange) {
        var tag = documentChange.doc;
        log.verbose("Processing ${tag.id}");
        ret.add(_firestoreTagToModelTag(tag));
      });
      listener(ret);
    });
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
