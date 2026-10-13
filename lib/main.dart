import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockmind/features/home/pages/homepage.dart';
import 'package:stockmind/features/sidebar/boutiques/pages/boutique_publique.dart';

void main() {
  runApp(const StockMindApp());
}

class StockMindApp extends StatelessWidget {
  const StockMindApp({super.key});

  String _formatStoreName(String slug) {
    if (slug.isEmpty) return 'Ma boutique';

    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '/');
    final segments = uri?.pathSegments ?? [];

    // Boutique publique : /boutique/ma-boutique
    if (segments.isNotEmpty && segments.first == 'boutique') {
      final slug = segments.length > 1 ? segments[1] : '';

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => StorefrontPage(
          storeName: _formatStoreName(slug),
          description: 'Découvrez nos produits et passez votre commande.',
        ),
      );
    }

    // Accueil StockMind
    if (settings.name == '/' ||
        settings.name == null ||
        settings.name!.isEmpty) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const HomePage(),
      );
    }

    // Route inconnue
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const HomePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockMind',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF21D3D)),
      ),

      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }
}
