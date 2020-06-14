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
PubSubClient _uptimePubSubInstance;

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
    _uptimePubSubInstance = new PubSubClient(platform_constants.statuszUrl, user);
    initUptimeMonitoring();
  });
}

void initUptimeMonitoring() {
  const fiveSeconds = const Duration(seconds: 5);
  const oneMinute = const Duration(minutes: 1);

  List<bool> lastThreePingsQueue = [true, true, true]; // If all are Used for marking network disconnect
  List<bool> lastFivePingsQueue = [true, true, true, true, true]; // Used for marking network connected
  Timer fiveSecTimer;
  SystemMessage systemMessage = new SystemMessage()
      ..text = "Warning: your internet connection is unstable, some messages may not send properly. Trying to reconnect...";

  Timer Function(Timer) newFiveSecTimer = (Timer t) {
    return new Timer.periodic(fiveSeconds, (Timer tt) {
      Map payload = {
        'ping': '${t.tick}.${tt.tick}',
        'lastUserActivity': controller.lastUserActivity.toIso8601String()
      };
      _uptimePubSubInstance.publish(platform_constants.statuszTopic, payload).then(
        (_) {
          log.success('Uptime ping ${t.tick}.${tt.tick} successful');

          // Add success to the three pings queue
          lastThreePingsQueue.add(true);
          lastThreePingsQueue.removeAt(0);

          // Add success to the five pings queue
          lastFivePingsQueue.add(true);
          lastFivePingsQueue.removeAt(0);

          // Hide the warning banner if all of the last five pings were successful, and cancel the 5 sec timer
          if (lastFivePingsQueue.length != lastFivePingsQueue.where((v) => v).length) {
            return;
          }

          controller.systemMessages.remove(systemMessage);
          controller.command(controller.UIAction.updateSystemMessages, new controller.SystemMessagesData(controller.systemMessages));
          fiveSecTimer?.cancel();
        },
        onError: (error, trace) {
          log.warning('Uptime ping ${t.tick}.${tt.tick} failed: $error, $trace');

          // Add failure to the three pings queue
          lastThreePingsQueue.add(false);
          lastThreePingsQueue.removeAt(0);

          // Add failure to the five pings queue
          lastFivePingsQueue.add(false);
          lastFivePingsQueue.removeAt(0);

          // If all the last three pings failed, show the banner
          if (lastThreePingsQueue.length != lastThreePingsQueue.where((v) => !v).length) {
            return;
          }

          if (controller.systemMessages.contains(systemMessage)) {
            // Message is already displayed, nothing else to do.
            return;
          }
          controller.systemMessages.add(systemMessage);
          controller.command(controller.UIAction.updateSystemMessages, new controller.SystemMessagesData(controller.systemMessages));
        });
    });
  };

  new Timer.periodic(oneMinute, (Timer t) {
    Map payload = {
      'ping': '${t.tick}',
      'lastUserActivity': controller.lastUserActivity.toIso8601String()
    };
    _uptimePubSubInstance.publish(platform_constants.statuszTopic, payload).then(
      (_) {
        log.success('Uptime ping ${t.tick} successful');

        // Cancel the previous 5 sec timer if it's still going.
        fiveSecTimer?.cancel();

        // Add success to the three pings queue
        lastThreePingsQueue.add(true);
        lastThreePingsQueue.removeAt(0);

        // Add success to the five pings queue
        lastFivePingsQueue.add(true);
        lastFivePingsQueue.removeAt(0);

        // Hide the warning banner if the last five pings were successful.
        if (lastFivePingsQueue.length == lastFivePingsQueue.where((v) => v).length) {
          controller.systemMessages.remove(systemMessage);
          controller.command(controller.UIAction.updateSystemMessages, new controller.SystemMessagesData(controller.systemMessages));
          return;
        }

        // Some of the previous 5 pings failed, continue running the 5 sec timer until we get 5 sequential pings
        fiveSecTimer = newFiveSecTimer(t);
      },
      onError: (error, trace) {
        log.warning('Uptime ping ${t.tick} failed: $error, $trace');

        // Cancel the previous 5 sec timer if it's still going.
        fiveSecTimer?.cancel();

        // Add failure to the three pings queue
        lastThreePingsQueue.add(false);
        lastThreePingsQueue.removeAt(0);

        // Add failure to the five pings queue
        lastFivePingsQueue.add(false);
        lastFivePingsQueue.removeAt(0);

        // Start the 5 sec timer
        fiveSecTimer = newFiveSecTimer(t);

        // If all the last three pings failed, show the banner
        if (lastThreePingsQueue.length != lastThreePingsQueue.where((v) => !v).length) {
          return;
        }

        if (controller.systemMessages.contains(systemMessage)) {
          // Message is already displayed, nothing else to do.
          return;
        }
        controller.systemMessages.add(systemMessage);
        controller.command(controller.UIAction.updateSystemMessages, new controller.SystemMessagesData(controller.systemMessages));
      });
  });
}

firebase.Auth get firebaseAuth => firebase.auth();

/// Signs the user in.
signIn(String domain) {
  var provider = new firebase.GoogleAuthProvider();
  provider.setCustomParameters({'hd': domain});
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

Future<void> sendMessage(String id, String message, {onError(dynamic)}) {
  log.verbose("Sending message $id : $message");

  return sendMultiMessage([id], message, onError: onError);
}

Future<void> sendMultiMessage(List<String> ids, String message, {onError(dynamic)}) async {
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

  try {
    return await _pubsubInstance.publish(platform_constants.smsTopic, payload);
  } catch (error, trace) {
    if (onError != null) onError(error);
    // Rethrow so that others could handle it
    // and so that it is logged through the normal process
    rethrow;
  }
}

void listenForUserConfigurations(UserConfigurationCollectionListener listener) {
  UserConfiguration.listen(_docStorage, listener);
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
  var futures = <Future>[];
  for (var conversation in conversations) {
    futures.add(conversation.setUnread(_pubsubInstance, newValue));
  }
  return Future.wait(futures);
}

Future<void> addConversationTag(Conversation conversation, String tagId) {
  log.verbose("Adding tag $tagId to ${conversation.docId}");
  return conversation.addTagIds(_pubsubInstance, [tagId]);
}

Future<void> removeConversationTag(Conversation conversation, String tagId) {
  log.verbose("Removing tag $tagId from ${conversation.docId}");
  return conversation.removeTagIds(_pubsubInstance, [tagId]);
}
