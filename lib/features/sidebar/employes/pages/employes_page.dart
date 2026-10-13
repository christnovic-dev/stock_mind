import 'package:flutter/material.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF159B72);

class EmployesPage extends StatefulWidget {
  const EmployesPage({super.key});

  @override
  State<EmployesPage> createState() => _EmployesPageState();
}

class _EmployesPageState extends State<EmployesPage> {
  final List<_Employe> _employes = [];

  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  String _statusFilter = 'Tous';

  List<_Employe> get _filteredEmployes {
    return _employes.where((employe) {
      final query = _search.toLowerCase().trim();

      final matchesSearch =
          employe.nom.toLowerCase().contains(query) ||
          employe.poste.toLowerCase().contains(query) ||
          employe.email.toLowerCase().contains(query) ||
          employe.telephone.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == 'Tous' ||
          (_statusFilter == 'Actifs' && employe.actif) ||
          (_statusFilter == 'Inactifs' && !employe.actif);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _actifs => _employes.where((e) => e.actif).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(mobile),
            const SizedBox(height: 24),
            _buildStats(mobile),
            const SizedBox(height: 26),
            _buildEmployeeSection(mobile),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool mobile) {
    return Flex(
      direction: mobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: mobile
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (mobile)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des employés',
                style: TextStyle(
                  color: _navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Organisez votre équipe et gérez ses informations.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          )
        else
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des employés',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Organisez votre équipe et gérez ses informations.',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        if (mobile) const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _openEmployeDialog(),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
          label: const Text('Ajouter un employé'),
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

  Widget _buildStats(bool mobile) {
    final cards = [
      _StatData(
        title: 'Total employés',
        value: '${_employes.length}',
        icon: Icons.groups_rounded,
        color: const Color(0xFF5276E8),
        background: const Color(0xFFEDF1FF),
      ),
      _StatData(
        title: 'Employés actifs',
        value: '$_actifs',
        icon: Icons.verified_user_outlined,
        color: _green,
        background: const Color(0xFFE5F7F0),
      ),
      _StatData(
        title: 'Employés inactifs',
        value: '${_employes.length - _actifs}',
        icon: Icons.person_off_outlined,
        color: _red,
        background: const Color(0xFFFFE9ED),
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
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 105,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];

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
                      color: card.background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(card.icon, color: card.color, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          card.value,
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

  Widget _buildEmployeeSection(bool mobile) {
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
            'Votre équipe',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Consultez et gérez les membres de votre équipe.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              final search = TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher un employé...',
                  hintStyle: const TextStyle(color: _muted, fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _muted,
                    size: 20,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          tooltip: 'Effacer la recherche',
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
                    vertical: 13,
                    horizontal: 12,
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
                value: _statusFilter,
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
                  Expanded(flex: 1, child: filter),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (_filteredEmployes.isEmpty)
            _buildEmptyState()
          else if (mobile)
            ..._filteredEmployes.map(_buildEmployeeCard)
          else
            _buildEmployeeTable(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasEmployees = _employes.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_outlined, color: _red, size: 29),
          ),
          const SizedBox(height: 16),
          Text(
            hasEmployees
                ? 'Aucun résultat trouvé'
                : 'Aucun employé pour le moment',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasEmployees
                ? 'Essayez un autre nom ou modifiez les filtres.'
                : 'Ajoutez les membres de votre équipe pour commencer.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          if (!hasEmployees) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _openEmployeDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter le premier employé'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: const BorderSide(color: _red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeTable() {
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              dataTextStyle: const TextStyle(color: _navy, fontSize: 12),
              horizontalMargin: 12,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('EMPLOYÉ')),
                DataColumn(label: Text('POSTE')),
                DataColumn(label: Text('TÉLÉPHONE')),
                DataColumn(label: Text('STATUT')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: _filteredEmployes.map((employe) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Row(
                          children: [
                            _avatar(employe),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    employe.nom,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (employe.email.isNotEmpty)
                                    Text(
                                      employe.email,
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
                    DataCell(Text(employe.poste)),
                    DataCell(Text(employe.telephone)),
                    DataCell(_statusBadge(employe.actif)),
                    DataCell(_actionMenu(employe)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeCard(_Employe employe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(employe, size: 45),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employe.nom,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employe.poste,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _actionMenu(employe),
            ],
          ),
          const Divider(height: 24, color: _border),
          _infoRow(Icons.phone_outlined, employe.telephone),
          if (employe.email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.email_outlined, employe.email),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              const Text(
                'Statut',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const Spacer(),
              _statusBadge(employe.actif),
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

  Widget _avatar(_Employe employe, {double size = 38}) {
    final initials = employe.nom.trim().split(RegExp(r'\s+'));
    final label = initials
        .take(2)
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
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
        label,
        style: const TextStyle(
          color: _red,
          fontWeight: FontWeight.w800,
          fontSize: 12,
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

  Widget _actionMenu(_Employe employe) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_horiz_rounded, color: _muted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _openEmployeDialog(employe: employe);
            break;
          case 'toggle':
            setState(() => employe.actif = !employe.actif);
            _showMessage(
              employe.actif ? 'Employé réactivé.' : 'Employé désactivé.',
            );
            break;
          case 'delete':
            _confirmDelete(employe);
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
                employe.actif
                    ? Icons.person_off_outlined
                    : Icons.person_outline_rounded,
                size: 18,
                color: _navy,
              ),
              const SizedBox(width: 10),
              Text(employe.actif ? 'Désactiver' : 'Réactiver'),
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

  Future<void> _openEmployeDialog({_Employe? employe}) async {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: employe?.nom ?? '');
    final posteController = TextEditingController(text: employe?.poste ?? '');
    final telephoneController = TextEditingController(
      text: employe?.telephone ?? '',
    );
    final emailController = TextEditingController(text: employe?.email ?? '');
    bool actif = employe?.actif ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                employe == null ? 'Ajouter un employé' : 'Modifier l’employé',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _formField(
                          controller: nomController,
                          label: 'Nom complet',
                          icon: Icons.person_outline_rounded,
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: posteController,
                          label: 'Poste / Fonction',
                          icon: Icons.work_outline_rounded,
                          required: true,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: telephoneController,
                          label: 'Téléphone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: emailController,
                          label: 'Adresse e-mail',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isNotEmpty &&
                                !RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                              return 'Adresse e-mail invalide.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: _red,
                          title: const Text(
                            'Employé actif',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Indique si cette personne fait partie de l’équipe active.',
                            style: TextStyle(color: _muted, fontSize: 11),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler', style: TextStyle(color: _muted)),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final nom = nomController.text.trim();
                    final poste = posteController.text.trim();

                    setState(() {
                      if (employe == null) {
                        _employes.add(
                          _Employe(
                            nom: nom,
                            poste: poste,
                            telephone: telephoneController.text.trim(),
                            email: emailController.text.trim(),
                            actif: actif,
                          ),
                        );
                      } else {
                        employe
                          ..nom = nom
                          ..poste = poste
                          ..telephone = telephoneController.text.trim()
                          ..email = emailController.text.trim()
                          ..actif = actif;
                      }
                    });

                    Navigator.pop(dialogContext);
                    _showMessage(
                      employe == null
                          ? 'Employé ajouté avec succès.'
                          : 'Informations mises à jour.',
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(employe == null ? 'Ajouter' : 'Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    nomController.dispose();
    posteController.dispose();
    telephoneController.dispose();
    emailController.dispose();
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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

  Future<void> _confirmDelete(_Employe employe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Supprimer cet employé ?',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Voulez-vous supprimer ${employe.nom} de la liste ?',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _employes.remove(employe));
      _showMessage('Employé supprimé.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Employe {
  String nom;
  String poste;
  String telephone;
  String email;
  bool actif;

  _Employe({
    required this.nom,
    required this.poste,
    required this.telephone,
    required this.email,
    this.actif = true,
  });
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });
}
