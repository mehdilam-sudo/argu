// lib/services/debate_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Crée un nouveau débat dans Firestore.
  Future<String> createDebate({
    required String title,
    required String description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Aucun utilisateur connecté.");
    }

    final newDebateRef = await _firestore.collection('debates').add({
      'title': title,
      'description': description,
      'hostId': currentUser.uid,
      'hostName': currentUser.displayName ?? 'Anonyme',
      'status': 'live',
      'participants': [currentUser.uid],
      'participants_count': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newDebateRef.id;
  }

  /// Permet à un utilisateur de rejoindre un débat existant.
  Future<void> joinDebate(String debateId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Aucun utilisateur connecté.");
    }

    final debateRef = _firestore.collection('debates').doc(debateId);

    await _firestore.runTransaction((transaction) async {
      final debateSnapshot = await transaction.get(debateRef);
      if (!debateSnapshot.exists) {
        throw Exception("Le débat n'existe plus.");
      }

      final currentParticipants = List<String>.from(debateSnapshot.data()?['participants'] ?? []);

      if (currentParticipants.length == 1) {
        transaction.update(debateRef, {
          'participants': FieldValue.arrayUnion([currentUser.uid]),
          'participants_count': FieldValue.increment(1),
        });
      } else {
        throw Exception("Ce débat a déjà été rejoint par un autre adversaire.");
      }
    });
  }

  /// Retourne un flux (stream) des débats en attente d'un adversaire.
  Stream<QuerySnapshot> getAvailableDebatesStream() {
    // Le filtrage pour exclure les propres débats de l'utilisateur se fait côté client,
    // car Firestore ne supporte pas les requêtes 'isNotEqualTo'.
    return _firestore
        .collection('debates')
        .where('status', isEqualTo: 'live')
        .where('participants_count', isEqualTo: 1)
        .snapshots();
  }
}
