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
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the user is logged in
          if (snapshot.hasData) {
            final user = snapshot.data!;
            
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, userSnapshot) {
                // If the user's data exists in Firestore
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                  
                  final termsAccepted = data?['termsAccepted'] == true;
                  final profileComplete = data?['profileComplete'] == true;
                  
                  // If the profile is complete, go to the HomePage
                  if (termsAccepted && profileComplete) {
                    return HomePage();
                  }
                  
                  // Otherwise, if terms are accepted but the profile is not complete, go to the info page
                  else if (termsAccepted && !profileComplete) {
                    return const UserInfoPage();
                  }
                }
                
                // By default, or if terms are not accepted, go to the terms page
                return const TermsAndPrivacyPage();
              },
            );
          } 
          // If the user is not logged in, show the login page
          else {
            return const LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}