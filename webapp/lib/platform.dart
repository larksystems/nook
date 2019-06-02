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

  Future loadConversations() {
    log.verbose('Loading conversations');

    return new Future.value(data.conversations);
  }

  typedef ConversationListener(List<Conversation> conversations);
  DeidentifiedPhoneNumber _firestorePhoneNumberToModelNumber(String deidentifiedNo) {
    String shortValue = deidentifiedNo.split('uuid-')[1].split('-')[0];
    return new DeidentifiedPhoneNumber()
      ..shortValue = shortValue
      ..value = deidentifiedNo;
  }

  Conversation _firestoreConversationToModelConversation(firestore.DocumentSnapshot conversation) {
    String deidentifiedNo = conversation.id;
    DeidentifiedPhoneNumber deidentPhoneNumber = _firestorePhoneNumberToModelNumber(deidentifiedNo);
    var data = conversation.data();
    Map<String, String> demogInfo = {};
    for (var k in data["demographicsInfo"].keys) {
      demogInfo[k] = data["demographicsInfo"].toString();
    }
    
    List<Tag> tags = [];
    String notes = ""; // TODO

    List<Message> messages = [];
    for (Map messageData in data["messages"]) {
     //{datetime: 2019-05-10T15:19:13.567929+00:00, direction: out, tags: [], text: test message, translation: }
      MessageDirection direction = messageData["direction"] == "in" ? MessageDirection.In : MessageDirection.Out;
      DateTime dateTime = DateTime.parse(messageData["datetime"]);
      String text = messageData["text"];
      String translation = messageData["translation"];
      messages.add(
        new Message()
          ..direction = direction
          ..datetime = dateTime
          ..text = text
          ..translation = translation
          ..tags = [] // TODO
      );
    }

    return new Conversation()
      ..deidentifiedPhoneNumber = deidentPhoneNumber
      ..demographicsInfo = demogInfo
      ..tags = tags
      ..messages = messages
      ..notes = notes;
  }

  void listenForConversations(ConversationListener listener) async {
    final conversationsQueryRoot = "/nook_conversations";
    log.verbose("Root of query: $conversationsQueryRoot");

    _firestoreInstance.collection(conversationsQueryRoot).onSnapshot.listen((querySnapshot) {
      // No need to process local writes to Firebase
      if (querySnapshot.metadata.hasPendingWrites) {
        log.verbose("Skipping processing of local changes");
        return;
      }

      log.verbose("Starting processing ${querySnapshot.docChanges().length} tags.");

      List<Conversation> ret = [];
      querySnapshot.docChanges().forEach((documentChange) {
        var conversation = documentChange.doc;
        log.verbose("Processing ${conversation.id}");
        ret.add(_firestoreConversationToModelConversation(conversation));
      });
      listener(ret);
    });
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

  typedef SuggestedRepliesListener(List<SuggestedReply> replies);
  SuggestedReply _firestoreSuggestedReplyToModelSuggestedReply(firestore.DocumentSnapshot suggestedReply) {
    var data = suggestedReply.data();
    return new SuggestedReply()
        ..shortcut = data["shortcut"]
        ..suggestedReplyId = suggestedReply.id
        ..text = data["text"]
        ..translation = data["translation"];
  }

  void listenForSuggestedReplies(SuggestedRepliesListener listener) {
    final suggestedRepliesRoot = "/suggestedReplies";
    log.verbose('Loading tags from $suggestedRepliesRoot');

    _firestoreInstance.collection(suggestedRepliesRoot).onSnapshot.listen((querySnapshot) {
      // No need to process local writes to Firebase
      if (querySnapshot.metadata.hasPendingWrites) {
        log.verbose("Skipping processing of local changes");
        return;
      }

      log.verbose("Starting processing ${querySnapshot.docChanges().length} suggested replies.");

      List<SuggestedReply> ret = [];
      querySnapshot.docChanges().forEach((documentChange) {
        var suggestedReply = documentChange.doc;
        log.verbose("Processing ${suggestedReply.id}");
        ret.add(_firestoreSuggestedReplyToModelSuggestedReply(suggestedReply));
      });
      listener(ret);
    });
  }

  Future updateConversation(Map conversationData) async {
    // TODO(mariana): implement commication with Firebase/PubSub here
  }
