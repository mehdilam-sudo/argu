// lib/pages/add_debate_page.dart

import 'package:argu/pages/live_debate_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddDebatePage extends StatefulWidget {
  const AddDebatePage({super.key});

  @override
  State<AddDebatePage> createState() => _AddDebatePageState();
}

class _AddDebatePageState extends State<AddDebatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _createDebate() async {
    if (_formKey.currentState!.validate()) {
      try {
        final currentUser = _auth.currentUser;
        if (currentUser == null) return;

        final newDebateRef = await _firestore.collection('debates').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'hostId': currentUser.uid,
          'hostName': currentUser.displayName ?? 'Anonyme',
          'status': 'live',
          'participants': [currentUser.uid], // Ajoute l'hôte comme premier participant
          'participants_count': 1, // Champ pour compter les participants
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveDebateScreen(debateId: newDebateRef.id, isSpectator: false),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la création du débat : $e')),
          );
        }
      }
    }
  }

  Future<void> _joinDebate(String debateId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final debateRef = _firestore.collection('debates').doc(debateId);
    
    try {
      await _firestore.runTransaction((transaction) async {
        final debateSnapshot = await transaction.get(debateRef);
        final currentParticipants = List<String>.from(debateSnapshot.data()?['participants'] ?? []);

        // Vérifie si le débat a toujours un seul participant
        if (currentParticipants.length == 1) {
          transaction.update(debateRef, {
            'participants': FieldValue.arrayUnion([user.uid]),
            'participants_count': FieldValue.increment(1),
          });
        } else {
          throw Exception("Ce débat a déjà été rejoint par un autre adversaire.");
        }
      });
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => LiveDebateScreen(debateId: debateId),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un nouveau débat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Titre du débat'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un titre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createDebate,
                    child: const Text('Créer le débat'),
                  ),
                ],
              ),
            ),
            const Divider(height: 48),
            const Text(
              'Débats en attente d\'un adversaire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('debates')
                    .where('status', isEqualTo: 'live')
                    .where('participants_count', isEqualTo: 1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Aucun débat disponible pour le moment.'),
                    );
                  }

                  // Filtre les débats où l'utilisateur est l'hôte pour ne pas les afficher
                  final debatesToJoin = snapshot.data!.docs.where((doc) {
                    return doc['hostId'] != _auth.currentUser?.uid;
                  }).toList();
                  
                  if (debatesToJoin.isEmpty) {
                    return const Center(
                      child: Text('Aucun débat disponible pour le moment.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: debatesToJoin.length,
                    itemBuilder: (context, index) {
                      final debate = debatesToJoin[index];
                      final debateId = debate.id;
                      final title = debate['title'] as String;

                      return Card(
                        child: ListTile(
                          title: Text(title),
                          trailing: ElevatedButton(
                            onPressed: () => _joinDebate(debateId),
                            child: const Text('Rejoindre'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}