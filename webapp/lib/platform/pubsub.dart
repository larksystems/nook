import "dart:async";
import "dart:convert";

import 'package:firebase/firebase.dart' as firebase;
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/platform/platform_constants.dart' as platform_constants;
import 'package:katikati_ui_lib/components/model/model.dart' show DocPubSubUpdate;

Logger log = new Logger('pubsub.dart');

class PubSubClient extends DocPubSubUpdate {
  final String publishUrl;
  static int _publishCount = 0;

  // The firebase user from which the user JWT auth token is obtained.
  final firebase.User user;

  PubSubClient(this.publishUrl, this.user);

  /// Publish the specified [payload] to the [topic].
  /// Callers should catch and handle HTTP exceptions (e.g. PubSubException, ClientException).
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
  Future<void> publishAddOpinion(String namespace,
      Map<String, dynamic> opinion) {
    return publish(platform_constants.smsTopic, {
      "source": "nook",
      "action": "add_opinion",
      "namespace": namespace,
      "opinion": opinion,
    });
  }
}

class PubSubException implements Exception {
  final String message;

  static fromResponse(Response response) =>
      PubSubException('[${response.statusCode}] ${response.reasonPhrase}, response.headers: ${response.headers}');

  PubSubException(this.message);

  @override
  String toString() => 'PubSubException: $message';
}
