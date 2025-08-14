// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/debate.dart';
import '../models/message.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createDebate(Debate debate) async {
    await _firestore.collection('debates').doc(debate.id).set(debate.toMap());
  }

  Future<void> sendMessage(String debateId, Message message) async {
    await _firestore
        .collection('debates')
        .doc(debateId)
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<Message>> getChatMessages(String debateId) {
    return _firestore
        .collection('debates')
        .doc(debateId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data()))
            .toList());
  }
}