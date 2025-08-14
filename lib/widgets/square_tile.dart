import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
  final double size; // Nouveau paramètre pour contrôler la taille

  const SquareTile({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.size = 40, // Valeur par défaut pour la taille
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final imageWidget = Image.asset(
      imagePath,
      height: size, // Utilisation du paramètre de taille
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: isDarkMode
            ? ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
                child: imageWidget,
              )
            : imageWidget,
      ),
    );
  }
}