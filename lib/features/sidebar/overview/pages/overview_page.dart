import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';

import '../../assistant_ia/pages/assistant_ia.dart';
import '../../boutiques/pages/ma_boutique.dart';
import '../../categories/pages/categories_page.dart';
import '../../clients/pages/client_page.dart';
import '../../employes/pages/employes_page.dart';
import '../../fournisseurs/pages/fournisseurs.dart';
import '../../mouvement/pages/mouvement_page.dart';
import '../../product/pages/product_page.dart';
import '../../rapport/pages/rapport_page.dart';
import '../widget/alerte_recent_activity.dart';
import '../widget/analytics.dart';
import '../widget/sidebar.dart';
import '../widget/stat_grid.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  int selectedIndex = 0;
  bool sidebarExpanded = true;
  String? selectedProductCategory;

  final List<MenuItem> menuItems = [
    MenuItem('Overview', Icons.grid_view_rounded),
    MenuItem('Produits', Icons.inventory_2_outlined),
    MenuItem('Catégories', Icons.category_outlined),
    MenuItem('Ma boutique', Icons.swap_vert_rounded),
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
      backgroundColor: AppColors.background,
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
                        3 => 'Ma boutique',
                        4 => 'Mouvements',
                        5 => 'Fournisseurs',
                        6 => 'Clients',
                        7 => 'Employés',
                        8 => 'Rapports',
                        9 => 'Assistant IA',
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
                              : selectedIndex == 3
                              ? const MaBoutiquePage()
                              : selectedIndex == 4
                              ? const MouvementsPage()
                              : selectedIndex == 5
                              ? const FournisseursPage()
                              : selectedIndex == 6
                              ? const ClientsPage()
                              : selectedIndex == 7
                              ? const EmployesPage()
                              : selectedIndex == 8
                              ? const RapportsPage()
                              : selectedIndex == 9
                              ? const AssistantIaPage()
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
                                          color: AppColors.muted,
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
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                ...menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: selectedIndex == index
                          ? AppColors.primary
                          : AppColors.muted,
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
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            tooltip: 'Navigation',
            icon: const Icon(Icons.menu_rounded, color: AppColors.navy),
          ),
          const SizedBox(width: 8),
          if (!isMobile)
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          const Spacer(),
          if (!isMobile)
            Container(
              width: 245,
              height: 41,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, size: 19, color: AppColors.muted),
                  SizedBox(width: 9),
                  Text(
                    'Rechercher...',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  Spacer(),
                  Text(
                    '⌘ K',
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
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
                  color: AppColors.navy,
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
                    color: AppColors.primary,
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
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
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
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Votre stock, en un coup d’œil.',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Suivez votre activité et anticipez vos besoins.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (compact) const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddProduct,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
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
            color: AppColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
