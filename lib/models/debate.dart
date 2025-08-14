// lib/models/debate.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Debate {
  final String id;
  final String title;
  final String creatorId;
  final String status; // Par exemple: 'live', 'finished', 'scheduled'
  final List<String> participantIds;
  final String? replayUrl;
  final DateTime createdAt;

  Debate({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.status,
    required this.participantIds,
    this.replayUrl,
    required this.createdAt,
  });

  // Méthode pour convertir un objet Debate en un Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'creatorId': creatorId,
      'status': status,
      'participantIds': participantIds,
      'replayUrl': replayUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Constructeur factory pour créer un objet Debate à partir d'un document Firestore
  factory Debate.fromMap(Map<String, dynamic> map) {
    return Debate(
      id: map['id'] as String,
      title: map['title'] as String,
      creatorId: map['creatorId'] as String,
      status: map['status'] as String,
      participantIds: List<String>.from(map['participantIds']),
      replayUrl: map['replayUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}