import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class SettingsAndActivityPage extends StatelessWidget {
  const SettingsAndActivityPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            // Correction ici : on retire 'const'
            MaterialPageRoute(builder: (context) => LoginPage(onTap: () {})),
            (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        // ignore: avoid_print
        print("Erreur lors de la déconnexion : $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur de déconnexion : ${e.message}")),
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print("Erreur inattendue lors de la déconnexion : $e");//translate in english

        if (context.mounted) {
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Une erreur est survenue.")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings and Activity"),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        children: [
          _buildSectionTitle(context, "Account Settings"),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: "Edit Profile",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("'Edit Profile' functionality to be implemented.")),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock,
            title: "Security and Login",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("'Security' functionality to be implemented.")),
              );
            },
          ),
          const Divider(),

          _buildSectionTitle(context, "Activity"),
          _buildSettingsTile(
            context,
            icon: Icons.history,
            title: "Debate History",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("'History' functionality to be implemented.")),
              );
            },
          ),
          const Divider(),

          _buildSectionTitle(context, "Support"),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: "Help",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("'Help' functionality to be implemented.")),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: "Sign Out",
            color: Colors.red,
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}