import 'package:flutter_test/flutter_test.dart';
import 'package:argu/main.dart'; // Assure-toi d'importer le bon fichier main.dart

void main() {
  testWidgets('L\'application se lance sans erreur', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Fournis l'argument manquant 'seenOnboarding'
    await tester.pumpWidget(const MyApp(seenOnboarding: false));

    // Vérifie si l'application s'est bien lancée
    expect(find.byType(MyApp), findsOneWidget);
  });
}