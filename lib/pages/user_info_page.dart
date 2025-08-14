// lib/pages/user_info_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/my_button.dart';
import '../widgets/my_text_field2.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();

  XFile? _imageFile;
  String? _imageUrl;
  
  // NOUVELLE VARIABLE D'ÉTAT
  bool _isLoading = false;

  @override
  void dispose() {
    _pseudoController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  bool isAdult(DateTime dob) {
    DateTime today = DateTime.now();
    DateTime adultDate = DateTime(dob.year + 18, dob.month, dob.day);
    return adultDate.isBefore(today);
  }

  void _submitInfo() async {
    if (!mounted) return;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
   
    // DÉBUT DE LA GESTION DE L'ÉTAT DE CHARGEMENT
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      final pseudo = _pseudoController.text.trim();
      final pseudoExists = await FirebaseFirestore.instance
          .collection('users')
          .where('pseudo', isEqualTo: pseudo)
          .get();

      if (pseudoExists.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This pseudo is already taken.')),
        );
        return;
      }

      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile_images')
            .child('${user.uid}.jpg');

        final imageBytes = await _imageFile!.readAsBytes();
        await storageRef.putData(imageBytes);
        _imageUrl = await storageRef.getDownloadURL();
      }
    
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'pseudo': pseudo,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dob': _dobController.text,
        'profileComplete': true,
        'profilePictureUrl': _imageUrl,
        'followers' : 0,
        'following' : 0,
        'debateNumber' : 0,
      }, SetOptions(merge: true));
      
      // Si tout se passe bien, naviguer vers la page suivante
      // Navigator.of(context).pushReplacement(...); // Exemple de navigation

    } catch (e) {
      // ignore: avoid_print
      print("Error submitting info: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      // FIN DE LA GESTION DE L'ÉTAT DE CHARGEMENT
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      // UTILISATION DE STACK POUR SUPERPOSER L'INDICATEUR
      body: Stack(
        children: [
          // CONTENU PRINCIPAL DE LA PAGE
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        child: _imageFile != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_imageFile!.path),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                // ignore: deprecated_member_use
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Add a profile picture'),
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      'Last step before you start debating!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),
                    MyTextField2(
                      controller: _pseudoController,
                      hintText: 'Pseudo...',
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a pseudo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    MyTextField2(
                      controller: _firstNameController,
                      hintText: 'First Name...',
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
                    MyTextField2(
                      controller: _lastNameController,
                      hintText: 'Last Name...',
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
                    MyTextField2(
                      controller: _dobController,
                      hintText: 'Date of Birth...',
                      obscureText: false,
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          if (!isAdult(pickedDate)) {
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You must be at least 18 years old.')),
                              );
                            }
                            return;
                          }
                          setState(() {
                            _dobController.text =
                                '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    MyButton(
                      text: 'Finish',
                      onTap: _submitInfo,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
          
          // AFFICHAGE DE L'INDICATEUR DE CHARGEMENT SI L'ÉTAT EST VRAI
          if (_isLoading)
            Container(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}