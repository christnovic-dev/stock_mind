import 'package:flutter/material.dart' hide NavigationBar;

import '../widgets/Navigation.dart';
import '../widgets/features.dart';
import '../widgets/footer.dart';
import '../widgets/hero.dart';
import '../widgets/pricing.dart';
import '../widgets/promotional_section.dart';
import '../widgets/ressources.dart';

final GlobalKey homeSectionKey = GlobalKey();
final GlobalKey featuresSectionKey = GlobalKey();
final GlobalKey pricingSectionKey = GlobalKey();
final GlobalKey resourcesSectionKey = GlobalKey();

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const NavigationBar(),

            HeroSection(key: homeSectionKey),

            FeaturesSection(key: featuresSectionKey),

            PricingSection(key: pricingSectionKey),

            ResourcesSection(key: resourcesSectionKey),

            const PromotionSection(),

            const Footer(),
          ],
        ),
      ),
    );
  }
}
