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

  typedef ConversationListener(List<Conversation> conversations);

  Conversation _firestoreConversationToModelConversation(firestore.DocumentSnapshot conversation) {
    log.verbose("_firestoreConversationToModelConversation: ${conversation.id}");

    var data = conversation.data();

    List conversationTagIds = data["tags"];
    List<Tag> allConversationTags = controller.conversationTags;
    List<Tag> conversationTags = allConversationTags.where((tag) => conversationTagIds.contains(tag.tagId)).toList();

    List<Message> messages = [];
    List<Tag> allMessageTags = controller.messageTags;
    for (Map messageData in data["messages"]) {
     //{datetime: 2019-05-10T15:19:13.567929+00:00, direction: out, tags: [], text: test message, translation: }
      List tagIds = messageData["tags"];
      List<Tag> messageTags = allMessageTags.where((tag) => tagIds.contains(tag.tagId)).toList();
      messages.add(
        Message.fromData(messageData)
          ..tags = messageTags
      );
    }

    return Conversation.fromFirestore(conversation)
      ..tags = conversationTags
      ..messages = messages;
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
        ret.add(Tag.fromFirestore(tag));
      });
      listener(ret);
    });
  }

  typedef SuggestedRepliesListener(List<SuggestedReply> replies);

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
        ret.add(SuggestedReply.fromFirestore(suggestedReply));
      });
      listener(ret);
    });
  }

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

    var messageMaps = [];
    for (Message msg in conversation.messages) {
      messageMaps.add({
        "direction" : MessageDirection_toString(msg.direction),
        "datetime" : msg.datetime.toIso8601String(),
        "text" : msg.text,
        "translation" : msg.translation,
        "tags" : msg.tags.map((t) => t.tagId).toList()
      });
    }

    return _firestoreInstance.doc("nook_conversations/${conversation.deidentifiedPhoneNumber.value}").update(
      data : {"messages" : messageMaps}
    );
  }

  Future updateNotes(Conversation conversation) {
    log.verbose("Updating conversation notes for ${conversation.deidentifiedPhoneNumber.value}");
    return _firestoreInstance.doc("nook_conversations/${conversation.deidentifiedPhoneNumber.value}").update(
      data: {"notes" : conversation.notes}
    );
  }

  Future updateConversationTags(Conversation conversation) {
    log.verbose("Updating conversation tags for ${conversation.deidentifiedPhoneNumber.value}");
    return _firestoreInstance.doc("nook_conversations/${conversation.deidentifiedPhoneNumber.value}").update(
      data: {"tags" : conversation.tags.map((t) => t.tagId).toList()}
    );
  }

  Future updateConversation(Map conversationData) async {
    // TODO(mariana): implement commication with Firebase/PubSub here
  }
