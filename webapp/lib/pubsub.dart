import "dart:async";
import "dart:convert";

import 'package:firebase/firebase.dart' as firebase;
import 'package:http/browser_client.dart';

import 'logger.dart';
import 'model.dart' show DocPubSubUpdate;
import 'platform_constants.dart' as platform_constants;

Logger log = new Logger('pubsub.dart');

class PubSubClient extends DocPubSubUpdate {
  final String publishUrl;

  // The firebase user from which the user JWT auth token is obtained.
  final firebase.User user;

  PubSubClient(this.publishUrl, this.user);

  Future<bool> publish(String topic, Map payload) async {
    log.verbose("publish $topic $payload");

    // The user JWT auth token used to authorize the pub/sub operation
    // is only valid for 1 hour. Don't cache it so that the firebase
    // user object can manage refreshing it as needed.
    // See https://firebase.google.com/docs/auth/admin/manage-sessions

    String body = json.encode({
      "topic": topic,
      "payload": payload,
      "fbUserIdToken": await user.getIdToken(),
    });
    log.verbose("publish About to send: ${body}");

    var client = new BrowserClient();
    var response = await client.post(publishUrl, body: body);

    log.verbose("publish response ${response.statusCode}, ${response.body}");
    return response.statusCode == 200;
  }

  @override
  Future<bool> publishDocChange(String collectionName, List<String> docIds,
      Map<String, dynamic> changes) {
    return publish(platform_constants.smsTopic, {
      "action": "update_firebase",
      "collection": collectionName,
      "ids": docIds,
      "changes": changes,
    });
  }
}
