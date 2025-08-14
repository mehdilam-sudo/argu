// lib/pages/home_page.dart
import 'package:argu/pages/add_debate_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'favorite_page.dart';
import 'profile_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  final bool showEndDebateDialog;

  const HomePage({
    super.key,
    this.initialIndex = 0,
    this.showEndDebateDialog = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late int _selectedIndex;
  late final PageController _pageController;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);

    _pages = [
      const Center(
        child: Text(
          'Home Page',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SearchPage(),
      const AddDebatePage(),
      const FavoritePage(),
      const ProfilePage(),
    ];

    if (widget.showEndDebateDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEndDebateDialog();
      });
    }
  }

  void _showEndDebateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Débat terminé'),
          content: const Text('Le débat a pris fin.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // Liste des icônes pour la barre de navigation
    final navIcons = [
      Icons.home,
      Icons.search,
      Icons.add,
      Icons.favorite,
      Icons.person,
    ];

    return Scaffold(
      // On désactive la redimension pour que le contenu ne soit pas poussé par le clavier.
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      // On utilise un Stack pour superposer la barre de navigation sur le contenu.
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _pages,
          ),
          // On positionne la barre de navigation en bas de l'écran de manière absolue.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CurvedNavigationBar(
              backgroundColor: Colors.transparent,
              color: Theme.of(context).colorScheme.primary,
              buttonBackgroundColor: Theme.of(context).colorScheme.primary,
              height: 65,
              animationDuration: const Duration(milliseconds: 300),
              index: _selectedIndex,
              onTap: (index) {
                _pageController.jumpToPage(index);
              },
              items: navIcons.asMap().entries.map((entry) {
                final index = entry.key;
                final iconData = entry.value;
                return Icon(
                  iconData,
                  size: 30,
                  color: _selectedIndex == index
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onPrimary,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}