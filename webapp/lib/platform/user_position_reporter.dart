import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'platform.dart';

class UserPositionReporter {
  Platform platform;

  UserPositionReporter(this.platform);

  Future reportPresence(model.User user, model.Conversation conversation) {
    print ("Reporting: ${user.userEmail} : ${conversation.docId}");
    return platform.docStorage.fs.doc("projects/${platform.appController.urlManager.project}/user_presence/${user.userEmail}").set(
      {
        "timestamp" : DateTime.now().toUtc().toIso8601String(), // TODO replace with server time
        "conversation_id" : conversation.docId
      }
    );
  }
}
