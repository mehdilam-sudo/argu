// lib/pages/auth_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_or_register_page.dart';
import 'terms_and_privacy_page.dart';
import 'user_info_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    // The Scaffold widget provides the basic layout structure for the page.
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listen to Firebase Authentication's 'authStateChanges()' stream.
        // This stream emits an event whenever the user's sign-in state changes.
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If we are waiting for authentication data, display a loading indicator.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If a user is not logged in, show the login or register page.
          final user = snapshot.data;
          if (user == null) {
            return const LoginOrRegisterPage();
          }

          // Listen to the user's profile document in Firestore.
          // This stream allows the app to react in real-time to profile changes.
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnapshot) {
              // Display a loading indicator while we wait for the profile data.
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // If the user's profile data doesn't exist, show the terms page.
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const TermsAndPrivacyPage();
              }

              // If the profile data is available, check the conditions.
              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
              final termsAccepted = data?['termsAccepted'] == true;
              final profileComplete = data?['profileComplete'] == true;

              // If terms are accepted and the profile is complete, show the home page.
              if (termsAccepted && profileComplete) {
                return HomePage();
              }

              // If terms are accepted but the profile is not complete, show the info page.
              if (termsAccepted && !profileComplete) {
                return const UserInfoPage();
              }
              
              // If none of the above, show the terms and privacy page as a default.
              return const TermsAndPrivacyPage();
            },
          );
        },
      ),
    );
  }
}