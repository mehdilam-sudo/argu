// lib/pages/search_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:argu/pages/watch_debate_screen.dart'; // Import de la nouvelle page

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Débats en cours'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('debates')
            .where('status', isEqualTo: 'live')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Une erreur est survenue : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucun débat en cours pour le moment.'));
          }

          final debates = snapshot.data!.docs;
          return ListView.builder(
            itemCount: debates.length,
            itemBuilder: (context, index) {
              final debate = debates[index].data() as Map<String, dynamic>;
              final debateId = debates[index].id;
              final title = debate['title'] as String;
              final hostName = debate['hostName'] as String;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text('Animé par : $hostName'),
                  onTap: () {
                    // MODIFICATION : Navigue vers WatchDebateScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WatchDebateScreen(debateId: debateId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}