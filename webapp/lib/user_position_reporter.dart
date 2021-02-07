import 'package:nook/model.dart' as model;
import 'platform.dart' as platform;

class UserPositionReporter {

  UserPositionReporter();

  Future reportPresence(model.User user, model.Conversation conversation) {
    print ("Reporting: ${user.userEmail} : ${conversation.docId}");
    return platform.firestoreInstance.doc("user_presence/${user.userEmail}").set(
      {
        "Timestamp" : DateTime.now().toUtc().toIso8601String(), // TODO replace with server time
        "ConversationID" : conversation.docId
      }
    );
  }
}
