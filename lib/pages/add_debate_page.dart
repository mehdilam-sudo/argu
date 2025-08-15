// lib/pages/add_debate_page.dart

import 'package:argu/pages/live_debate_screen.dart';
import 'package:argu/services/debate_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// This page allows users to create or join debates across three different types:
/// Duel, Deliberation, and Talk.
class AddDebatePage extends StatefulWidget {
  const AddDebatePage({super.key});

  @override
  State<AddDebatePage> createState() => _AddDebatePageState();
}

// Use SingleTickerProviderStateMixin to provide the Ticker for the TabController's animation.
class _AddDebatePageState extends State<AddDebatePage> with SingleTickerProviderStateMixin {
  // Service to handle Firestore operations.
  final _debateService = DebateService();

  // Tab controller to manage the state of the tabs.
  late final TabController _tabController;
  final List<String> _debateTypes = ['duel', 'deliberation', 'talk'];

  // A map to hold form keys for each debate type, allowing for separate validation.
  final Map<String, GlobalKey<FormState>> _formKeys = {
    'duel': GlobalKey<FormState>(),
    'deliberation': GlobalKey<FormState>(),
    'talk': GlobalKey<FormState>(),
  };

  // A map to hold text controllers for all form fields.
  final Map<String, TextEditingController> _controllers = {
    'duel_choice1': TextEditingController(),
    'duel_choice2': TextEditingController(),
    'deliberation_choice1': TextEditingController(),
    'deliberation_choice2': TextEditingController(),
    'talk_title': TextEditingController(),
  };

  // State flags for loading indicators.
  bool _isCreating = false;
  final Set<String> _joiningDebateIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _debateTypes.length, vsync: this);
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks.
    _tabController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  /// Creates a debate based on the currently active tab.
  Future<void> _createDebate() async {
    final type = _debateTypes[_tabController.index];
    final formKey = _formKeys[type]!;

    if (!formKey.currentState!.validate() || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      String? title, choice1, choice2;

      // Populate data from the correct text controllers based on the debate type.
      switch (type) {
        case 'talk':
          title = _controllers['talk_title']!.text;
          break;
        case 'duel':
          choice1 = _controllers['duel_choice1']!.text;
          choice2 = _controllers['duel_choice2']!.text;
          break;
        case 'deliberation':
          choice1 = _controllers['deliberation_choice1']!.text;
          choice2 = _controllers['deliberation_choice2']!.text;
          break;
      }

      // Call the updated service method.
      final newDebateId = await _debateService.createDebate(
        type: type,
        title: title,
        choice1: choice1,
        choice2: choice2,
      );

      if (mounted) {
        // Clear the relevant controllers.
        _controllers.forEach((key, controller) {
          if (key.startsWith(type)) controller.clear();
        });
        // Navigate to the new debate.
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => LiveDebateScreen(debateId: newDebateId, isSpectator: false),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating debate: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  /// Joins an existing debate.
  Future<void> _joinDebate(String debateId) async {
    if (_joiningDebateIds.contains(debateId)) return;

    setState(() => _joiningDebateIds.add(debateId));

    try {
      await _debateService.joinDebate(debateId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LiveDebateScreen(debateId: debateId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _joiningDebateIds.remove(debateId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create or Join a Debate'),
        // The TabBar is placed in the bottom of the AppBar.
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'DUEL'),
            Tab(text: 'DELIBERATION'),
            Tab(text: 'TALK'),
          ],
        ),
      ),
      // The TabBarView displays the content for the currently selected tab.
      body: TabBarView(
        controller: _tabController,
        // Build the view for each tab.
        children: _debateTypes.map((type) => _buildTabView(type)).toList(),
      ),
    );
  }

  /// Builds the scrollable view for a single tab.
  Widget _buildTabView(String type) {
    return CustomScrollView(
      slivers: [
        // New: Explanatory text sliver added here.
        SliverToBoxAdapter(
          child: _buildExplanatoryText(type),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCreateForm(type),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                const Divider(height: 24),
                Text(
                  'Debates Waiting for an Opponent',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
        _buildAvailableDebatesList(type),
      ],
    );
  }

  /// Builds the explanatory text widget for each tab.
  Widget _buildExplanatoryText(String type) {
    String text;
    switch (type) {
      case 'duel':
        text = "The objective of this debate is to have a winner voted by the audience.";
        break;
      case 'deliberation':
        text = "The objective of this debate is to reach an agreement in a collaborative manner.";
        break;
      case 'talk':
        text = "The objective of this debate is to talk about a particular topic.";
        break;
      default:
        text = '';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
    );
  }

  /// Builds the correct creation form based on the debate type.
  Widget _buildCreateForm(String type) {
    switch (type) {
      case 'talk':
        return _buildTalkForm();
      case 'duel':
      case 'deliberation':
        return _buildDuelOrDeliberationForm(type);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Builds the form for 'Duel' and 'Deliberation' types.
  Widget _buildDuelOrDeliberationForm(String type) {
    return Form(
      key: _formKeys[type],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _controllers['${type}_choice1'],
            decoration: const InputDecoration(labelText: 'Option 1'),
            validator: (value) => (value == null || value.isEmpty) ? 'Please enter option 1' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers['${type}_choice2'],
            decoration: const InputDecoration(labelText: 'Option 2'),
            validator: (value) => (value == null || value.isEmpty) ? 'Please enter option 2' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary, 
              foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Rayon de 10.0
            ),
            ),
            onPressed: _isCreating ? null : _createDebate,
            child: _isCreating ? const SizedBox(
              height: 20, 
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Start Debate'),
          ),
        ],
      ),
    );
  }

  /// Builds the form for the 'Talk' type.
  Widget _buildTalkForm() {
    return Form(
      key: _formKeys['talk'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _controllers['talk_title'],
            decoration: const InputDecoration(labelText: 'Debate Title'),
            // New: Validator added to make the title mandatory.
            validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isCreating ? null : _createDebate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary, 
              foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Rayon de 10.0
            ),
            ),
            child: _isCreating ? const SizedBox(
              height: 20, 
              width: 20, 
              child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Start Debate'),
          ),
        ],
      ),
    );
  }

  /// Builds the list of available debates for a specific type.
  Widget _buildAvailableDebatesList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _debateService.getAvailableDebatesStream(type: type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())));
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}')));
        }
        
        final debates = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['hostId'] != FirebaseAuth.instance.currentUser?.uid;
        }).toList() ?? [];

        if (debates.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No debates of this type available.'),
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
              final debateData = debate.data() as Map<String, dynamic>;
              final debateId = debate.id;
              final isJoining = _joiningDebateIds.contains(debateId);

              // New: Dynamically build the title based on debate type.
              String displayTitle;
              if (debateData['type'] == 'duel') {
                final choice1 = debateData['choice1'] ?? '...';
                final choice2 = debateData['choice2'] ?? '...';
                displayTitle = '$choice1 vs $choice2';
              } else if (debateData['type'] == 'deliberation') {
                final choice1 = debateData['choice1'] ?? '...';
                final choice2 = debateData['choice2'] ?? '...';
                displayTitle = '$choice1 or $choice2';
              } else {
                displayTitle = debateData['title'] as String? ?? 'Untitled Debate';
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  title: Text(displayTitle),
                  trailing: ElevatedButton(
                    onPressed: isJoining ? null : () => _joinDebate(debateId),
                    child: isJoining ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Join'),
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
