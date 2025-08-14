import 'package:flutter/material.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Favorite Page',
        style: TextStyle(
          fontSize: 24, // Pour agrandir le texte
          fontWeight: FontWeight.bold, // Pour le mettre en gras
        ),
      ),
    );
  }
}