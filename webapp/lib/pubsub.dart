import "dart:async";
import "dart:convert";

import 'package:http/browser_client.dart';

import 'logger.dart';

Logger log = new Logger('pubsub.dart');

class PubSubClient {
  final String publishUrl;

  // The firebase token used to authenticate pub/sub operations.
  // This is dynamically set and cleared when a user signs in and out.
  String fbUserIdToken;

  PubSubClient(this.publishUrl);

  Future<bool> publish(String topic, Map payload) async {
    log.verbose("publish $topic $payload");
    String body = json.encode({
      "topic": topic,
      "payload": payload,
      "fbUserIdToken": fbUserIdToken,
    });
    log.verbose("publish About to send: ${body}");

    var client = new BrowserClient();
    var response = await client.post(publishUrl, body: body);

    log.verbose("publish response ${response.statusCode}, ${response.body}");
    return response.statusCode == 200;
  }
}
