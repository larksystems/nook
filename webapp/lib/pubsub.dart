import "dart:async";
import "dart:convert";

import 'package:http/browser_client.dart';

import 'logger.dart';

Logger log = new Logger('pubsub.dart');

class PubSubClient {
  final String publishUrl;

  PubSubClient(this.publishUrl);

  Future<bool> publish(String topic, Map payload) async {
    log.verbose("publish $topic $payload");
    String body = json.encode({"topic": topic, "payload": payload});
    log.verbose("publish About to send: ${body}");

    var client = new BrowserClient();
    var response = await client.post(publishUrl, body: body);

    log.verbose("publish response ${response.statusCode}, ${response.body}");
    return response.statusCode == 200;
  }
}
