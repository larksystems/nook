import 'dart:async';

import 'package:firebase/firestore.dart' as firestore;

import 'logger.dart';
import 'model.dart';

Logger log = Logger('model_firebase.dart');

/// Firebase specific document storage.
class FirebaseDocStorage implements DocStorage {
  final firestore.Firestore fs;

  FirebaseDocStorage(this.fs);

  @override
  Stream<List<DocSnapshot>> onChange(String collectionRoot) {
    return fs
        .collection(collectionRoot)
        .onSnapshot
        .transform<List<DocSnapshot>>(StreamTransformer.fromHandlers(
      handleData: (firestore.QuerySnapshot querySnapshot,
          EventSink<List<DocSnapshot>> sink) {
        // No need to process local writes to Firebase
        if (querySnapshot.metadata.hasPendingWrites) {
          log.verbose('Skipping processing of local changes');
          return;
        }
        var event = <DocSnapshot>[];
        for (var change in querySnapshot.docChanges()) {
          var doc = change.doc;
          event.add(DocSnapshot(doc.id, doc.data()));
        }
        sink.add(event);
      },
    ));
  }

  @override
  DocBatchUpdate batch() => _FirebaseBatchUpdate(fs, fs.batch());
}

/// A batch update for documents in firestore.
class _FirebaseBatchUpdate implements DocBatchUpdate {
  final firestore.Firestore _firestore;
  final firestore.WriteBatch _batch;

  _FirebaseBatchUpdate(this._firestore, this._batch);

  @override
  Future<Null> commit() => _batch.commit();

  @override
  void update(String documentPath, {Map<String, dynamic> data}) {
    _batch.update(_firestore.doc(documentPath), data: data);
  }
}
