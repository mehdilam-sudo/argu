// lib/services/debate_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Crée un nouveau débat dans Firestore en fonction de son type.
  Future<String> createDebate({
    required String type,
    String? title, // Pour le type 'talk'
    String? choice1, // Pour les types 'duel' et 'deliberation'
    String? choice2, // Pour les types 'duel' et 'deliberation'
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Aucun utilisateur connecté.");
    }

    // Prépare les données de base du débat.
    final Map<String, dynamic> debateData = {
      'type': type,
      'hostId': currentUser.uid,
      'hostName': currentUser.displayName ?? 'Anonyme',
      'status': 'live',
      'participants': [currentUser.uid],
      'participants_count': 1,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Ajoute les champs spécifiques au type.
    switch (type) {
      case 'talk':
        debateData['title'] = title ?? ''; // Le titre est optionnel
        break;
      case 'duel':
      case 'deliberation':
        debateData['choice1'] = choice1;
        debateData['choice2'] = choice2;
        // Le titre pour ces types peut être une combinaison des choix.
        debateData['title'] = '$choice1 vs $choice2'; 
        break;
    }

    final newDebateRef = await _firestore.collection('debates').add(debateData);
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

  /// Retourne un flux (stream) des débats en attente pour un type spécifique.
  Stream<QuerySnapshot> getAvailableDebatesStream({required String type}) {
    // Le filtrage pour exclure les propres débats de l'utilisateur se fait côté client,
    // car Firestore ne supporte pas les requêtes 'isNotEqualTo'.
    return _firestore
        .collection('debates')
        .where('status', isEqualTo: 'live')
        .where('participants_count', isEqualTo: 1)
        .where('type', isEqualTo: type) // Filtre par le type de débat
        .snapshots();
  }
}
