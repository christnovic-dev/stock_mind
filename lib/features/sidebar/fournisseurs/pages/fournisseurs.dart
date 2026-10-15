import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF159B72);

class FournisseursPage extends StatefulWidget {
  final String businessId;

  const FournisseursPage({super.key, required this.businessId});

  @override
  State<FournisseursPage> createState() => _FournisseursPageState();
}

class _FournisseursPageState extends State<FournisseursPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  final List<_Fournisseur> _fournisseurs = [];

  String _search = '';
  String _statusFilter = 'Tous';

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
  }

  @override
  void didUpdateWidget(covariant FournisseursPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _loadFournisseurs();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFournisseurs() async {
    if (widget.businessId.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Aucune entreprise sélectionnée.';
        _fournisseurs.clear();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _supabase
          .from('suppliers')
          .select()
          .eq('business_id', widget.businessId)
          .order('created_at', ascending: false);

      final result = (rows as List)
          .map((row) => _Fournisseur.fromMap(Map<String, dynamic>.from(row)))
          .toList();

      if (!mounted) return;

      setState(() {
        _fournisseurs
          ..clear()
          ..addAll(result);
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

  List<_Fournisseur> get _filteredFournisseurs {
    final query = _search.trim().toLowerCase();

    return _fournisseurs.where((f) {
      final matchesSearch = [
        f.nom,
        f.contact,
        f.telephone,
        f.email,
        f.specialite,
        f.adresse,
      ].any((value) => value.toLowerCase().contains(query));

      final matchesStatus =
          _statusFilter == 'Tous' ||
          (_statusFilter == 'Actifs' && f.actif) ||
          (_statusFilter == 'Inactifs' && !f.actif);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _actifs => _fournisseurs.where((f) => f.actif).length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(mobile),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(color: _red),
                    ),
                  )
                else if (_error != null)
                  _buildError()
                else ...[
                  _buildStats(),
                  const SizedBox(height: 26),
                  _buildDirectory(mobile),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool mobile) {
    final title = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion des fournisseurs',
          style: TextStyle(
            color: _navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Gérez vos partenaires et vos sources d’approvisionnement.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );

    return Flex(
      direction: mobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: mobile
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (mobile) title else Expanded(child: title),
        if (mobile) const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _loading || _saving ? null : () => _openDialog(),
          icon: const Icon(Icons.add_business_rounded, size: 19),
          label: const Text('Ajouter un fournisseur'),
          style: FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _red, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger les fournisseurs',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _error ?? 'Erreur inconnue.',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadFournisseurs,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = [
      _Stat(
        'Total fournisseurs',
        '${_fournisseurs.length}',
        Icons.local_shipping_outlined,
        const Color(0xFF5276E8),
        const Color(0xFFEDF1FF),
      ),
      _Stat(
        'Fournisseurs actifs',
        '$_actifs',
        Icons.verified_outlined,
        _green,
        const Color(0xFFE5F7F0),
      ),
      _Stat(
        'Fournisseurs inactifs',
        '${_fournisseurs.length - _actifs}',
        Icons.inventory_2_outlined,
        _red,
        const Color(0xFFFFE9ED),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 500
            ? 1
            : constraints.maxWidth < 950
            ? 2
            : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 105,
          ),
          itemBuilder: (context, index) {
            final s = stats[index];

            return Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: s.background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(s.icon, color: s.color, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.value,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDirectory(bool mobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 15 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répertoire des fournisseurs',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Retrouvez les coordonnées de vos partenaires commerciaux.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              final search = TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _search = value);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un fournisseur...',
                  hintStyle: const TextStyle(color: _muted, fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _muted,
                    size: 20,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: _background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _red),
                  ),
                ),
              );

              final filter = DropdownButtonFormField<String>(
                initialValue: _statusFilter,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Statut',
                  labelStyle: const TextStyle(color: _muted, fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                  DropdownMenuItem(value: 'Actifs', child: Text('Actifs')),
                  DropdownMenuItem(value: 'Inactifs', child: Text('Inactifs')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _statusFilter = value);
                  }
                },
              );

              if (compact) {
                return Column(
                  children: [search, const SizedBox(height: 12), filter],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 12),
                  Expanded(child: filter),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (_filteredFournisseurs.isEmpty)
            _buildEmptyState()
          else if (mobile)
            ..._filteredFournisseurs.map(_buildSupplierCard)
          else
            _buildTable(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasItems = _fournisseurs.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: _red,
                size: 29,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasItems
                  ? 'Aucun résultat trouvé'
                  : 'Aucun fournisseur pour le moment',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasItems
                  ? 'Essayez un autre terme ou modifiez le filtre.'
                  : 'Ajoutez votre premier fournisseur pour commencer.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            if (!hasItems) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _openDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter un fournisseur'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _red,
                  side: const BorderSide(color: _red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(_background),
              headingTextStyle: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              dataTextStyle: const TextStyle(color: _navy, fontSize: 12),
              horizontalMargin: 12,
              columnSpacing: 22,
              columns: const [
                DataColumn(label: Text('FOURNISSEUR')),
                DataColumn(label: Text('CONTACT')),
                DataColumn(label: Text('TÉLÉPHONE')),
                DataColumn(label: Text('SPÉCIALITÉ')),
                DataColumn(label: Text('STATUT')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: _filteredFournisseurs.map((f) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Row(
                          children: [
                            _avatar(f),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.nom,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (f.email.isNotEmpty)
                                    Text(
                                      f.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(f.contact.isEmpty ? '—' : f.contact)),
                    DataCell(Text(f.telephone.isEmpty ? '—' : f.telephone)),
                    DataCell(Text(f.specialite.isEmpty ? '—' : f.specialite)),
                    DataCell(_statusBadge(f.actif)),
                    DataCell(_actionMenu(f)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupplierCard(_Fournisseur f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(f, size: 45),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.nom,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.specialite.isEmpty
                          ? 'Spécialité non renseignée'
                          : f.specialite,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _actionMenu(f),
            ],
          ),
          const Divider(height: 24, color: _border),
          _infoRow(Icons.person_outline_rounded, f.contact),
          const SizedBox(height: 10),
          _infoRow(Icons.phone_outlined, f.telephone),
          if (f.email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.email_outlined, f.email),
          ],
          if (f.adresse.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, f.adresse),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              const Text(
                'Statut',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const Spacer(),
              _statusBadge(f.actif),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: _muted, size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value.isEmpty ? 'Non renseigné' : value,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _avatar(_Fournisseur f, {double size = 38}) {
    final words = f.nom.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: _red,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statusBadge(bool actif) {
    final color = actif ? _green : _muted;
    final background = actif
        ? const Color(0xFFE5F7F0)
        : const Color(0xFFF0F1F5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            actif ? 'Actif' : 'Inactif',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionMenu(_Fournisseur f) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_horiz_rounded, color: _muted),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _openDialog(fournisseur: f);
            break;
          case 'toggle':
            _toggleFournisseur(f);
            break;
          case 'delete':
            _confirmDelete(f);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: _navy),
              SizedBox(width: 10),
              Text('Modifier'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                f.actif
                    ? Icons.person_off_outlined
                    : Icons.person_outline_rounded,
                size: 18,
                color: _navy,
              ),
              const SizedBox(width: 10),
              Text(f.actif ? 'Désactiver' : 'Réactiver'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: _red),
              SizedBox(width: 10),
              Text('Supprimer', style: TextStyle(color: _red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openDialog({_Fournisseur? fournisseur}) async {
    final formKey = GlobalKey<FormState>();

    final nom = TextEditingController(text: fournisseur?.nom ?? '');
    final contact = TextEditingController(text: fournisseur?.contact ?? '');
    final telephone = TextEditingController(text: fournisseur?.telephone ?? '');
    final email = TextEditingController(text: fournisseur?.email ?? '');
    final specialite = TextEditingController(
      text: fournisseur?.specialite ?? '',
    );
    final adresse = TextEditingController(text: fournisseur?.adresse ?? '');

    bool actif = fournisseur?.actif ?? true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !_saving,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Text(
                  fournisseur == null
                      ? 'Ajouter un fournisseur'
                      : 'Modifier le fournisseur',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _formField(
                            nom,
                            'Nom de l’entreprise',
                            Icons.business_outlined,
                            required: true,
                          ),
                          const SizedBox(height: 13),
                          _formField(
                            contact,
                            'Nom du contact',
                            Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 13),
                          _formField(
                            telephone,
                            'Téléphone',
                            Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 13),
                          _formField(
                            email,
                            'Adresse e-mail',
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final v = value?.trim() ?? '';

                              if (v.isNotEmpty &&
                                  !RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(v)) {
                                return 'Adresse e-mail invalide.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 13),
                          _formField(
                            specialite,
                            'Produits fournis / spécialité',
                            Icons.inventory_2_outlined,
                          ),
                          const SizedBox(height: 13),
                          _formField(
                            adresse,
                            'Adresse',
                            Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: _red,
                            title: const Text(
                              'Fournisseur actif',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: actif,
                            onChanged: (value) {
                              setDialogState(() => actif = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: _muted),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final success = await _saveFournisseur(
                              id: fournisseur?.id,
                              nom: nom.text,
                              contact: contact.text,
                              telephone: telephone.text,
                              email: email.text,
                              specialite: specialite.text,
                              adresse: adresse.text,
                              actif: actif,
                            );

                            if (success && dialogContext.mounted) {
                              Navigator.pop(dialogContext);
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
                        : Text(fournisseur == null ? 'Ajouter' : 'Enregistrer'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nom.dispose();
      contact.dispose();
      telephone.dispose();
      email.dispose();
      specialite.dispose();
      adresse.dispose();
    }
  }

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _navy, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 12),
        prefixIcon: Icon(icon, size: 19, color: _muted),
        filled: true,
        fillColor: _background,
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
      ),
      validator:
          validator ??
          (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Ce champ est obligatoire.';
            }
            return null;
          },
    );
  }

  Future<bool> _saveFournisseur({
    required String? id,
    required String nom,
    required String contact,
    required String telephone,
    required String email,
    required String specialite,
    required String adresse,
    required bool actif,
  }) async {
    if (_saving) return false;

    setState(() => _saving = true);

    try {
      final data = <String, dynamic>{
        'business_id': widget.businessId,
        'name': nom.trim(),
        'contact_person': contact.trim(),
        'phone': telephone.trim(),
        'email': email.trim(),
        'specialite': specialite.trim(),
        'address': adresse.trim(),
        'is_active': actif,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (id == null) {
        await _supabase.from('suppliers').insert(data);
      } else {
        data.remove('business_id');

        await _supabase
            .from('suppliers')
            .update(data)
            .eq('id', id)
            .eq('business_id', widget.businessId);
      }

      await _loadFournisseurs();

      if (!mounted) return false;

      _showMessage(
        id == null
            ? 'Fournisseur ajouté avec succès.'
            : 'Fournisseur mis à jour.',
      );

      return true;
    } catch (e) {
      if (mounted) {
        _showMessage('Erreur de sauvegarde : $e');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleFournisseur(_Fournisseur f) async {
    if (f.id == null || _saving) return;

    final newStatus = !f.actif;

    try {
      await _supabase
          .from('suppliers')
          .update({
            'is_active': newStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', f.id!)
          .eq('business_id', widget.businessId);

      await _loadFournisseurs();

      if (!mounted) return;

      _showMessage(
        newStatus ? 'Fournisseur réactivé.' : 'Fournisseur désactivé.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erreur de modification : $e');
    }
  }

  Future<void> _confirmDelete(_Fournisseur fournisseur) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Supprimer ce fournisseur ?',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Voulez-vous supprimer ${fournisseur.nom} du répertoire ?',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final id = fournisseur.id;

    if (id == null) {
      _showMessage('Identifiant du fournisseur introuvable.');
      return;
    }

    try {
      await _supabase
          .from('suppliers')
          .delete()
          .eq('id', id)
          .eq('business_id', widget.businessId);

      await _loadFournisseurs();

      if (!mounted) return;

      _showMessage('Fournisseur supprimé.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erreur de suppression : $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Fournisseur {
  final String? id;
  String nom;
  String contact;
  String telephone;
  String email;
  String specialite;
  String adresse;
  bool actif;

  _Fournisseur({
    this.id,
    required this.nom,
    required this.contact,
    required this.telephone,
    required this.email,
    required this.specialite,
    required this.adresse,
    this.actif = true,
  });

  factory _Fournisseur.fromMap(Map<String, dynamic> map) {
    return _Fournisseur(
      id: map['id']?.toString(),
      nom: map['name']?.toString() ?? '',
      contact: map['contact_person']?.toString() ?? '',
      telephone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      specialite: map['specialite']?.toString() ?? '',
      adresse: map['address']?.toString() ?? '',
      actif: map['is_active'] as bool? ?? true,
    );
  }
}

class _Stat {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _Stat(this.title, this.value, this.icon, this.background, this.color);
}
