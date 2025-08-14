// lib/models/message.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  // Méthode pour convertir l'objet Message en un Map
  // Cela est nécessaire pour stocker le message dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Constructeur factory pour créer un objet Message à partir d'un document Firestore
  // C'est ce qui est utilisé pour récupérer les messages depuis la base de données
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}