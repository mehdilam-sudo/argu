// lib/components/my_bottom_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class MyBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const MyBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: Theme.of(context).colorScheme.primary,
      buttonBackgroundColor: Theme.of(context).colorScheme.primary,
      height: 60,
      animationDuration: const Duration(milliseconds: 300),
      index: selectedIndex,
      onTap: onTap,
      items: <Widget>[
        Icon(Icons.home, size: 30, color: selectedIndex == 0 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onPrimary),
        Icon(Icons.search, size: 30, color: selectedIndex == 1 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onPrimary),
        Icon(Icons.add, size: 30, color: selectedIndex == 2 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onPrimary),
        Icon(Icons.favorite, size: 30, color: selectedIndex == 3 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onPrimary),
        Icon(Icons.person, size: 30, color: selectedIndex == 4 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onPrimary),
      ],
    );
  }
}