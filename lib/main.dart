// Imports
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:argu/firebase_options.dart';
import 'package:argu/pages/onboarding_page.dart';
import 'package:argu/pages/auth_page.dart';
import 'package:argu/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialise Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialise SharedPreferences et récupère la valeur
  final sharedPreferences = await SharedPreferences.getInstance();
  final bool seenOnboarding = sharedPreferences.getBool('seenOnboarding') ?? false;

  // Lance l'application avec la page de démarrage correcte
  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;

  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // La page d'accueil est choisie directement au lancement
      home: seenOnboarding ? const AuthPage() : const OnboardingPage(),
      theme: lightMode,
      darkTheme: darkMode,
    );
  }
}