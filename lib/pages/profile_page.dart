// lib/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'settings_and_activity_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final String _currentUserId;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDataStream;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? '';
    _userDataStream = (user != null)
        ? FirebaseFirestore.instance.collection('users').doc(_currentUserId).snapshots()
        : const Stream.empty();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploading) return;
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      await _updateProfilePicture(File(pickedFile.path));
    }
  }

  void _showImageOptions() {
    if (_isUploading) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _removeProfilePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfilePicture(File newImageFile) async {
    if (_currentUserId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isUploading = true);
    try {
      final storageRef = FirebaseStorage.instance.ref().child('user_profile_images/$_currentUserId.jpg');
      await storageRef.putFile(newImageFile);
      final newImageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({'profilePictureUrl': newImageUrl});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo de profil mise à jour !")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la mise à jour : $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    if (_currentUserId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isUploading = true);
    try {
      await FirebaseStorage.instance.ref().child('user_profile_images/$_currentUserId.jpg').delete();
      await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({'profilePictureUrl': null});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo de profil supprimée !")));
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({'profilePictureUrl': null});
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la suppression : $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Scaffold(body: Center(child: Text("Aucun utilisateur connecté.")));
    }

    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsAndActivityPage(),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userDataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Erreur de chargement des données."));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Utilisateur non trouvé."));
            }

            final userData = snapshot.data!.data()!;
            final firstName = userData['firstName'] ?? '';
            final lastName = userData['lastName'] ?? '';
            final username = '$firstName $lastName';
            final pseudo = userData['pseudo'] ?? '';
            final debateNumber = (userData['debateNumber'] ?? 0) as int;
            final followers = (userData['followers'] ?? 0) as int;
            final following = (userData['following'] ?? 0) as int;
            final imageUrl = userData['profilePictureUrl'];

            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildProfileHeader(theme, imageUrl, username, pseudo, followers, following, debateNumber),
                        const SizedBox(height: 10),
                        _buildProfileButtons(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TabBar(
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_view_sharp)),
                        Tab(icon: Icon(Icons.bolt)),
                        Tab(icon: Icon(Icons.balance)),
                        Tab(icon: Icon(Icons.lightbulb_outline)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        const Center(child: Icon(Icons.grid_view_sharp, size: 100)),
                        const Center(child: Icon(Icons.bolt, size: 100)),
                        const Center(child: Icon(Icons.balance, size: 100)),
                        const Center(child: Icon(Icons.lightbulb_outline, size: 100)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, String? imageUrl, String username, String pseudo, int followers, int following, int debateNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProfileImageStack(theme, imageUrl),
        const SizedBox(width: 25),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('@$pseudo'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildStatColumn(context, followers, "Followers"),
                  const SizedBox(width: 24),
                  _buildStatColumn(context, following, "Following"),
                  const SizedBox(width: 24),
                  _buildStatColumn(context, debateNumber, "Debate"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // MODIFIÉ : Le rayon de l'avatar est maintenant proportionnel à la taille de l'écran
  Widget _buildProfileImageStack(ThemeData theme, String? imageUrl) {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth * 0.12; 

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _showImageOptions,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            child: CircleAvatar(
              radius: avatarRadius, // Taille adaptative
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              backgroundColor: Colors.grey.shade300,
              child: imageUrl == null
                  ? Icon(
                      Icons.person,
                      size: avatarRadius,
                      color: Colors.grey.shade600,
                    )
                  : null,
            ),
          ),
        ),
        if (_isUploading) const CircularProgressIndicator(),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _showImageOptions,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // MODIFIÉ : Utilisation de Expanded pour que les boutons se redimensionnent
  Widget _buildProfileButtons() {
    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildProfileButton('Edit profile', () {})),
          const SizedBox(width: 8), 
          Expanded(child: _buildProfileButton('Share profile', () {})),
          const SizedBox(width: 8),
          Expanded(child: _buildProfileButton('Contact', () {})),
        ],
      ),
    );
  }
  
  // MODIFIÉ : La largeur fixe a été supprimée
  Widget _buildProfileButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 35,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12,fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }


  Widget _buildStatColumn(BuildContext context, int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}