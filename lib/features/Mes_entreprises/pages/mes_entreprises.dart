import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockmind/features/core/constant/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../onboarding/pages/company_onboarding_page.dart';
import '../../sidebar/overview/pages/overview_page.dart';

/// Page d'accueil après la connexion :
/// - affiche les entreprises dont l'utilisateur est membre ;
/// - affiche les invitations en attente ;
/// - permet de créer une nouvelle entreprise.
///
/// Cette page suppose les tables `businesses`, `business_members` et
/// `invitations`, avec les colonnes utilisées dans les requêtes ci-dessous.
class MesEntreprisesPage extends StatefulWidget {
  const MesEntreprisesPage({super.key});

  @override
  State<MesEntreprisesPage> createState() => _MesEntreprisesPageState();
}

class _MesEntreprisesPageState extends State<MesEntreprisesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _memberships = [];
  List<Map<String, dynamic>> _invitations = [];
  final Set<String> _busyInvitations = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Votre session a expiré. Veuillez vous reconnecter.');
      }

      final membershipResponse = await _supabase
          .from('business_members')
          .select(
            'business_id, user_id, role, '
            'business:businesses(id, name, sector, city)',
          )
          .eq('user_id', user.id);

      final email = user.email?.trim().toLowerCase();
      List<Map<String, dynamic>> invitationRows = [];

      if (email != null && email.isNotEmpty) {
        final invitationResponse = await _supabase
            .from('invitations')
            .select(
              'id, token, business_id, email, role, status, expires_at, '
              'business:businesses(id, name, sector, city)',
            )
            .ilike('email', email)
            .eq('status', 'pending')
            .gt('expires_at', DateTime.now().toUtc().toIso8601String());

        invitationRows = (invitationResponse as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _memberships = List<Map<String, dynamic>>.from(membershipResponse);
        _invitations = invitationRows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _createBusiness() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const CompanyOnboardingPage(),
          ),
        )
        .then((_) => _loadData());
  }

  void _openBusiness(Map<String, dynamic> membership) {
    final business = _asMap(membership['business']);
    if (business == null) {
      _showMessage(
        'Impossible de charger les informations de cette entreprise.',
      );
      return;
    }

    // TODO : lorsque OverviewPage acceptera un businessId, lui transmettre
    // business['id'] afin de filtrer toutes les données sur cette entreprise.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OverviewPage(
          businessId: business['id'].toString(),
          businessName: business['name']?.toString() ?? 'Mon entreprise',
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(Map<String, dynamic> invitation) async {
    final invitationId = invitation['id']?.toString();
    final token = invitation['token']?.toString();

    if (invitationId == null ||
        invitationId.isEmpty ||
        token == null ||
        token.isEmpty) {
      _showMessage('Les informations de cette invitation sont incomplètes.');
      return;
    }

    if (_busyInvitations.contains(invitationId)) return;

    setState(() => _busyInvitations.add(invitationId));

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Votre session a expiré. Reconnectez-vous.');
      }

      final result = await _supabase.rpc(
        'accept_business_invitation',
        params: {'p_token': token},
      );

      final businessId = result?.toString();

      await _loadData();

      if (!mounted) return;

      _showMessage('Invitation acceptée. Vous avez rejoint l’entreprise.');

      if (businessId != null && businessId.isNotEmpty) {
        Map<String, dynamic>? membership;

        for (final item in _memberships) {
          if (item['business_id']?.toString() == businessId) {
            membership = item;
            break;
          }
        }

        if (membership != null) {
          _openBusiness(membership);
        }
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible d’accepter l’invitation : '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );

      await _loadData();
    } finally {
      if (mounted) {
        setState(() => _busyInvitations.remove(invitationId));
      }
    }
  }

  Future<void> _declineInvitation(Map<String, dynamic> invitation) async {
    final invitationId = invitation['id']?.toString();

    if (invitationId == null || invitationId.isEmpty) return;
    if (_busyInvitations.contains(invitationId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Refuser l’invitation ?', style: _headingStyle(17)),
        content: Text(
          'Vous ne rejoindrez pas cette entreprise.',
          style: _bodyStyle(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyInvitations.add(invitationId));

    try {
      await _supabase.rpc(
        'decline_business_invitation',
        params: {'p_invitation_id': invitationId},
      );

      await _loadData();

      if (!mounted) return;
      _showMessage('Invitation refusée.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de refuser cette invitation : '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _busyInvitations.remove(invitationId));
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _text(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  String _roleLabel(dynamic role) {
    switch (_text(role).toLowerCase()) {
      case 'owner':
      case 'proprietaire':
      case 'propriétaire':
        return 'Propriétaire';
      case 'admin':
      case 'administrator':
        return 'Administrateur';
      case 'stock_manager':
      case 'gestionnaire_stock':
        return 'Gestionnaire de stock';
      case 'employee':
      case 'employe':
      case 'employé':
        return 'Employé';
      default:
        return _text(role, fallback: 'Membre');
    }
  }

  TextStyle _headingStyle(double size) => GoogleFonts.poppins(
    color: AppColors.navy,
    fontSize: size,
    fontWeight: FontWeight.w700,
  );

  TextStyle _bodyStyle(double size) =>
      GoogleFonts.poppins(color: AppColors.muted, fontSize: size, height: 1.65);

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final displayName = _text(
      user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'],
      fallback: user?.email?.split('@').first ?? 'Utilisateur',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTopBar(),
                        const SizedBox(height: 36),
                        _buildWelcome(displayName),
                        const SizedBox(height: 28),
                        _buildCreateBusinessBanner(),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          title: 'Mes entreprises',
                          subtitle:
                              'Retrouvez tous vos espaces de travail au même endroit.',
                          count: _memberships.length,
                        ),
                        const SizedBox(height: 16),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_error != null)
                          _buildErrorState()
                        else if (_memberships.isEmpty)
                          _buildEmptyBusinesses()
                        else
                          _buildBusinessGrid(),
                        if (!_loading && _error == null) ...[
                          const SizedBox(height: 34),
                          _buildSectionHeader(
                            title: 'Invitations reçues',
                            subtitle:
                                'Acceptez une invitation pour rejoindre l’équipe concernée.',
                            count: _invitations.length,
                          ),
                          const SizedBox(height: 16),
                          if (_invitations.isEmpty)
                            _buildNoInvitations()
                          else
                            ..._invitations.map(_buildInvitationCard),
                        ],
                        const SizedBox(height: 34),
                        _buildFooter(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: AppColors.navy,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
            children: const [
              TextSpan(text: 'Stock'),
              TextSpan(
                text: 'Mind',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _loading ? null : _loadData,
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bonjour $name 👋', style: _headingStyle(27)),
        const SizedBox(height: 8),
        Text(
          'Choisissez une entreprise pour continuer à travailler, ou créez un nouvel espace si vous gérez une autre activité.',
          style: _bodyStyle(13),
        ),
      ],
    );
  }

  Widget _buildCreateBusinessBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF172B52), Color(0xFF263F70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 530;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Vous gérez une nouvelle activité ?',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Créez un autre espace StockMind. Vos stocks et vos équipes resteront séparés.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
          );
          final button = ElevatedButton.icon(
            onPressed: _createBusiness,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Créer une entreprise'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, const SizedBox(height: 18), button],
            );
          }
          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 18),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _headingStyle(18)),
              const SizedBox(height: 5),
              Text(subtitle, style: _bodyStyle(11)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 850
            ? 3
            : width >= 570
            ? 2
            : 1;
        final ratio = columns == 1 ? 2.0 : 1.35;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _memberships.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) =>
              _buildBusinessCard(_memberships[index]),
        );
      },
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> membership) {
    final business = _asMap(membership['business']) ?? {};
    final name = _text(business['name'], fallback: 'Entreprise sans nom');
    final sector = _text(business['sector'], fallback: 'Activité non précisée');
    final city = _text(business['city'], fallback: 'Ville non précisée');
    final role = _roleLabel(membership['role']);
    final isOwner = _text(membership['role']).toLowerCase() == 'owner';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openBusiness(membership),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: .025),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: AppColors.primary,
                      size: 25,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isOwner
                          ? const Color(0xFFE9F8F0)
                          : const Color(0xFFEEF3FF),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: isOwner
                            ? const Color(0xFF168052)
                            : const Color(0xFF3159B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _headingStyle(15),
              ),
              const SizedBox(height: 5),
              Text(
                sector,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _bodyStyle(11),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyStyle(10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ouvrir',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final business = _asMap(invitation['business']) ?? {};
    final id = invitation['id']?.toString() ?? '';
    final name = _text(business['name'], fallback: 'Entreprise');
    final city = _text(business['city'], fallback: 'Ville non précisée');
    final role = _roleLabel(invitation['role']);
    final busy = _busyInvitations.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE5C2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          final info = Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: Color(0xFFB86A12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _headingStyle(13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$role • $city',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyStyle(10),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: busy ? null : () => _declineInvitation(invitation),
                child: Text(
                  'Refuser',
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: busy ? null : () => _acceptInvitation(invitation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Accepter',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyBusinesses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.business_center_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune entreprise pour le moment',
            textAlign: TextAlign.center,
            style: _headingStyle(15),
          ),
          const SizedBox(height: 7),
          Text(
            'Créez votre première entreprise ou acceptez une invitation reçue par e-mail.',
            textAlign: TextAlign.center,
            style: _bodyStyle(11),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _createBusiness,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Créer une entreprise'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInvitations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.muted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vous n’avez aucune invitation en attente.',
              style: _bodyStyle(11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text('Chargement impossible', style: _headingStyle(15)),
          const SizedBox(height: 6),
          Text(
            _error ?? 'Une erreur est survenue.',
            textAlign: TextAlign.center,
            style: _bodyStyle(11),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'StockMind • Un seul compte, plusieurs entreprises.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: AppColors.muted, fontSize: 10),
      ),
    );
  }
}
