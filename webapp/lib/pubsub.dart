import "dart:async";
import "dart:convert";

import 'package:firebase/firebase.dart' as firebase;
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'logger.dart';
import 'model.dart' show DocPubSubUpdate;
import 'platform_constants.dart' as platform_constants;

Logger log = new Logger('pubsub.dart');

class PubSubClient extends DocPubSubUpdate {
  final String publishUrl;
  static int _publishCount = 0;

  // The firebase user from which the user JWT auth token is obtained.
  final firebase.User user;

  PubSubClient(this.publishUrl, this.user);

  /// Publish the specified exception.
  /// Callers should catch and handle IOException.
  Future<void> publish(String topic, Map payload) async {
    // a simplistic way to correlate publish log entries
    int publishId = _publishCount++;

    log.verbose("publish #$publishId: $topic $payload");

    payload["_authenticatedUserEmail"] = this.user.email;
    payload["_authenticatedUserDisplayName"] = this.user.displayName;

    // The user JWT auth token used to authorize the pub/sub operation
    // is only valid for 1 hour. Don't cache it so that the firebase
    // user object can manage refreshing it as needed.
    // See https://firebase.google.com/docs/auth/admin/manage-sessions

    String body = json.encode({
      "topic": topic,
      "payload": payload,
      "fbUserIdToken": await user.getIdToken(),
    });
    log.verbose("publish About to send #$publishId: ${body}");

    var client = new BrowserClient();
    var response = await client.post(publishUrl, body: body);

    log.verbose("publish response #$publishId: ${response.statusCode}, ${response.body}");
    if (response.statusCode != 200)
      throw PubSubException.fromResponse(response);
  }

  @override
  Future<void> publishDocAdd(String collectionName, List<String> docIds,
      Map<String, List<dynamic>> additions) {
    return publish(platform_constants.smsTopic, {
      "action": "update_firebase",
      "collection": collectionName,
      "ids": docIds,
      "additions": additions,
    });
  }

  @override
  Future<void> publishDocChange(String collectionName, List<String> docIds,
      Map<String, dynamic> changes) {
    return publish(platform_constants.smsTopic, {
      "action": "update_firebase",
      "collection": collectionName,
      "ids": docIds,
      "changes": changes,
    });
  }

  @override
  Future<void> publishDocRemove(String collectionName, List<String> docIds,
      Map<String, List<dynamic>> removals) {
    return publish(platform_constants.smsTopic, {
      "action": "update_firebase",
      "collection": collectionName,
      "ids": docIds,
      "removals": removals,
    });
  }
}

class PubSubException implements Exception {
  final String message;

  static fromResponse(Response response) =>
      PubSubException('[${response.statusCode}] ${response.reasonPhrase}');

  PubSubException(this.message);

  @override
  String toString() => 'PubSubException: $message';
}
