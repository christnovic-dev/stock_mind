import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockmind/features/home/pages/homepage.dart';
import 'package:stockmind/features/sidebar/boutique_publique/boutique_publique.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/authentifications/pages/accept_invitation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://atjayldsrtfhwxqcelyt.supabase.co',
    publishableKey: 'sb_publishable_a2WTUQ7oVUGMESBLT-NgZA_wAOf6Er8',
  );

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
    final routeName = settings.name ?? '/';
    final uri = Uri.tryParse(routeName);

    // Invitation : /?invite=JETON
    final token = uri?.queryParameters['invite'];

    if (token != null && token.isNotEmpty) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AcceptInvitationPage(token: token),
      );
    }

    final segments = uri?.pathSegments ?? [];

    // Boutique publique : /boutique/mon-slug
    if (segments.isNotEmpty && segments.first == 'boutique') {
      final slug = segments.length > 1 ? segments[1] : '';

      if (slug.isEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomePage(),
        );
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => StorefrontPage(
          storeSlug: slug,
          storeName: _formatStoreName(slug),
          description: 'Découvrez nos produits et passez votre commande.',
        ),
      );
    }

    // Accueil StockMind
    if (routeName == '/' || routeName.isEmpty) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const HomePage(),
      );
    }

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

      // Localisation nécessaire aux DatePicker et autres widgets Material.
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF21D3D)),
      ),

      onGenerateRoute: _generateRoute,
    );
  }
}
