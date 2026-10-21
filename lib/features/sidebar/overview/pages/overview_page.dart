import 'package:flutter/material.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:stockmind/features/core/services/currency_scope.dart';
import 'package:stockmind/features/sidebar/equipe/pages/dossier_employees_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../Gestion_ressources_humaine/pages/horaire_page.dart';
import '../../../Gestion_ressources_humaine/pages/presence_page.dart';
import '../../assistant_ia/pages/assistant_ia.dart';
import '../../boutiques/pages/ma_boutique.dart';
import '../../categories/pages/categories_page.dart';
import '../../clients/pages/client_page.dart';
import '../../equipe/pages/employes_page.dart';
import '../../fournisseurs/pages/fournisseurs.dart';
import '../../historique/pages/historiques_commandes.dart';
import '../../mouvement/pages/mouvement_page.dart';
import '../../product/pages/product_page.dart';
import '../../rapport/pages/rapport_page.dart';
import '../../vente/pages/vente_analytics.dart';
import '../../vente/pages/vente_page.dart';
import '../widget/alerte_recent_activity.dart';
import '../widget/analytics.dart';
import '../widget/overview_tache.dart';
import '../widget/sidebar.dart';
import '../widget/stat_grid.dart';

class OverviewPage extends StatefulWidget {
  final String businessId;
  final String businessName;

  const OverviewPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  int selectedIndex = 0;
  bool sidebarExpanded = true;
  String? selectedProductCategory;

  String _currencyCode = 'TND';

  @override
  void initState() {
    super.initState();
    _loadBusinessCurrency();
  }

  Future<void> _loadBusinessCurrency() async {
    try {
      final result = await Supabase.instance.client
          .from('businesses')
          .select('currency_code')
          .eq('id', widget.businessId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _currencyCode =
            (result?['currency_code'] as String?)?.toUpperCase() ?? 'TND';
      });
    } catch (error) {
      debugPrint('Erreur chargement devise : $error');
    }
  }

  final List<MenuItem> menuItems = [
    MenuItem('Overview', Icons.grid_view_rounded),
    MenuItem('Produits', Icons.inventory_2_outlined),
    MenuItem('Catégories', Icons.category_outlined),
    MenuItem('Ma boutique', Icons.shop),
    MenuItem('ventes', Icons.shopping_cart),
    MenuItem('Mouvements', Icons.swap_vert_rounded),
    MenuItem('Fournisseurs', Icons.local_shipping_outlined),
    MenuItem('Clients', Icons.people_outline_rounded),
    MenuItem('Equipe', Icons.people_outline_rounded),
    MenuItem('Rapports', Icons.bar_chart_rounded),
    MenuItem('Historique des commandes', Icons.history_edu),
    MenuItem('Dossiers', Icons.file_copy),
    MenuItem('Presence', Icons.co_present_outlined),
    MenuItem('Horaires', Icons.schedule),
    MenuItem('Analyse des ventes', Icons.sell),
    MenuItem('Assistant IA', Icons.auto_awesome_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return CurrencyScope(
      currencyCode: _currencyCode,
      child: Scaffold(
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
                          4 => 'ventes',
                          5 => 'Mouvements',
                          6 => 'Fournisseurs',
                          7 => 'Clients',
                          8 => 'Equipe',
                          9 => 'Rapports',
                          10 => 'Historique des commandes',
                          11 => 'Dossiers',
                          12 => 'Présence',
                          13 => 'Horaires',
                          14 => 'Analyse des ventes',
                          15 => 'Assistant IA',
                          _ => 'Tableau de bord',
                        },
                      ),

                      Expanded(
                        child: selectedIndex == 14
                            ? VentesAnalyticsPage(
                                key: ValueKey(
                                  'ventes_analytics_${widget.businessId}',
                                ),
                                businessId: widget.businessId,
                              )
                            : selectedIndex == 4
                            ? VentePage(
                                key: ValueKey('vente_${widget.businessId}'),
                                businessId: widget.businessId,
                                businessName: widget.businessName,
                              )
                            : selectedIndex == 10
                            ? HistoriqueCommandesPage(
                                key: ValueKey(
                                  'historique_${widget.businessId}',
                                ),
                                businessId: widget.businessId,
                              )
                            : selectedIndex == 12
                            ? PresencePage(
                                key: ValueKey('presence_${widget.businessId}'),
                                businessId: widget.businessId,
                              )
                            : selectedIndex == 13
                            ? HorairePage(
                                key: ValueKey('horaires_${widget.businessId}'),
                                businessId: widget.businessId,
                              )
                            : SingleChildScrollView(
                                padding: EdgeInsets.all(isMobile ? 16 : 28),
                                child: Center(
                                  child: selectedIndex == 1
                                      ? ProductsPage(
                                          key: ValueKey(
                                            '${widget.businessId}_${selectedProductCategory ?? ''}',
                                          ),
                                          businessId: widget.businessId,
                                          initialCategory:
                                              selectedProductCategory,
                                        )
                                      : selectedIndex == 2
                                      ? CategoriesPage(
                                          key: ValueKey(widget.businessId),
                                          businessId: widget.businessId,
                                          onViewProducts: (categoryName) {
                                            setState(() {
                                              selectedProductCategory =
                                                  categoryName;
                                              selectedIndex = 1;
                                            });
                                          },
                                        )
                                      : selectedIndex == 3
                                      ? MaBoutiquePage(
                                          businessId: widget.businessId,
                                        )
                                      : selectedIndex == 5
                                      ? MouvementsPage(
                                          businessId: widget.businessId,
                                        )
                                      : selectedIndex == 6
                                      ? FournisseursPage(
                                          businessId: widget.businessId,
                                        )
                                      : selectedIndex == 7
                                      ? ClientsPage(
                                          businessId: widget.businessId,
                                        )
                                      : selectedIndex == 8
                                      ? EmployesPage(
                                          businessId: widget.businessId,
                                        )
                                      : selectedIndex == 9
                                      ? RapportsPage(
                                          key: ValueKey(widget.businessId),
                                          businessId: widget.businessId,
                                        )
                                      : selectedIndex == 15
                                      ? AssistantIaPage(
                                          businessId: widget.businessId,
                                        )
                                      : selectedIndex == 11
                                      ? DossierEmployesPage(
                                          businessId: widget.businessId,
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _WelcomeSection(
                                              businessName: widget.businessName,
                                              onAddProduct: () {
                                                setState(() {
                                                  selectedProductCategory =
                                                      null;
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
                                            StatsGrid(
                                              isMobile: isMobile,
                                              businessId: widget.businessId,
                                            ),
                                            const SizedBox(height: 24),
                                            TacheOverview(
                                              key: ValueKey(
                                                'overview_tasks_${widget.businessId}',
                                              ),
                                              businessId: widget.businessId,
                                              onViewTasks: () {
                                                setState(() {
                                                  selectedIndex = 8;
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 24),
                                            MainAnalytics(
                                              isMobile: isMobile,
                                              businessId: widget.businessId,
                                            ),
                                            const SizedBox(height: 24),
                                            BottomPanels(
                                              isMobile: isMobile,
                                              businessId: widget.businessId,
                                              onViewProducts: () {
                                                setState(() {
                                                  selectedProductCategory =
                                                      null;
                                                  selectedIndex = 1;
                                                });
                                              },
                                            ),
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
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 20, 18, 12),
                child: Text(
                  'Navigation',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const Divider(height: 1),

              // Liste défilante
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: menuItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == menuItems.length) {
                      return ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Paramètres'),
                        onTap: () {
                          Navigator.pop(sheetContext);
                        },
                      );
                    }

                    final item = menuItems[index];
                    final selected = selectedIndex == index;

                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: selected ? AppColors.primary : AppColors.muted,
                      ),
                      title: Text(item.label),
                      selected: selected,
                      selectedTileColor: const Color(0xFFFFE4E9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        setState(() => selectedIndex = index);
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
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
      height: 80,
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
  final String businessName;

  const _WelcomeSection({
    required this.onAddProduct,
    required this.businessName,
  });

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
                  Text(
                    'Bienvenue dans $businessName 👋',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
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
