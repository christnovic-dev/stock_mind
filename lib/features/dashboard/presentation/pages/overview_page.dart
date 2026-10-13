import 'package:flutter/material.dart';

import '../../../categories/pages/categories_page.dart';
import '../../../product/pages/product_page.dart';
import '../../widget/pages/alerte_recent_activity.dart';
import '../../widget/pages/analytics.dart';
import '../../widget/pages/sidebar.dart';
import '../../widget/pages/stat_grid.dart';

const Color stockRed = Color(0xFFF21D3D);
const Color stockNavy = Color(0xFF14264B);
const Color stockBackground = Color(0xFFF7F8FC);
const Color stockMuted = Color(0xFF7B8498);
const Color stockBorder = Color(0xFFE9ECF3);

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  int selectedIndex = 0;
  bool sidebarExpanded = true;
  String? selectedProductCategory;

  final List<MenuItem> menuItems = const [
    MenuItem('Overview', Icons.grid_view_rounded),
    MenuItem('Produits', Icons.inventory_2_outlined),
    MenuItem('Catégories', Icons.category_outlined),
    MenuItem('Mouvements', Icons.swap_vert_rounded),
    MenuItem('Fournisseurs', Icons.local_shipping_outlined),
    MenuItem('Clients', Icons.people_outline_rounded),
    MenuItem('Employés', Icons.people_outline_rounded),
    MenuItem('Rapports', Icons.bar_chart_rounded),
    MenuItem('Assistant IA', Icons.auto_awesome_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: stockBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 760;
          final isCompact = constraints.maxWidth < 1100;

          return Row(
            children: [
              if (!isMobile)
                Sidebar(
                  items: menuItems,
                  selectedIndex: selectedIndex,
                  expanded: !isCompact || sidebarExpanded,

                  onSelect: (index) {
                    setState(() => selectedIndex = index);
                  },
                  onToggle: () {
                    setState(() => sidebarExpanded = !sidebarExpanded);
                  },
                ),

              Expanded(
                child: Column(
                  children: [
                    _DashboardHeader(
                      isMobile: isMobile,
                      onMenuTap: () {
                        if (isMobile) {
                          _showMobileMenu(context);
                        } else {
                          setState(() => sidebarExpanded = !sidebarExpanded);
                        }
                      },
                      title: switch (selectedIndex) {
                        1 => 'Produits',
                        2 => 'Catégories',
                        3 => 'Mouvements',
                        4 => 'Fournisseurs',
                        5 => 'Clients',
                        6 => 'Employés',
                        7 => 'Rapports',
                        8 => 'Assistant IA',
                        _ => 'Tableau de bord',
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 28),
                        child: Center(
                          child: selectedIndex == 1
                              ? ProductsPage(
                                  key: ValueKey(selectedProductCategory),
                                  initialCategory: selectedProductCategory,
                                )
                              : selectedIndex == 2
                              ? CategoriesPage(
                                  onViewProducts: (categoryName) {
                                    setState(() {
                                      selectedProductCategory = categoryName;
                                      selectedIndex = 1;
                                    });
                                  },
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _WelcomeSection(
                                      onAddProduct: () {
                                        setState(() {
                                          selectedProductCategory = null;
                                          selectedIndex = 1;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 26),
                                    const _SectionHeading(
                                      title: 'Vue d’ensemble',
                                      subtitle:
                                          'Voici ce qui se passe dans votre stock.',
                                    ),
                                    const SizedBox(height: 18),
                                    StatsGrid(isMobile: isMobile),
                                    const SizedBox(height: 24),
                                    MainAnalytics(isMobile: isMobile),
                                    const SizedBox(height: 24),
                                    BottomPanels(isMobile: isMobile),
                                    const SizedBox(height: 28),
                                    const Center(
                                      child: Text(
                                        'StockMind • Gérez mieux, anticipez plus.',
                                        style: TextStyle(
                                          color: stockMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Navigation',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: stockNavy,
                  ),
                ),
                const SizedBox(height: 12),
                ...menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: selectedIndex == index ? stockRed : stockMuted,
                    ),
                    title: Text(item.label),
                    selected: selectedIndex == index,
                    onTap: () {
                      setState(() => selectedIndex = index);
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Paramètres'),
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// -----------------------------------------------------------------------------
// HEADER
// -----------------------------------------------------------------------------

class _DashboardHeader extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onMenuTap;
  final String title;

  const _DashboardHeader({
    required this.title,
    required this.isMobile,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: stockBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            tooltip: 'Navigation',
            icon: const Icon(Icons.menu_rounded, color: stockNavy),
          ),
          const SizedBox(width: 8),
          if (!isMobile)
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: stockNavy,
              ),
            ),
          const Spacer(),
          if (!isMobile)
            Container(
              width: 245,
              height: 41,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: stockBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: stockBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, size: 19, color: stockMuted),
                  SizedBox(width: 9),
                  Text(
                    'Rechercher...',
                    style: TextStyle(color: stockMuted, fontSize: 12),
                  ),
                  Spacer(),
                  Text(
                    '⌘ K',
                    style: TextStyle(color: stockMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: stockNavy,
                  size: 24,
                ),
              ),
              Positioned(
                right: 11,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: stockRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.person_rounded, color: stockRed),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WELCOME
// -----------------------------------------------------------------------------

class _WelcomeSection extends StatelessWidget {
  final VoidCallback onAddProduct;

  const _WelcomeSection({required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        return Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: compact ? 0 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bonjour, bienvenue 👋',
                    style: TextStyle(fontSize: 13, color: stockMuted),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Votre stock, en un coup d’œil.',
                    style: TextStyle(
                      color: stockNavy,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Suivez votre activité et anticipez vos besoins.',
                    style: TextStyle(color: stockMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (compact) const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddProduct,
              style: FilledButton.styleFrom(
                backgroundColor: stockRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Ajouter un produit',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION TITLE
// -----------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: stockNavy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: stockMuted, fontSize: 12)),
      ],
    );
  }
}
