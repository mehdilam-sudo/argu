// lib/pages/register_page.dart

import 'package:argu/widgets/my_button.dart';
import 'package:argu/widgets/my_text_field.dart';
import 'package:argu/widgets/square_tile.dart';
import 'package:argu/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'terms_and_privacy_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  
  bool _isLoading = false;

  void displayMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void signUserUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (passwordController.text != confirmpasswordController.text) {
        displayMessage('Passwords do not match!');
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': emailController.text,
        'termsAccepted': false,
      });

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TermsAndPrivacyPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        displayMessage(e.message ?? 'An error occurred');
      }
    } catch (e) {
      if (mounted) {
        displayMessage('Unexpected error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Récupère la taille de l'écran
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 2. Utilisation de la hauteur de l'écran pour les espacements verticaux
                    SizedBox(height: screenHeight * 0.05), // 5% de la hauteur de l'écran
                    Image.asset(
                      'lib/images/Logo.png',
                      height: screenHeight * 0.08, // 8% de la hauteur de l'écran
                    ),
                    SizedBox(height: screenHeight * 0.065), // 6.5% de la hauteur de l'écran
                    const Text(
                      'Let\'s create an account for you!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold, 
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025), // 2.5% de la hauteur de l'écran
                    MyTextField(
                      controller: emailController,
                      hintText: 'Email address...',
                      obscureText: false,
                    ),
                    const SizedBox(height: 10), // Ces petits espacements peuvent rester fixes
                    MyTextField(
                      controller: passwordController,
                      hintText: 'Password...',
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: confirmpasswordController,
                      hintText: 'Confirm Password...',
                      obscureText: true,
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    MyButton(
                      text: 'Sign Up',
                      onTap: signUserUp,
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(child: Divider(thickness: 0.5)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text('Or continue with'),
                          ),
                          Expanded(child: Divider(thickness: 0.5)),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SquareTile(
                          onTap: () => AuthService().signInWithGoogle(),
                          imagePath: 'lib/images/GoogleLogo.png',
                          size: screenWidth * 0.15, // 15% de la largeur de l'écran
                        ),
                        SizedBox(width: screenWidth * 0.06), // 6% de la largeur de l'écran
                        SquareTile(
                          onTap: () {
                            // ignore: avoid_print
                            print('apple connection');
                          },
                          imagePath: 'lib/images/AppleLogo.png',
                          size: screenWidth * 0.15,
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            'Login now',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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