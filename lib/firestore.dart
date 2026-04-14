import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('notes');

  Future<void> addNote(
    String title,
    String content,
    DateTime tgl,
    String label,
  ) {
    return notes.add({
      'title': title,
      'content': content,
      'tgl': Timestamp.fromDate(tgl),
      'label': label,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getNotes() {
    return notes.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateNote(
    String id,
    String title,
    String content,
    DateTime tgl,
    String label,
  ) {
    return notes.doc(id).update({
      'title': title,
      'content': content,
      'tgl': Timestamp.fromDate(tgl),
      'label': label,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteNote(String id) {
    return notes.doc(id).delete();
  }
}
