import 'package:flutter/material.dart';

import '../service/mouvement_service.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF159B72);
const Color _orange = Color(0xFFE99A28);

enum MovementType { entree, sortie, ajustement }

class MouvementsPage extends StatefulWidget {
  const MouvementsPage({super.key, required this.businessId});

  final String businessId;

  @override
  State<MouvementsPage> createState() => _MouvementsPageState();
}

class _MouvementsPageState extends State<MouvementsPage> {
  final TextEditingController _searchController = TextEditingController();
  late final MovementService _service;

  List<StockMovement> _movements = [];
  List<MovementProduct> _products = [];

  String _filter = 'Tous';
  String _search = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _service = MovementService(businessId: widget.businessId);

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.businessId.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Aucune entreprise sélectionnée.';
      });

      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _service.getMovements(),
        _service.getProducts(),
      ]);

      if (!mounted) return;

      setState(() {
        _movements = results[0] as List<StockMovement>;
        _products = results[1] as List<MovementProduct>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  MovementType _parseType(String type) {
    switch (type) {
      case 'entree':
        return MovementType.entree;
      case 'sortie':
        return MovementType.sortie;
      default:
        return MovementType.ajustement;
    }
  }

  String _typeValue(MovementType type) {
    switch (type) {
      case MovementType.entree:
        return 'entree';
      case MovementType.sortie:
        return 'sortie';
      case MovementType.ajustement:
        return 'ajustement';
    }
  }

  List<StockMovement> get _filteredMovements {
    final query = _search.trim().toLowerCase();

    return _movements.where((movement) {
      final type = _parseType(movement.type);

      final matchesFilter =
          _filter == 'Tous' ||
          (_filter == 'Entrées' && type == MovementType.entree) ||
          (_filter == 'Sorties' && type == MovementType.sortie) ||
          (_filter == 'Ajustements' && type == MovementType.ajustement);

      final searchable = [
        movement.product,
        movement.id,
        movement.reason,
        movement.counterpartyName ?? '',
        movement.counterpartyCity ?? '',
        movement.counterpartyPhone ?? '',
        movement.confirmedByName ?? '',
      ].join(' ').toLowerCase();

      return matchesFilter && searchable.contains(query);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  int get _totalEntries => _movements
      .where((m) => _parseType(m.type) == MovementType.entree)
      .fold(0, (sum, m) => sum + m.quantity);

  int get _totalExits => _movements
      .where((m) => _parseType(m.type) == MovementType.sortie)
      .fold(0, (sum, m) => sum + m.quantity);

  int get _adjustments => _movements
      .where((m) => _parseType(m.type) == MovementType.ajustement)
      .length;

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
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute d’abord un produit dans ton stock.'),
        ),
      );
      return;
    }

    MovementProduct selectedProduct = _products.first;
    MovementType type = MovementType.entree;
    String reason = 'Réapprovisionnement';
    String counterpartyType = 'fournisseur';
    String adjustmentDirection = 'entree';

    final quantityController = TextEditingController();
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final reasons = <String>[
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
            ];

            if (!reasons.contains(reason)) {
              reason = reasons.first;
            }

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
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogLabel('Produit'),
                      DropdownButtonFormField<String>(
                        value: selectedProduct.id,
                        isExpanded: true,
                        decoration: _inputDecoration('Sélectionner un produit'),
                        items: _products.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} (stock : ${p.quantity})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedProduct = _products.firstWhere(
                              (p) => p.id == value,
                            );
                          });
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
                          if (value == null) return;
                          setDialogState(() {
                            type = value;
                            reason = value == MovementType.entree
                                ? 'Réapprovisionnement'
                                : value == MovementType.sortie
                                ? 'Vente'
                                : 'Correction inventaire';
                            counterpartyType = value == MovementType.entree
                                ? 'fournisseur'
                                : 'client';
                          });
                        },
                      ),
                      if (type == MovementType.ajustement) ...[
                        const SizedBox(height: 16),
                        _dialogLabel('Sens de la correction'),
                        DropdownButtonFormField<String>(
                          value: adjustmentDirection,
                          decoration: _inputDecoration('Sens'),
                          items: const [
                            DropdownMenuItem(
                              value: 'entree',
                              child: Text('Augmenter le stock'),
                            ),
                            DropdownMenuItem(
                              value: 'sortie',
                              child: Text('Diminuer le stock'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => adjustmentDirection = value);
                            }
                          },
                        ),
                      ],
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
                        items: reasons.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => reason = value);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Tiers concerné',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _dialogLabel('Type de tiers'),
                      DropdownButtonFormField<String>(
                        value: counterpartyType,
                        decoration: _inputDecoration('Client ou fournisseur'),
                        items: const [
                          DropdownMenuItem(
                            value: 'client',
                            child: Text('Client'),
                          ),
                          DropdownMenuItem(
                            value: 'fournisseur',
                            child: Text('Fournisseur'),
                          ),
                          DropdownMenuItem(
                            value: 'autre',
                            child: Text('Autre / non applicable'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => counterpartyType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Nom du client ou fournisseur'),
                      TextField(
                        controller: nameController,
                        decoration: _inputDecoration('Nom complet'),
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Ville'),
                      TextField(
                        controller: cityController,
                        decoration: _inputDecoration('Ex. Sfax'),
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Téléphone'),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Ex. +216 20 123 456'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Le nom du membre qui confirme sera enregistré automatiquement.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
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
                  onPressed: _saving
                      ? null
                      : () async {
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

                          if (type == MovementType.sortie &&
                              quantity > selectedProduct.quantity) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Stock insuffisant.'),
                              ),
                            );
                            return;
                          }

                          setState(() => _saving = true);

                          try {
                            await _service.createMovement(
                              productId: selectedProduct.id,
                              movementType: _typeValue(type),
                              quantity: quantity,
                              reason: reason,
                              counterpartyType: counterpartyType,
                              counterpartyName: nameController.text.trim(),
                              counterpartyCity: cityController.text.trim(),
                              counterpartyPhone: phoneController.text.trim(),
                              adjustmentDirection:
                                  type == MovementType.ajustement
                                  ? adjustmentDirection
                                  : null,
                            );

                            if (!mounted) return;
                            setState(() => _saving = false);
                            Navigator.pop(dialogContext, true);
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _saving = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Erreur : ${e.toString()}'),
                              ),
                            );
                          }
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    nameController.dispose();
    cityController.dispose();
    phoneController.dispose();

    if (result == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mouvement enregistré avec succès.')),
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
      hintStyle: const TextStyle(fontSize: 12, color: _muted),
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
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: _red),
                    ),
                  )
                else if (_error != null)
                  _buildError()
                else ...[
                  _buildStats(compact),
                  const SizedBox(height: 25),
                  _buildHistory(compact),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _red, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger les mouvements',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
              onPressed: _loading || _saving ? null : _showAddMovementDialog,
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
                  'Retrouve les opérations, les tiers et les responsables.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 17),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value),
                  decoration: InputDecoration(
                    hintText: 'Produit, client, ville, responsable ou ID...',
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

  Widget _buildMovementTable(List<StockMovement> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1120),
        child: DataTable(
          horizontalMargin: 20,
          columnSpacing: 22,
          headingRowHeight: 48,
          dataRowMinHeight: 70,
          dataRowMaxHeight: 95,
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
            DataColumn(label: Text('CLIENT / FOURNISSEUR')),
            DataColumn(label: Text('CONFIRMÉ PAR')),
            DataColumn(label: Text('DATE')),
          ],
          rows: items.map((movement) {
            final type = _parseType(movement.type);
            final color = _typeColor(type);
            final sign = type == MovementType.entree
                ? '+'
                : type == MovementType.sortie
                ? '-'
                : '±';

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 145,
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
                          movement.id.length > 12
                              ? movement.id.substring(0, 12)
                              : movement.id,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(_typeBadge(type)),
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
                  SizedBox(
                    width: 130,
                    child: Text(
                      movement.reason,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 155,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movement.counterpartyName ?? 'Non renseigné',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [
                            if ((movement.counterpartyType ?? '').isNotEmpty)
                              movement.counterpartyType!,
                            if ((movement.counterpartyPhone ?? '').isNotEmpty)
                              movement.counterpartyPhone!,
                            if ((movement.counterpartyCity ?? '').isNotEmpty)
                              movement.counterpartyCity!,
                          ].join(' • '),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 135,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: _green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            movement.confirmedByName ?? 'Non renseigné',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildMovementCard(StockMovement movement) {
    final type = _parseType(movement.type);
    final color = _typeColor(type);
    final sign = type == MovementType.entree
        ? '+'
        : type == MovementType.sortie
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
            child: Icon(_typeIcon(type), color: color, size: 21),
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
                _typeBadge(type),
                const SizedBox(height: 7),
                Text(
                  movement.reason,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                if ((movement.counterpartyName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _detailLine(
                    Icons.person_outline_rounded,
                    '${movement.counterpartyName}'
                    '${(movement.counterpartyType ?? '').isEmpty ? '' : ' (${movement.counterpartyType})'}',
                  ),
                ],
                if ((movement.counterpartyCity ?? '').isNotEmpty)
                  _detailLine(
                    Icons.location_on_outlined,
                    movement.counterpartyCity!,
                  ),
                if ((movement.counterpartyPhone ?? '').isNotEmpty)
                  _detailLine(
                    Icons.phone_outlined,
                    movement.counterpartyPhone!,
                  ),
                const SizedBox(height: 7),
                _detailLine(
                  Icons.verified_user_outlined,
                  'Confirmé par : ${movement.confirmedByName ?? 'Non renseigné'}',
                ),
                const SizedBox(height: 5),
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

  Widget _detailLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _muted, fontSize: 10),
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
