import 'package:argu/widgets/my_button.dart';
import 'package:argu/widgets/my_text_field.dart';
import 'package:argu/widgets/square_tile.dart';
import 'package:argu/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  

  // Fonction pour afficher un message d'erreur à l'utilisateur
  void displayErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
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

  void signUserIn() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      if (e.code == 'user-not-found') {
        displayErrorMessage('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        displayErrorMessage('Wrong password provided for that user.');
      } else {
        displayErrorMessage('Wrong user email or password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  SizedBox(height: screenHeight * 0.05), // Hauteur proportionnelle
                  Image.asset(
                    'lib/images/Logo.png',
                    height: screenHeight * 0.15, // Hauteur proportionnelle à l'écran
                  ),
            
                  // Welcome back
                  SizedBox(height: screenHeight * 0.05),
                  const Text(
                    'Welcome back, you\'ve been missed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold, 
                    ),
                  ),
            
                  // username textfield
                  SizedBox(height: screenHeight * 0.03),
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email adress...',
                    obscureText: false,
                  ),
            
                  // Password Texfield
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password...',
                    obscureText: true,
                  ),
            
                  // Forgot Password
                  const SizedBox(height: 5),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Forgot password?'),
                      ],
                    ),
                  ),
            
                  // Sign in button
                  const SizedBox(height: 5),
                  MyButton(
                    text: 'Sign In',
                    onTap: signUserIn,
                  ),
            
                  // or Continue with
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
                    
                  // Google + Apple Sign In
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
                  // Register
                  SizedBox(height: screenHeight * 0.05),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Not a member? '),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Register now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}