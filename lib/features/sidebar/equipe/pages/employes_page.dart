import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'equipe_tache.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF159B72);

class EmployesPage extends StatefulWidget {
  final String businessId;

  const EmployesPage({super.key, required this.businessId});

  @override
  State<EmployesPage> createState() => _EmployesPageState();
}

class _EmployesPageState extends State<EmployesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _invitations = [];

  String _search = '';
  String _roleFilter = 'Tous';
  bool _loading = true;
  bool _busy = false;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Map<String, dynamic>? get _currentMember {
    for (final member in _members) {
      if (member['user_id']?.toString() == _currentUserId) {
        return member;
      }
    }
    return null;
  }

  bool get _isOwner => _currentMember?['role'] == 'owner';

  List<Map<String, dynamic>> get _filteredMembers {
    final query = _search.toLowerCase().trim();

    return _members.where((member) {
      final name = (member['full_name'] ?? '').toString().toLowerCase();
      final email = (member['email'] ?? '').toString().toLowerCase();
      final role = (member['role'] ?? '').toString();

      final matchesSearch = name.contains(query) || email.contains(query);

      final matchesRole = _roleFilter == 'Tous' || role == _roleFilter;

      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant EmployesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.businessId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _supabase.rpc(
        'list_business_members',
        params: {'p_business_id': widget.businessId},
      );

      final members = (result as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final current = _currentUserId;

      debugPrint('========== STOCKMIND EMPLOYÉS ==========');
      debugPrint('Business ID : ${widget.businessId}');
      debugPrint('Utilisateur connecté : $current');
      debugPrint('Membres retournés par le RPC : $members');
      debugPrint('=========================================');

      final currentMember = members.where(
        (member) => member['user_id']?.toString() == current,
      );

      final isOwner =
          currentMember.isNotEmpty && currentMember.first['role'] == 'owner';

      debugPrint(
        'Rôle détecté pour moi : '
        '${currentMember.isNotEmpty ? currentMember.first['role'] : 'INTROUVABLE'}',
      );
      debugPrint('isOwner : $isOwner');

      List<Map<String, dynamic>> invitations = [];

      // Seul le propriétaire consulte et gère les invitations.
      if (isOwner) {
        final invitationResult = await _supabase
            .from('invitations')
            .select('id, email, role, status, created_at, expires_at, token')
            .eq('business_id', widget.businessId)
            .eq('status', 'pending')
            .order('created_at', ascending: false);

        invitations = (invitationResult as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      if (!mounted) return;

      setState(() {
        _members = members;
        _invitations = invitations;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Impossible de charger les membres : $error');
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'owner':
        return 'Propriétaire';
      case 'admin':
        return 'Administrateur';
      case 'stock_manager':
        return 'Gestionnaire de stock';
      case 'employee':
        return 'Employé';
      default:
        return role ?? 'Non défini';
    }
  }

  String _displayName(Map<String, dynamic> member) {
    final name = (member['full_name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;

    final email = (member['email'] ?? '').toString().trim();
    if (email.isNotEmpty) return email;

    return 'Membre StockMind';
  }

  List<String> get _availableRoles => const [
    'admin',
    'stock_manager',
    'employee',
  ];

  Future<void> _openInvitationDialog() async {
    if (!_isOwner) {
      _showMessage('Seul le propriétaire peut inviter des membres.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    String selectedRole = 'employee';

    final shouldReload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool sending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Inviter un membre',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'La personne devra se connecter avec cette adresse e-mail pour accepter l’invitation.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          'Adresse e-mail',
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Saisissez une adresse e-mail.';
                          }

                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Adresse e-mail invalide.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          'Rôle attribué',
                          Icons.admin_panel_settings_outlined,
                        ),
                        items: _availableRoles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(
                              _roleLabel(role),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedRole = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Annuler', style: TextStyle(color: _muted)),
                ),
                FilledButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => sending = true);

                          final invitedEmail = emailController.text
                              .trim()
                              .toLowerCase();

                          try {
                            // 1. Créer l'invitation dans Supabase.
                            final result = await _supabase.rpc(
                              'create_business_invitation',
                              params: {
                                'p_business_id': widget.businessId,
                                'p_email': invitedEmail,
                                'p_role': selectedRole,
                              },
                            );

                            final token = result.toString().trim();

                            if (token.isEmpty || token == 'null') {
                              throw Exception(
                                'Supabase n’a pas retourné de jeton d’invitation.',
                              );
                            }

                            if (!mounted || !dialogContext.mounted) return;

                            // 2. Fermer le formulaire et retourner un résultat positif.
                            Navigator.pop(dialogContext, true);

                            // 3. Afficher le lien à partager manuellement.
                            await _showInvitationLink(token);
                          } catch (error) {
                            if (!mounted || !dialogContext.mounted) return;

                            setDialogState(() => sending = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Impossible de créer l’invitation : $error',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },

                  label: Text(sending ? 'Envoi...' : 'Créer l’invitation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();

    if (shouldReload == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _showInvitationLink(String token) async {
    // URL publique de StockMind sur GitHub Pages.
    const String baseUrl = 'https://christnovic-dev.github.io/stock_mind/';

    // Construit le lien public avec le token Supabase existant.
    final uri = Uri.parse(baseUrl).replace(queryParameters: {'invite': token});

    final link = uri.toString();

    debugPrint('========== INVITATION STOCKMIND ==========');
    debugPrint('Lien généré : $link');
    debugPrint('==========================================');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Invitation créée',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copiez ce lien et envoyez-le à la personne invitée.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              SelectableText(
                link,
                style: const TextStyle(color: _navy, fontSize: 12),
              ),
              const SizedBox(height: 10),
              const Text(
                'Le lien expire après 7 jours. La personne doit utiliser '
                'le compte associé à l’adresse e-mail invitée.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));

              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);
              _showMessage('Lien public copié dans le presse-papiers.');
            },
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: const Text('Copier le lien'),
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(Map<String, dynamic> member, String role) async {
    final userId = member['user_id']?.toString();

    if (!_isOwner || userId == null) return;

    try {
      await _supabase.rpc(
        'change_business_member_role',
        params: {
          'p_business_id': widget.businessId,
          'p_member_user_id': userId,
          'p_role': role,
        },
      );

      _showMessage('Rôle modifié avec succès.');
      await _loadData();
    } catch (error) {
      _showMessage('Impossible de modifier le rôle : $error');
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final userId = member['user_id']?.toString();

    if (!_isOwner || userId == null) return;

    final name = _displayName(member);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Retirer ce membre ?',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '$name ne sera plus membre de cette entreprise.',
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
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _supabase.rpc(
        'remove_business_member',
        params: {
          'p_business_id': widget.businessId,
          'p_member_user_id': userId,
        },
      );

      _showMessage('Membre retiré de l’entreprise.');
      await _loadData();
    } catch (error) {
      _showMessage('Impossible de retirer ce membre : $error');
    }
  }

  Future<void> _cancelInvitation(Map<String, dynamic> invitation) async {
    if (!_isOwner) return;

    final id = invitation['id']?.toString();
    if (id == null) return;

    try {
      await _supabase.rpc(
        'cancel_business_invitation',
        params: {'p_invitation_id': id},
      );

      _showMessage('Invitation annulée.');
      await _loadData();
    } catch (error) {
      _showMessage('Impossible d’annuler l’invitation : $error');
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted, fontSize: 12),
      prefixIcon: Icon(icon, color: _muted, size: 19),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;

        if (_loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: _red),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(mobile),
            const SizedBox(height: 24),
            _buildStats(),
            const SizedBox(height: 24),
            _buildMemberSection(mobile),
            if (_isOwner) ...[
              const SizedBox(height: 24),
              _buildInvitationSection(mobile),
            ],
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
                'Organisez votre équipe et gérez les accès.',
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
                  'Organisez votre équipe et gérez les accès.',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        if (mobile) const SizedBox(height: 18),
        if (_isOwner)
          FilledButton.icon(
            onPressed: _busy ? null : _openInvitationDialog,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
            label: const Text('Inviter un membre'),
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        SizedBox(width: 7),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EquipeTachesPage(
                  businessId: widget.businessId,
                  isOwner: _isOwner,
                  members: _members,
                ),
              ),
            );
          },
          icon: const Icon(Icons.checklist_rounded),
          label: const Text('Tâches de l’équipe'),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final cards = [
      _StatData(
        title: 'Membres',
        value: '${_members.length}',
        icon: Icons.groups_rounded,
        color: const Color(0xFF5276E8),
        background: const Color(0xFFEDF1FF),
      ),
      _StatData(
        title: 'Administrateurs',
        value: '${_members.where((m) => m['role'] == 'admin').length}',
        icon: Icons.admin_panel_settings_outlined,
        color: _green,
        background: const Color(0xFFE5F7F0),
      ),
      _StatData(
        title: 'Invitations en attente',
        value: '${_invitations.length}',
        icon: Icons.mark_email_unread_outlined,
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

  Widget _buildMemberSection(bool mobile) {
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
            'Les membres ayant accès à cette entreprise.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            decoration:
                _inputDecoration(
                  'Rechercher par nom ou e-mail',
                  Icons.search_rounded,
                ).copyWith(
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _roleFilter,
            isExpanded: true,
            decoration: _inputDecoration('Filtrer par rôle', Icons.filter_list),
            items: [
              const DropdownMenuItem(
                value: 'Tous',
                child: Text('Tous les rôles'),
              ),
              ...const ['owner', 'admin', 'stock_manager', 'employee'].map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(_roleLabel(role)),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _roleFilter = value);
            },
          ),
          const SizedBox(height: 18),
          if (_filteredMembers.isEmpty)
            _emptyState(
              title: _members.isEmpty
                  ? 'Aucun membre trouvé'
                  : 'Aucun résultat',
              message: _members.isEmpty
                  ? 'Les membres de cette entreprise apparaîtront ici.'
                  : 'Essayez un autre terme ou un autre rôle.',
              icon: Icons.groups_outlined,
            )
          else if (mobile)
            ..._filteredMembers.map(_buildMemberCard)
          else
            _buildMemberTable(),
        ],
      ),
    );
  }

  Widget _buildMemberTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(_background),
        headingTextStyle: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: const TextStyle(color: _navy, fontSize: 12),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('MEMBRE')),
          DataColumn(label: Text('RÔLE')),
          DataColumn(label: Text('DATE D’ARRIVÉE')),
          DataColumn(label: Text('ACTIONS')),
        ],
        rows: _filteredMembers.map((member) {
          final isCurrent = member['user_id']?.toString() == _currentUserId;
          final isMemberOwner = member['role'] == 'owner';

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      _avatar(_displayName(member)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName(member),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              (member['email'] ?? '').toString(),
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
              DataCell(_roleBadge(member['role']?.toString())),
              DataCell(Text(_formatDate(member['joined_at']?.toString()))),
              DataCell(
                _memberActions(
                  member,
                  canManage: _isOwner && !isMemberOwner && !isCurrent,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isCurrent = member['user_id']?.toString() == _currentUserId;
    final isMemberOwner = member['role'] == 'owner';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(_displayName(member), size: 45),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(member),
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (member['email'] ?? '').toString(),
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _memberActions(
                member,
                canManage: _isOwner && !isMemberOwner && !isCurrent,
              ),
            ],
          ),
          const Divider(height: 24, color: _border),
          Row(
            children: [
              const Text('Rôle', style: TextStyle(color: _muted, fontSize: 12)),
              const Spacer(),
              _roleBadge(member['role']?.toString()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Membre depuis',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                _formatDate(member['joined_at']?.toString()),
                style: const TextStyle(color: _navy, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memberActions(
    Map<String, dynamic> member, {
    required bool canManage,
  }) {
    if (!canManage) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_horiz_rounded, color: _muted),
      onSelected: (value) async {
        if (value == 'role') {
          await _openRoleDialog(member);
        } else if (value == 'remove') {
          await _removeMember(member);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'role',
          child: Row(
            children: [
              Icon(Icons.manage_accounts_outlined, color: _navy, size: 18),
              SizedBox(width: 10),
              Text('Modifier le rôle'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.person_remove_outlined, color: _red, size: 18),
              SizedBox(width: 10),
              Text('Retirer le membre', style: TextStyle(color: _red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openRoleDialog(Map<String, dynamic> member) async {
    String selectedRole = member['role']?.toString() ?? 'employee';

    final role = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Modifier le rôle',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            isExpanded: true,
            decoration: _inputDecoration('Nouveau rôle', Icons.security),
            items: _availableRoles.map((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(_roleLabel(value)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedRole = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, selectedRole),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (role != null && role != member['role'] && mounted) {
      await _changeRole(member, role);
    }
  }

  Widget _buildInvitationSection(bool mobile) {
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
            'Invitations en attente',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Les personnes invitées qui n’ont pas encore rejoint votre équipe.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_invitations.isEmpty)
            _emptyState(
              title: 'Aucune invitation en attente',
              message: 'Les invitations créées apparaîtront ici.',
              icon: Icons.mark_email_read_outlined,
            )
          else
            ..._invitations.map(_buildInvitationCard),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final email = (invitation['email'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, color: _red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_roleLabel(invitation['role']?.toString())} · Expire le ${_formatDate(invitation['expires_at']?.toString())}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Annuler l’invitation',
            onPressed: () => _cancelInvitation(invitation),
            icon: const Icon(Icons.cancel_outlined, color: _red),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: _red, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name, {double size = 38}) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
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
        initials.isEmpty ? 'M' : initials,
        style: const TextStyle(
          color: _red,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _roleBadge(String? role) {
    final isOwner = role == 'owner';
    final isAdmin = role == 'admin';

    final color = isOwner
        ? const Color(0xFF5276E8)
        : isAdmin
        ? _green
        : _navy;

    final background = isOwner
        ? const Color(0xFFEDF1FF)
        : isAdmin
        ? const Color(0xFFE5F7F0)
        : const Color(0xFFF0F1F5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _roleLabel(role),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '—';

    final date = DateTime.tryParse(value);
    if (date == null) return '—';

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
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
