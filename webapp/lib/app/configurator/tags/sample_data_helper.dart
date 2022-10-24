import 'package:firebase/firestore.dart' as firestore;
import 'package:katikati_ui_lib/components/model/model.dart';

Future<List<Message>> getSampleMessages(firestore.Firestore fs, String projectId, String tagId) async {
  var snapshot = await fs.collection("projects/${projectId}/nook_conversation_shards/shard-0/conversations")
    .where("tags", "array-contains", tagId)
    .limit(50)
    .get();

  var messageTexts = <Message>[];

  for (var doc in snapshot.docs) {
    var data = doc.data();
    var messages = data["messages"];
    for (var message in messages) {
      var tags = (message["tags"] as List);
      if (tags.contains(tagId)) {
        messageTexts.add(Message.fromData(message));
      }
    }
  }
  return messageTexts;
}
