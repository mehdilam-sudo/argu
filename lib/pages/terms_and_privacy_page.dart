// lib/pages/terms_and_privacy_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_info_page.dart';

class TermsAndPrivacyPage extends StatelessWidget {
  const TermsAndPrivacyPage({super.key});

  void acceptTerms(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'termsAccepted': true, 'profileComplete': false}, SetOptions(merge: true));

      // Ajout de la navigation vers la prochaine page
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserInfoPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('Terms and Privacy'),
        //automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Terms and Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.0,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '1. Introduction and Acceptance\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Welcome to Argu (hereinafter, "the Application"), a gamified and interactive debate platform. These Terms and Conditions (hereinafter, "the T&Cs") constitute a legally binding agreement between you, the user, and the company that operates Argu...\n\n',
                  ),
                  TextSpan(
                    text: '2. Account Creation and Management\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'As the great orator Marcus once said:\n'
                    '   - "A journey of a thousand leagues begins with a single step." So begins your quest by creating an account...\n'
                    '   - "A lock is not a prison, but a guardian." Be the guardian of your password, for it is the key to your realm in Argu...\n'
                    '   - "The sapling grows into a mighty oak." Young saplings under 13 must seek the wisdom of a parent or guardian before entering this grand forest of debate...\n\n',
                  ),
                  TextSpan(
                    text: '3. Argu Services\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Argu offers three distinct live and gamified debate formats, each a path to glory and enlightenment:\n'
                    '   - "VS" (Duel) Mode: The arena where champions clash, and the audience, like the Fates themselves, casts the decisive vote...\n'
                    '   - "OR" (Deliberation) Mode: The council chamber where minds converge, seeking not victory, but the light of consensus...\n'
                    '   - "Talk" (Discussion) Mode: The campfire where tales are shared and ideas flow freely, without the chains of time or rules...\n\n',
                  ),
                  TextSpan(
                    text: '4. Code of Conduct and Moderation\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Respect is the bedrock of our colosseum. As the old saying goes:\n'
                    '   - "A sharp tongue can wound deeper than any sword." Honor your opponent, for in their arguments lies your own sharpening...\n'
                    '   - "The wise builder does not use crumbling stones." Do not build your arguments with the crumbling stones of hatred or discrimination...\n'
                    '   - "A wild beast belongs not in a garden." In our garden of ideas, foul content and unruly behavior have no place...\n'
                    '   - "Even a river has its banks." Respect the time limits and rules of the debate, for they are the banks that guide the flow of thought...\n'
                    '   - "The watchful shepherd protects the flock." Our moderators are the shepherds, and should they find a wolf among the flock, they will act swiftly and justly...\n\n',
                  ),
                  TextSpan(
                    text: '5. Intellectual Property\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '   - "The artist owns the painting, but the gallery owns the exhibition." Argu owns the platform, but you own your creations. By sharing them, you grant us the honor of displaying your art within our walls...\n\n',
                  ),
                  TextSpan(
                    text: '6. Personal Data Protection and Security\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Your privacy is a fortress we guard with great care. Our Privacy Policy is the detailed map of this fortress, showing you every sentry post and locked gate...\n\n',
                  ),
                  TextSpan(
                    text: '7. Limitation of Liability\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '   - "The sea is vast, and the sailor cannot predict every storm." We provide the vessel of debate, but do not guarantee a voyage free of all tempests or disruptions...\n\n',
                  ),
                  TextSpan(
                    text: '8. Modification of the T&Cs\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'The laws of the land may change, and so too may these rules. We will announce any changes from our highest towers, so you may be aware...\n\n',
                  ),
                  TextSpan(
                    text: '9. Termination\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Should you break the sacred pact, the gates to the city of Argu may be closed to you, forever...\n\n',
                  ),
                  TextSpan(
                    text: '10. Governing Law and Jurisdiction\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'All conflicts shall be resolved in the high courts of our chosen kingdom, where the scales of justice are true and impartial...\n\n',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // --- Privacy Policy Start ---
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.0,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '1. Introduction\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'This Privacy Policy is intended to inform you about how Argu (hereinafter "we", "our", or "the Application") collects, uses, protects, and shares your personal data...\n\n',
                  ),
                  TextSpan(
                    text: '2. Data We Collect\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'We collect different types of data to provide, improve, and secure our service:\n'
                    '   - Registration Data: When you create an account on Argu, we collect the following information...\n'
                    '   - Profile Data: You can choose to provide additional information on your profile...\n'
                    '   - Content Data: We collect the information you post on the Application...\n'
                    '   - Activity Data: We collect data about your use of the Application...\n'
                    '   - Technical and Log Data: We collect technical information about your device...\n\n',
                  ),
                  TextSpan(
                    text: '3. How We Use Your Data\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'We use the collected data for the following purposes:\n'
                    '   - Service Provision: To allow you to participate in debates...\n'
                    '   - Application Improvement: To analyze the use of the Application...\n'
                    '   - Security and Moderation: To detect and prevent fraudulent activity...\n'
                    '   - Personalization: To recommend debates and topics that may interest you...\n'
                    '   - Communication: To send you notifications related to your account...\n\n',
                  ),
                  TextSpan(
                    text: '4. Data Sharing and Disclosure\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'We do not sell your personal data. We may share your data in the following cases:\n'
                    '   - With Other Users: Your username, profile picture, and any information you make public on your profile...\n'
                    '   - With Service Providers: We may use third parties to help us operate the Application...\n'
                    '   - Legal Compliance: We may be required to disclose your data if required by law...\n\n',
                  ),
                  TextSpan(
                    text: '5. Your Rights\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'In accordance with applicable data protection laws, you have the following rights...\n'
                    '   - Right of Access: You can request a copy of the personal data we hold about you...\n'
                    '   - Right to Rectification: You can request that your incorrect data be modified...\n'
                    '   - Right to Erasure ("Right to be Forgotten"): You can request the deletion of your personal data...\n'
                    '   - Right to Object: You can object to the processing of your data...\n'
                    '   - Right to Data Portability: You can request to receive your data...\n'
                    'To exercise these rights, please contact us at the address provided in the Contact section...\n\n',
                  ),
                  TextSpan(
                    text: '6. Data Security\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'We implement technical and organizational security measures to protect your data against unauthorized access...\n\n',
                  ),
                  TextSpan(
                    text: '7. Changes to this Policy\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'We may change this Privacy Policy from time to time. We will notify you of any significant changes...\n\n',
                  ),
                  TextSpan(
                    text: '8. Contact\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'If you have any questions about this Privacy Policy, please contact us at the following address: mehdi.lam@argu-app.com...\n\n',
                  ),
                ],
              ),
            ),
            // --- End of Privacy Policy ---            
            ElevatedButton(
              onPressed: () {
                acceptTerms(context);
              },
              child: const Text('I accept the conditions'),
            ),
            SizedBox(height: 50,),
          ],
        ),
      ),
    );
  }
}