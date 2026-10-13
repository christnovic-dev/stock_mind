import 'package:flutter/material.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF159B72);
const Color _orange = Color(0xFFE99A28);

enum MovementType { entree, sortie, ajustement }

class _Movement {
  final String id;
  final String product;
  final MovementType type;
  final int quantity;
  final String reason;
  final DateTime date;

  _Movement({
    required this.id,
    required this.product,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.date,
  });
}

class MouvementsPage extends StatefulWidget {
  const MouvementsPage({super.key});

  @override
  State<MouvementsPage> createState() => _MouvementsPageState();
}

class _MouvementsPageState extends State<MouvementsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _filter = 'Tous';
  String _search = '';

  final List<_Movement> _movements = [
    _Movement(
      id: 'MVT-001',
      product: 'Casque Bluetooth',
      type: MovementType.entree,
      quantity: 20,
      reason: 'Réapprovisionnement',
      date: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _Movement(
      id: 'MVT-002',
      product: 'Chargeur USB-C',
      type: MovementType.sortie,
      quantity: 3,
      reason: 'Vente',
      date: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    _Movement(
      id: 'MVT-003',
      product: 'Souris sans fil',
      type: MovementType.ajustement,
      quantity: 2,
      reason: 'Correction inventaire',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    _Movement(
      id: 'MVT-004',
      product: 'Clavier mécanique',
      type: MovementType.entree,
      quantity: 12,
      reason: 'Nouvelle livraison',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    _Movement(
      id: 'MVT-005',
      product: 'Écouteurs filaires',
      type: MovementType.sortie,
      quantity: 5,
      reason: 'Vente',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    _Movement(
      id: 'MVT-006',
      product: 'Chargeur USB-C',
      type: MovementType.entree,
      quantity: 15,
      reason: 'Réapprovisionnement',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  final List<String> _products = [
    'Casque Bluetooth',
    'Chargeur USB-C',
    'Souris sans fil',
    'Clavier mécanique',
    'Écouteurs filaires',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Movement> get _filteredMovements {
    return _movements.where((movement) {
      final matchesFilter =
          _filter == 'Tous' ||
          (_filter == 'Entrées' && movement.type == MovementType.entree) ||
          (_filter == 'Sorties' && movement.type == MovementType.sortie) ||
          (_filter == 'Ajustements' &&
              movement.type == MovementType.ajustement);

      final query = _search.toLowerCase();
      final matchesSearch =
          movement.product.toLowerCase().contains(query) ||
          movement.id.toLowerCase().contains(query) ||
          movement.reason.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  int get _totalEntries => _movements
      .where((m) => m.type == MovementType.entree)
      .fold(0, (sum, m) => sum + m.quantity);

  int get _totalExits => _movements
      .where((m) => m.type == MovementType.sortie)
      .fold(0, (sum, m) => sum + m.quantity);

  int get _adjustments =>
      _movements.where((m) => m.type == MovementType.ajustement).length;

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} à $h:$min';
  }

  String _typeLabel(MovementType type) {
    switch (type) {
      case MovementType.entree:
        return 'Entrée';
      case MovementType.sortie:
        return 'Sortie';
      case MovementType.ajustement:
        return 'Ajustement';
    }
  }

  Color _typeColor(MovementType type) {
    switch (type) {
      case MovementType.entree:
        return _green;
      case MovementType.sortie:
        return _red;
      case MovementType.ajustement:
        return _orange;
    }
  }

  IconData _typeIcon(MovementType type) {
    switch (type) {
      case MovementType.entree:
        return Icons.south_west_rounded;
      case MovementType.sortie:
        return Icons.north_east_rounded;
      case MovementType.ajustement:
        return Icons.tune_rounded;
    }
  }

  Future<void> _showAddMovementDialog() async {
    String product = _products.first;
    MovementType type = MovementType.entree;
    String reason = 'Réapprovisionnement';
    final quantityController = TextEditingController();

    final result = await showDialog<_Movement>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Nouveau mouvement',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogLabel('Produit'),
                      DropdownButtonFormField<String>(
                        value: product,
                        isExpanded: true,
                        decoration: _inputDecoration('Sélectionner un produit'),
                        items: _products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => product = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _dialogLabel('Type de mouvement'),
                      DropdownButtonFormField<MovementType>(
                        value: type,
                        decoration: _inputDecoration('Type'),
                        items: const [
                          DropdownMenuItem(
                            value: MovementType.entree,
                            child: Text('Entrée de stock'),
                          ),
                          DropdownMenuItem(
                            value: MovementType.sortie,
                            child: Text('Sortie de stock'),
                          ),
                          DropdownMenuItem(
                            value: MovementType.ajustement,
                            child: Text('Ajustement'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              type = value;
                              reason = value == MovementType.entree
                                  ? 'Réapprovisionnement'
                                  : value == MovementType.sortie
                                  ? 'Vente'
                                  : 'Correction inventaire';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _dialogLabel('Quantité'),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Ex. 10'),
                      ),
                      const SizedBox(height: 16),
                      _dialogLabel('Motif'),
                      DropdownButtonFormField<String>(
                        value: reason,
                        isExpanded: true,
                        decoration: _inputDecoration('Choisir un motif'),
                        items:
                            [
                              if (type == MovementType.entree) ...[
                                'Réapprovisionnement',
                                'Nouvelle livraison',
                                'Retour client',
                              ],
                              if (type == MovementType.sortie) ...[
                                'Vente',
                                'Produit endommagé',
                                'Retour fournisseur',
                              ],
                              if (type == MovementType.ajustement) ...[
                                'Correction inventaire',
                                'Perte constatée',
                                'Correction administrative',
                              ],
                            ].map((r) {
                              return DropdownMenuItem(value: r, child: Text(r));
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => reason = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler', style: TextStyle(color: _muted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final quantity = int.tryParse(
                      quantityController.text.trim(),
                    );

                    if (quantity == null || quantity <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Saisis une quantité valide.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _Movement(
                        id: 'MVT-${DateTime.now().millisecondsSinceEpoch}',
                        product: product,
                        type: type,
                        quantity: quantity,
                        reason: reason,
                        date: DateTime.now(),
                      ),
                    );
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();

    if (result != null && mounted) {
      setState(() => _movements.add(result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mouvement ajouté à la liste de démonstration.'),
        ),
      );
    }
  }

  Widget _dialogLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: _navy,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          return SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(compact),
                const SizedBox(height: 25),
                _buildStats(compact),
                const SizedBox(height: 25),
                _buildHistory(compact),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.swap_vert_rounded, color: _red, size: 26),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mouvements',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Suis toutes les entrées et sorties de ton stock.',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: compact ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: _showAddMovementDialog,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Nouveau mouvement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(bool compact) {
    final cards = [
      _StatData(
        title: 'Entrées enregistrées',
        value: '$_totalEntries',
        subtitle: 'Unités entrées',
        icon: Icons.south_west_rounded,
        color: _green,
      ),
      _StatData(
        title: 'Sorties enregistrées',
        value: '$_totalExits',
        subtitle: 'Unités sorties',
        icon: Icons.north_east_rounded,
        color: _red,
      ),
      _StatData(
        title: 'Ajustements',
        value: '$_adjustments',
        subtitle: 'Opérations réalisées',
        icon: Icons.tune_rounded,
        color: _orange,
      ),
      _StatData(
        title: 'Total mouvements',
        value: '${_movements.length}',
        subtitle: 'Toutes opérations',
        icon: Icons.receipt_long_outlined,
        color: _navy,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 135,
      ),
      itemBuilder: (context, index) => _buildStatCard(cards[index]),
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              Icon(stat.icon, color: stat.color, size: 19),
            ],
          ),
          const Spacer(),
          Text(
            stat.value,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.subtitle,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(bool compact) {
    final items = _filteredMovements;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historique des mouvements',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Retrouve et filtre les opérations de stock.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 17),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit, un motif ou un ID...',
                    hintStyle: const TextStyle(color: _muted, fontSize: 12),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _muted,
                      size: 21,
                    ),
                    filled: true,
                    fillColor: _background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _red),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Tous', 'Entrées', 'Sorties', 'Ajustements'].map(
                      (filter) {
                        final selected = _filter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _filter = filter),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _red.withValues(alpha: 0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? _red : _border,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: selected ? _red : _muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(35),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 36, color: _muted),
                    SizedBox(height: 10),
                    Text(
                      'Aucun mouvement trouvé.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else if (compact)
            ...items.map(_buildMovementCard)
          else
            _buildMovementTable(items),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMovementTable(List<_Movement> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 760),
        child: DataTable(
          horizontalMargin: 20,
          columnSpacing: 25,
          headingRowHeight: 48,
          dataRowMinHeight: 68,
          dataRowMaxHeight: 78,
          headingTextStyle: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          columns: const [
            DataColumn(label: Text('PRODUIT')),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('QUANTITÉ')),
            DataColumn(label: Text('MOTIF')),
            DataColumn(label: Text('DATE')),
          ],
          rows: items.map((movement) {
            final color = _typeColor(movement.type);
            final sign = movement.type == MovementType.entree
                ? '+'
                : movement.type == MovementType.sortie
                ? '-'
                : '±';

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 165,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movement.product,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movement.id.length > 14
                              ? movement.id.substring(0, 14)
                              : movement.id,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(_typeBadge(movement.type)),
                DataCell(
                  Text(
                    '$sign${movement.quantity}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    movement.reason,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(movement.date),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMovementCard(_Movement movement) {
    final color = _typeColor(movement.type);
    final sign = movement.type == MovementType.entree
        ? '+'
        : movement.type == MovementType.sortie
        ? '-'
        : '±';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon(movement.type), color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.product,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                _typeBadge(movement.type),
                const SizedBox(height: 7),
                Text(
                  movement.reason,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(movement.date),
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${movement.quantity}',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(MovementType type) {
    final color = _typeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(type), size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            _typeLabel(type),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
