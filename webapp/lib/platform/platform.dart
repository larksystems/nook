import "dart:async";
import 'dart:html';

import 'package:firebase/firebase.dart' as firebase;
import 'package:katikati_ui_lib/datatypes/doc_storage_util.dart' show DocQuery;

import 'package:nook/controller.dart' as controller;
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/model/model.dart';
import 'package:katikati_ui_lib/components/platform/doc_storage_firebase.dart';
import 'package:katikati_ui_lib/components/platform/platform_constants.dart' as platform_constants;
import 'package:katikati_ui_lib/components/platform/platform.dart' as platform;
export 'package:katikati_ui_lib/components/platform/platform.dart';
import 'package:katikati_ui_lib/components/platform/pubsub.dart';

/// The client version used to track client/server API changes
/// and passed to the server during each heartbeat
String clientVersion = '1.0.1';

Logger log = new Logger('platform.dart');

const _SEND_MESSAGES_TO_IDS_ACTION = "send_messages_to_ids";

const _LOG_SUFFIX = '-log';
const _PUBLISH_SUFFIX = '-publish';
const _PUBLISH_TOPIC_SUFFIX = '-pubsub';
const _STATUSZ_SUFFIX = '-statusz';

class Platform {
  controller.Controller appController;

  StreamSubscription _projectSubscription;
  StreamSubscription _tagSubscription;
  StreamSubscription _suggestedRepliesSubscription;
  StreamSubscription _userPresenceSubscription;
  StreamSubscription _userConfigSubscription;
  StreamSubscription _systemMessagesSubscription;
  StreamSubscription _shardsSubscription;
  StreamSubscription _conversationsSubscriptions;
  StreamSubscription _uuidMappingsSubscription;

  DocStorage _docStorage;
  DocStorage _projectDocStorage;
  PubSubClient _pubsubInstance;
  PubSubClient _pubsubLogInstance;
  PubSubClient _uptimePubSubInstance;
  firebase.Storage _imagesBucket;

  PubSubClient get pubsubInstance => _pubsubInstance;

  Platform(this.appController) {
    platform.init("/assets/firebase_constants.json", (user) {
      String photoURL = platform.firebaseAuth.currentUser.photoURL;
      if (photoURL == null) {
        photoURL =  '/assets/user_image_placeholder.png';
      }
      _docStorage = FirebaseDocStorage(firebase.firestore());
      var firebaseCollectionPrefix = appController.urlManager.project != null ? '/projects/${appController.urlManager.project}' : null;
      _projectDocStorage = FirebaseDocStorage(firebase.firestore(), collectionPathPrefix: firebaseCollectionPrefix);
      _imagesBucket = firebase.app().storage("gs://${firebase.app().options.projectId}-telegram-images");

      var projectName = appController.urlManager.project ?? "base"; // Use [base] if we're on the project selection page
      var baseUrl = '${platform_constants.cloudFunctionsUrlDomain}${projectName}';
      _pubsubInstance = new PubSubClient('$baseUrl$_PUBLISH_SUFFIX', '$projectName$_PUBLISH_TOPIC_SUFFIX', user);
      _pubsubLogInstance = new PubSubClient('$baseUrl$_LOG_SUFFIX', '$projectName$_LOG_SUFFIX', user);
      _uptimePubSubInstance = new PubSubClient('$baseUrl$_STATUSZ_SUFFIX', '$projectName$_STATUSZ_SUFFIX', user);

      appController.command(controller.BaseAction.userSignedIn, new controller.UserData(user.displayName, user.email, photoURL));
      initUptimeMonitoring();
    }, () {
      _pubsubInstance = null;
      _pubsubLogInstance = null;
      appController.command(controller.BaseAction.userSignedOut, null);
    });
    Logger.platform = this;
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
          'lastUserActivity': appController.lastUserActivity.toIso8601String(),
          'clientVersion': clientVersion,
        };
        _uptimePubSubInstance.publish(payload).then(
          (_) {
            log.debug('Uptime ping ${t.tick}.${tt.tick} successful');

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

            appController.systemMessages.remove(systemMessage);
            appController.command(controller.BaseAction.updateSystemMessages, new controller.SystemMessagesData(appController.systemMessages));
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

            if (appController.systemMessages.contains(systemMessage)) {
              // Message is already displayed, nothing else to do.
              return;
            }
            appController.systemMessages.add(systemMessage);
            appController.command(controller.BaseAction.updateSystemMessages, new controller.SystemMessagesData(appController.systemMessages));
          });
      });
    };

    // Heartbeat to check internet connectivity and notify server of the version being used
    new Timer.periodic(oneMinute, (Timer t) {
      Map payload = {
        'ping': '${t.tick}',
        'lastUserActivity': appController.lastUserActivity.toIso8601String(),
        'clientVersion': clientVersion,
      };
      // TODO Prompt user to refresh browser if a heartbeat response from server indicates that the client is out of date
      _uptimePubSubInstance.publish(payload).then(
        (_) {
          log.debug('Uptime ping ${t.tick} successful');

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
            appController.systemMessages.remove(systemMessage);
            appController.command(controller.BaseAction.updateSystemMessages, new controller.SystemMessagesData(appController.systemMessages));
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

          if (appController.systemMessages.contains(systemMessage)) {
            // Message is already displayed, nothing else to do.
            return;
          }
          appController.systemMessages.add(systemMessage);
          appController.command(controller.BaseAction.updateSystemMessages, new controller.SystemMessagesData(appController.systemMessages));
        });
    });
  }

  signIn({String domain}) => platform.signIn(domain: domain);

  signOut() {
    _projectSubscription?.cancel();
    _tagSubscription?.cancel();
    _suggestedRepliesSubscription?.cancel();
    _userPresenceSubscription?.cancel();
    _userConfigSubscription?.cancel();
    _systemMessagesSubscription?.cancel();
    _shardsSubscription?.cancel();
    _conversationsSubscriptions?.cancel();
    platform.signOut();
  }

  bool isUserSignedIn() => platform.isUserSignedIn();

  Future<String> getImageUrl(String filePath) async {
    return (await imageStorage.ref(filePath).getDownloadURL()).toString();
  }

  FirebaseDocStorage get docStorage => _docStorage;
  FirebaseDocStorage get projectDocStorage => _projectDocStorage;
  firebase.Storage get imageStorage => _imagesBucket;

  void listenForProjects(ProjectCollectionListener listener, [OnErrorListener onErrorListener]) {
    _projectSubscription = Project.listen(_docStorage, listener, queryList: [FirebaseQuery('users', FirebaseQuery.ARRAY_CONTAINS, appController.signedInUser.userEmail)], onError: onErrorListener);
  }

  void listenForUserConfigurations(UserConfigurationCollectionListener listener, [OnErrorListener onErrorListener]) {
    _userConfigSubscription = UserConfiguration.listen(_projectDocStorage, listener, onError: onErrorListener);
  }

  void listenForSystemMessages(SystemMessageCollectionListener listener, [OnErrorListener onErrorListener]) {
    _systemMessagesSubscription = SystemMessage.listen(_projectDocStorage, listener, onErrorListener: onErrorListener);
  }


  void listenForConversationListShards(ConversationListShardCollectionListener listener, [OnErrorListener onErrorListener]) {
    _shardsSubscription =  ConversationListShard.listen(_projectDocStorage, listener, onError: onErrorListener);
  }

  StreamSubscription listenForConversations(ConversationCollectionListener listener, String conversationListRoot, [OnErrorListener onErrorListener, List<DocQuery> queryList]) {
    _conversationsSubscriptions = Conversation.listen(_projectDocStorage, listener, collectionRoot: conversationListRoot, onErrorListener: onErrorListener, queryList: queryList);
    return _conversationsSubscriptions;
  }

  void listenForTags(TagCollectionListener listener, [OnErrorListener onErrorListener]) {
    _tagSubscription = Tag.listen(_projectDocStorage, listener, collectionRoot: "/tags", onError: onErrorListener);
  }

  void listenForSuggestedReplies(SuggestedReplyCollectionListener listener, [OnErrorListener onErrorListener]) {
    _suggestedRepliesSubscription = SuggestedReply.listen(_projectDocStorage, listener, onError: onErrorListener);
  }

  void listenForUserPresence(UserPresenceCollectionListener listener, [OnErrorListener onErrorListener]) {
    _userPresenceSubscription = UserPresence.listen(_projectDocStorage, listener, onError: onErrorListener);
  }

  StreamSubscription listenForUuidMappings(DataMapListener listener, [OnErrorListener onErrorListener]) {
    _uuidMappingsSubscription = DataMap.listen(_projectDocStorage, listener, 'tables/uuid-table/mappings', onError: onErrorListener);
    return _uuidMappingsSubscription;
  }

  Future<void> sendMultiMessage(List<String> ids, String message, {bool wasSuggested = false, onError(dynamic)}) async {
    log.verbose("Sending multi-message $ids : $message");
    return sendMultiMessages(ids, [message], wasSuggested: wasSuggested, onError: onError);
  }

  Future<void> sendMultiMessages(List<String> ids, List<String> messages, {bool wasSuggested = false, onError(dynamic)}) async {
    log.verbose("Sending multi-message $ids : $messages");

    //  {
    //  "action" : "send_messages_to_ids"
    //  "ids" : [ "nook-uuid-23dsa" ],
    //  "messages" : [ "🐱" ]
    //  }
    Map payload =
      {
        'action' : _SEND_MESSAGES_TO_IDS_ACTION,
        'ids' : ids,
        'messages' : messages,
        'was_suggested' : wasSuggested,
      };

    try {
      return await _pubsubInstance.publish(payload);
    } catch (error, trace) {
      if (onError != null) onError(error);
      // Rethrow so that others could handle it
      // and so that it is logged through the normal process
      rethrow;
    }
  }

  void serverLog(String message, onError(dynamic)) async {
    Map payload = {
      'user': appController.signedInUser.userEmail,
      'datetime': DateTime.now().toUtc().toIso8601String(),
      'data': message,
    };

    _pubsubLogInstance
      .publish(payload)
      .then((_) => {}, onError: (error, trace) { if (onError != null) onError(error); });
  }

  Future<void> addMessageTag(Conversation conversation, Message message, String tagId) {
    log.verbose("Adding tag $tagId to message in conversation ${conversation.docId}");
    return message.addTagId(_pubsubInstance, conversation, tagId);
  }

  Future<void> removeMessageTag(Conversation conversation, Message message, String tagId) {
    log.verbose("Removing tag $tagId from message in conversation ${conversation.docId}");
    return message.removeTagId(_pubsubInstance, conversation, tagId);
  }

  Future<void> confirmMessageTag(Conversation conversation, Message message, String tagId) {
    log.verbose("Confirming suggested tag $tagId from message in conversation ${conversation.docId}");
    return message.addTagId(_pubsubInstance, conversation, tagId, wasSuggested: true);
  }

  Future<void> rejectMessageTag(Conversation conversation, Message message, String tagId) {
    log.verbose("Removing suggested tag $tagId from message in conversation ${conversation.docId}");
    return message.removeTagId(_pubsubInstance, conversation, tagId, wasSuggested: true);
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

  Future<void> confirmConversationTag(Conversation conversation, String tagId) {
    log.verbose("Confirming suggested tag $tagId to ${conversation.docId}");
    return conversation.addTagIds(_pubsubInstance, [tagId], wasSuggested: true);
  }

  Future<void> rejectConversationTag(Conversation conversation, String tagId) {
    log.verbose("Removing suggested tag $tagId from ${conversation.docId}");
    return conversation.removeTagIds(_pubsubInstance, [tagId], wasSuggested: true);
  }

  Future<void> rejectSuggestedMessages(Conversation conversation) {
    log.verbose("Removing suggested messages from ${conversation.docId}");
    return conversation.removeSuggestedMessages(_pubsubInstance);
  }

  Future<void> addTag(Tag tag) {
    log.verbose("Adding new tag ${tag.tagId} to tag list");
    var tagData = tag.toData();
    tagData['__id'] = tag.docId;
    return _pubsubInstance.publishAddOpinion('nook/set_tag', tagData);
  }

  Future<void> setProjectInfo(Project project) {
    log.verbose(("Updating ${project.projectId} info"));
    var projectData = project.toData();
    projectData['__id'] = project.docId;
    projectData.remove('_authenticatedUserEmail');
    projectData.remove('_authenticatedUserDisplayName');
    return _pubsubInstance.publishAddOpinion('nook/set_project_config', projectData);
  }

  Future<void> setUserConfigField(String user, String field, dynamic value) {
    log.verbose(("Setting $field to $value for $user"));
    return _pubsubInstance.publishAddOpinion('nook/set_user_config', {
      '__id': user,
      field: value
    });
  }

  Future<void> addUser(String user) {
    log.verbose(("Adding user $user"));
    return _pubsubInstance.publishAddOpinion('nook/add_user', {
      '__id': user,
      'role': 'UserRole.user',
      'status': 'UserStatus.active',
    });
  }

  Future<void> updateTags(List<Tag> tags) {
    List<Future> futures = [];

    for (Tag tag in tags) {
      futures.add(_pubsubInstance.publishAddOpinion('nook/set_tag', tag.toData()..putIfAbsent('__id', () => tag.tagId)));
    }

    return Future.wait(futures);
  }

  Future<void> updateSuggestedReplies(List<SuggestedReply> replies) {
    List<Future> futures = [];

    for (SuggestedReply suggestedReply in replies) {
      futures.add(_pubsubInstance.publishAddOpinion('nook/set_suggested_reply', suggestedReply.toData()..putIfAbsent('__id', () => suggestedReply.suggestedReplyId)));
    }

    return Future.wait(futures);
  }

  Future<void> deleteTags(List<Tag> tags) {
    List<Future> futures = [];

    for (Tag tag in tags) {
      futures.add(_pubsubInstance.publishAddOpinion('nook/del_tag', tag.toData()..putIfAbsent('__id', () => tag.tagId)));
    }

    return Future.wait(futures);
  }

  Future<void> deleteSuggestedReplies(List<SuggestedReply> replies) {
    List<Future> futures = [];

    for (SuggestedReply suggestedReply in replies) {
      futures.add(_pubsubInstance.publishAddOpinion('nook/del_suggested_reply', suggestedReply.toData()..putIfAbsent('__id', () => suggestedReply.suggestedReplyId)));
    }

    return Future.wait(futures);
  }
}
