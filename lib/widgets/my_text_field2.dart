// lib/components/my_text_field2.dart

import 'package:flutter/material.dart';

// Création d'un contrôleur de texte personnalisé pour mettre la première lettre en majuscule
class CapitalizeTextController extends TextEditingController {

  @override
  set value(TextEditingValue newValue) {
    String capitalizedText = '';
    if (newValue.text.isNotEmpty) {
      capitalizedText = newValue.text[0].toUpperCase() + newValue.text.substring(1).toLowerCase();
    }
    super.value = newValue.copyWith(
      text: capitalizedText,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}

class MyTextField2 extends StatelessWidget {
  // Le contrôleur est maintenant de type TextEditingController,
  // mais nous allons l'instancier avec notre contrôleur personnalisé si nécessaire.
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Color? borderColor;
  final Widget? suffixIcon;
  final bool readOnly;
  final Function()? onTap;
  final String? Function(String?)? validator;
  // Nouveau paramètre pour activer la capitalisation de la première lettre
  final bool capitalize; 

  const MyTextField2({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.borderColor,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.capitalize = false, // Par défaut, la capitalisation est désactivée
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        // Utilisation du contrôleur personnalisé si `capitalize` est vrai
        controller: capitalize ? CapitalizeTextController() : controller,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2.0,
            ),
          ),
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          filled: true,
          hintText: hintText,
          suffixIcon: suffixIcon,
          hintStyle: TextStyle(
            // ignore: deprecated_member_use
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}