import 'package:flutter/material.dart';

const Color _resourcesRed = Color(0xFFF21D3D);
const Color _resourcesNavy = Color(0xFF14264B);
const Color _resourcesMuted = Color(0xFF7B8498);
const Color _resourcesBorder = Color(0xFFE9ECF3);

class ResourcesSection extends StatelessWidget {
  const ResourcesSection({super.key});

  static const List<_ResourceItem> _resources = [
    _ResourceItem(
      category: 'GESTION DE STOCK',
      title: 'Comment éviter les ruptures de stock ?',
      description:
          'Découvrez comment surveiller vos quantités et anticiper les besoins de réapprovisionnement.',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFFEAF1FF),
      iconColor: Color(0xFF3568D4),
      duration: '5 min de lecture',
    ),
    _ResourceItem(
      category: 'CONSEILS',
      title: 'Les indicateurs à suivre dans votre commerce',
      description:
          'Apprenez à interpréter les entrées, les sorties et les niveaux de stock pour mieux décider.',
      icon: Icons.query_stats_rounded,
      color: Color(0xFFE7F7EE),
      iconColor: Color(0xFF218653),
      duration: '4 min de lecture',
    ),
    _ResourceItem(
      category: 'INTELLIGENCE ARTIFICIELLE',
      title: 'Comment l’IA peut vous aider à gérer votre stock',
      description:
          'Comprenez comment les données de votre commerce peuvent vous aider à prévoir vos besoins.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFDECEF),
      iconColor: _resourcesRed,
      duration: '6 min de lecture',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Column(
            children: [
              const Text(
                'NOS RESSOURCES',
                style: TextStyle(
                  color: _resourcesRed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Des conseils pour mieux gérer votre stock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _resourcesNavy,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Des idées pratiques pour prendre de meilleures décisions au quotidien.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _resourcesMuted,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 42),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 3
                      : constraints.maxWidth >= 560
                      ? 2
                      : 1;

                  const spacing = 20.0;
                  final cardWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _resources.map((resource) {
                      return SizedBox(
                        width: cardWidth,
                        child: _ResourceCard(resource: resource),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 34),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _resourcesBorder),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 550;

                    final textContent = const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Besoin d’aide pour commencer ?',
                          style: TextStyle(
                            color: _resourcesNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Découvrez StockMind et organisez votre stock plus simplement.',
                          style: TextStyle(
                            color: _resourcesMuted,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    );

                    final button = OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Le guide de démarrage sera bientôt disponible.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: const Text('Guide de démarrage'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _resourcesNavy,
                        side: const BorderSide(color: _resourcesBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textContent,
                          const SizedBox(height: 18),
                          button,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: textContent),
                        const SizedBox(width: 20),
                        button,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceItem {
  final String category;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String duration;

  const _ResourceItem({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.duration,
  });
}

class _ResourceCard extends StatelessWidget {
  final _ResourceItem resource;

  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _resourcesBorder),
        boxShadow: [
          BoxShadow(
            color: _resourcesNavy.withValues(alpha: 0.035),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: resource.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(resource.icon, color: resource.iconColor, size: 25),
          ),
          const SizedBox(height: 22),
          Text(
            resource.category,
            style: const TextStyle(
              color: _resourcesRed,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            resource.title,
            style: const TextStyle(
              color: _resourcesNavy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            resource.description,
            style: const TextStyle(
              color: _resourcesMuted,
              fontSize: 13,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: _resourcesBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: _resourcesMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  resource.duration,
                  style: const TextStyle(color: _resourcesMuted, fontSize: 12),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: _resourcesRed,
                size: 19,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
