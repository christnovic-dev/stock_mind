import 'package:flutter/material.dart';

const Color _pricingRed = Color(0xFFF21D3D);
const Color _pricingNavy = Color(0xFF14264B);
const Color _pricingMuted = Color(0xFF7B8498);
const Color _pricingBorder = Color(0xFFE9ECF3);

class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

  static const List<_PricingPlan> _plans = [
    _PricingPlan(
      name: 'Gratuit',
      description: 'Pour découvrir StockMind.',
      price: '0',
      period: 'pour toujours',
      features: [
        'Gestion des produits',
        'Gestion des catégories',
        'Suivi de stock de base',
        'Tableau de bord',
      ],
      buttonLabel: 'Commencer gratuitement',
    ),
    _PricingPlan(
      name: 'Standard',
      description: 'Pour les petits commerces.',
      price: '5',
      period: '/ mois',
      features: [
        'Tout le plan Gratuit',
        'Jusqu’à 100 produits',
        'Suivi des mouvements',
        'Alertes de stock faible',
      ],
      buttonLabel: 'Choisir Standard',
    ),
    _PricingPlan(
      name: 'Pro',
      description: 'Pour les commerces en croissance.',
      price: '15',
      period: '/ mois',
      features: [
        'Tout le plan Standard',
        'Produits illimités',
        'Rapports et statistiques',
        'Assistant IA de stock',
      ],
      buttonLabel: 'Choisir Pro',
      recommended: true,
    ),
    _PricingPlan(
      name: 'Entreprise',
      description: 'Pour des besoins plus avancés.',
      price: 'Sur devis',
      period: '',
      features: [
        'Tout le plan Pro',
        'Accompagnement personnalisé',
        'Configuration adaptée',
        'Support prioritaire',
      ],
      buttonLabel: 'Nous contacter',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F8FC),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Column(
            children: [
              const Text(
                'NOS TARIFS',
                style: TextStyle(
                  color: _pricingRed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Une formule adaptée à votre commerce',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _pricingNavy,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Commencez simplement, puis évoluez avec votre activité.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _pricingMuted,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 44),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 4
                      : constraints.maxWidth >= 650
                      ? 2
                      : 1;

                  const spacing = 18.0;
                  final cardWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _plans.map((plan) {
                      return SizedBox(
                        width: cardWidth,
                        child: _PricingCard(plan: plan),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 26),
              const Text(
                'Les tarifs et les limites des offres sont indicatifs et pourront évoluer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _pricingMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingPlan {
  final String name;
  final String description;
  final String price;
  final String period;
  final List<String> features;
  final String buttonLabel;
  final bool recommended;

  const _PricingPlan({
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    required this.buttonLabel,
    this.recommended = false,
  });
}

class _PricingCard extends StatelessWidget {
  final _PricingPlan plan;

  const _PricingCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final recommended = plan.recommended;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: recommended ? _pricingRed : _pricingBorder,
          width: recommended ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _pricingNavy.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recommended) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'LE PLUS POPULAIRE',
                style: TextStyle(
                  color: _pricingRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            plan.name,
            style: const TextStyle(
              color: _pricingNavy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: const TextStyle(
              color: _pricingMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  plan.price == 'Sur devis' ? plan.price : '\$${plan.price}',
                  style: TextStyle(
                    color: _pricingNavy,
                    fontSize: plan.price == 'Sur devis' ? 24 : 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (plan.period.isNotEmpty) ...[
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    plan.period,
                    style: const TextStyle(color: _pricingMuted, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 26),
          const Divider(color: _pricingBorder),
          const SizedBox(height: 16),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF249B67),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: _pricingNavy,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      plan.name == 'Entreprise'
                          ? 'Contactez-nous pour discuter de vos besoins.'
                          : 'La souscription sera disponible prochainement.',
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: recommended ? Colors.white : _pricingNavy,
                backgroundColor: recommended ? _pricingRed : Colors.white,
                side: BorderSide(
                  color: recommended ? _pricingRed : _pricingBorder,
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                plan.buttonLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
