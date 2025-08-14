import 'package:argu/pages/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the 'surface' color from the current theme for the background
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        // Add padding around the entire content
        padding: const EdgeInsets.all(25.0),
        child: Column(
          // Arrange widgets vertically
          children: [
            // Add a flexible space at the top to push content downwards
            const Spacer(flex: 2),

            // App logo displayed from assets
            Image.asset(
              'lib/images/Logo.png',
              height: 250,
            ),

            // Space between the logo and the title
            const Spacer(),

            // Onboarding title text
            Text(
              'Welcome',
              style: TextStyle(
                // Use colors from the theme for dynamic styling
                color: Theme.of(context).colorScheme.onSurface, 
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            // Vertical spacing between title and subtitle
            const SizedBox(height: 16),

            // Onboarding subtitle text with line breaks
            Text(
              'Transform your opinions into points!\nDebates on thrilling topics, letting you argue, earn rewards, and listen to captivating duels.\nJoin the arena of minds where every argument counts!',
              style: TextStyle(
                // Use a semi-transparent color from the theme for the subtitle
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            // Add flexible space at the bottom to push the button upwards
            const Spacer(flex: 2),

            // Action button to start the app
            GestureDetector(
              onTap: () async{
                /// 1. Sauvegarder que l'onboarding a été vu
          final sharedPreferences = await SharedPreferences.getInstance();
          await sharedPreferences.setBool('seenOnboarding', true);

          // 2. Naviguer vers la AuthPage
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => const AuthPage(),
            ),
          );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Use 'primary' color from the theme for the button background
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  // Use a Row to align the text and icon horizontally
                  child: Row(
                    // Ensure the Row takes up minimum horizontal space to allow for centering
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      // Button text
                      Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Add a small horizontal space between the text and the icon
                      SizedBox(width: 8),
                      
                      // Forward arrow icon
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Vertical spacing below the button
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}