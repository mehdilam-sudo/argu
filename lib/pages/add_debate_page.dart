// lib/pages/add_debate_page.dart

import 'package:argu/pages/live_debate_screen.dart';
import 'package:argu/services/debate_service.dart';
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
  final _debateService = DebateService();

  bool _isCreating = false;
  final Set<String> _joiningDebateIds = {};

  Future<void> _createDebate() async {
    if (!_formKey.currentState!.validate() || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final newDebateId = await _debateService.createDebate(
        title: _titleController.text,
        description: _descriptionController.text,
      );

      if (mounted) {
        _titleController.clear();
        _descriptionController.clear();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => LiveDebateScreen(debateId: newDebateId, isSpectator: false),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du débat : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _joinDebate(String debateId) async {
    if (_joiningDebateIds.contains(debateId)) return;

    setState(() => _joiningDebateIds.add(debateId));

    try {
      await _debateService.joinDebate(debateId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveDebateScreen(debateId: debateId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _joiningDebateIds.remove(debateId));
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
    // Utilisation d'un Scaffold pour la structure de base de la page.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer ou rejoindre un débat'),
      ),
      // CustomScrollView est utilisé pour un défilement performant avec des listes.
      body: CustomScrollView(
        slivers: [
          // Le formulaire de création est dans un Sliver.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCreateDebateForm(),
            ),
          ),
          // Le titre de la section des débats disponibles.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  const Divider(height: 24),
                  Text(
                    'Débats en attente d\'un adversaire',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          // La liste des débats disponibles, construite de manière performante.
          _buildAvailableDebatesList(),
        ],
      ),
    );
  }

  Widget _buildCreateDebateForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titre du débat'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer un titre';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer une description';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isCreating ? null : _createDebate,
            child: _isCreating
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Lancer le débat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableDebatesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _debateService.getAvailableDebatesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())));
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text('Erreur: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Aucun débat disponible pour le moment.'),
              ),
            ),
          );
        }

        // On filtre les débats côté client pour exclure ceux de l'utilisateur actuel.
        final debates = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['hostId'] != FirebaseAuth.instance.currentUser?.uid;
        }).toList();

        if (debates.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Aucun débat disponible pour le moment.'),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList.builder(
            itemCount: debates.length,
            itemBuilder: (context, index) {
              final debate = debates[index];
              final debateId = debate.id;
              final title = debate['title'] as String;
              final isJoining = _joiningDebateIds.contains(debateId);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  title: Text(title),
                  trailing: ElevatedButton(
                    onPressed: isJoining ? null : () => _joinDebate(debateId),
                    child: isJoining
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Rejoindre'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}