import 'package:firebase/firestore.dart' as firestore;

Future<List<String>> getSampleMessages(firestore.Firestore fs, String tagId) async {
  var snapshot = await fs.collection("/nook_conversation_shards/shard-0/conversations")
    .where("tags", "array-contains", tagId)
    .limit(50)
    .get();

  var messageTexts = <String>[];

  for (var doc in snapshot.docs) {
    var data = doc.data();
    var messages = data["messages"];
    for (var message in messages) {
      var tags = (message["tags"] as List);
      if (tags.contains(tagId)) {
        messageTexts.add(message["text"]);
      }
    }
  }
  return messageTexts;
}
