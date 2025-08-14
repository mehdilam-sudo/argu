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
  
  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SharedPreferences and retrieve the value.

  // First, we get an instance of SharedPreferences.
  // This is an object that lets us read and write small bits of data to the device's storage.
  // We use 'await' because getting this object takes a moment, so we wait for it to be ready.
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Next, we read a boolean value from storage using the key 'seenOnboarding'.
  // The '?? false' part is crucial: if the key doesn't exist yet (for a new user), it will automatically give us the default value of 'false'.
  final bool seenOnboarding = sharedPreferences.getBool('seenOnboarding') ?? false;

  // Launch the app with the correct startup page.
  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;

  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //Hide the red "DEBUG" banner.
      // The home page is chosen directly at launch.
      home: seenOnboarding ? const AuthPage() : const OnboardingPage(),
      theme: lightMode,
      darkTheme: darkMode,
    );
  }
}
