import "logger.dart";
import "dart:convert";
import 'package:http/browser_client.dart';

Logger log = new Logger('platform_utils.dart');

class PlatformUtils {
  String publishUrl;

  PlatformUtils(this.publishUrl, String todo_fix_arg_list) {
    // TODO: Firebase login here
  }

  Future sendMessage(String id, String message) {
    log.verbose("Sending message $id : $message");

    return new Future.value(true);
  }

  Future sendMultiMessage(List<String> ids, String message) {
    log.verbose("Sending multi-message $ids : $message");

    return new Future.value(true);
  }


  Future _sendPubSubMessage(String topic, String message) async {
    log.verbose("_sendPubSubMessage $topic $message");
    var client = new BrowserClient();
    var response = await client.post(publishUrl, body: json.encode({"topic":topic,"message": message }));
    
    log.verbose("_sendPubSubMessage response ${response.statusCode}, ${response.body}");
  } 
}

