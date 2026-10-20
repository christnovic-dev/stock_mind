import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF16845B);
const Color _orange = Color(0xFFB7791F);

class DossierEmployesPage extends StatefulWidget {
  const DossierEmployesPage({super.key, required this.businessId});

  final String businessId;

  @override
  State<DossierEmployesPage> createState() => _DossierEmployesPageState();
}

class _DossierEmployesPageState extends State<DossierEmployesPage> {
  final SupabaseClient _db = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  String _search = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    if (mounted) setState(() => _loading = true);

    try {
      final result = await _db
          .from('employees')
          .select()
          .eq('business_id', widget.businessId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _employees = List<Map<String, dynamic>>.from(result);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Erreur de chargement des employés : $e', error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? _red : _navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _name(Map<String, dynamic> employee) {
    return '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
        .trim();
  }

  int _count(String status) =>
      _employees.where((e) => e['employment_status'] == status).length;

  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'on_leave':
        return 'En congé';
      case 'suspended':
        return 'Suspendu';
      case 'departed':
        return 'Parti';
      default:
        return 'Non défini';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return _green;
      case 'on_leave':
        return _orange;
      case 'suspended':
        return _red;
      default:
        return _muted;
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    final query = _search.trim().toLowerCase();

    return _employees.where((employee) {
      final searchable = [
        _name(employee),
        employee['employee_number'] ?? '',
        employee['email'] ?? '',
        employee['phone'] ?? '',
        employee['job_title'] ?? '',
        employee['department'] ?? '',
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);
      final status = employee['employment_status'] ?? 'active';

      final matchesFilter =
          _filter == 'all' ||
          (_filter == 'active' && status == 'active') ||
          (_filter == 'on_leave' && status == 'on_leave') ||
          (_filter == 'suspended' && status == 'suspended') ||
          (_filter == 'departed' && status == 'departed');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _statusBadge(String? status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // AJOUT ET MODIFICATION D'UN EMPLOYÉ
  // -----------------------------------------------------------------

  Future<void> _openEmployeeForm({Map<String, dynamic>? employee}) async {
    final editing = employee != null;

    final formKey = GlobalKey<FormState>();
    final number = TextEditingController(
      text: employee?['employee_number']?.toString() ?? '',
    );
    final firstName = TextEditingController(
      text: employee?['first_name']?.toString() ?? '',
    );
    final lastName = TextEditingController(
      text: employee?['last_name']?.toString() ?? '',
    );
    final email = TextEditingController(
      text: employee?['email']?.toString() ?? '',
    );
    final phone = TextEditingController(
      text: employee?['phone']?.toString() ?? '',
    );
    final job = TextEditingController(
      text: employee?['job_title']?.toString() ?? '',
    );
    final department = TextEditingController(
      text: employee?['department']?.toString() ?? '',
    );
    final notes = TextEditingController(
      text: employee?['notes']?.toString() ?? '',
    );

    String status = employee?['employment_status']?.toString() ?? 'active';
    DateTime? joinedAt = DateTime.tryParse(
      employee?['joined_at']?.toString() ?? '',
    );
    DateTime? leftAt = DateTime.tryParse(
      employee?['left_at']?.toString() ?? '',
    );
    bool saving = false;

    String? optionalValue(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    Future<void> pickDate(bool joining, StateSetter setDialogState) async {
      final current = joining ? joinedAt : leftAt;
      final picked = await showDatePicker(
        context: context,
        initialDate: current ?? DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime(2100),
      );

      if (picked != null) {
        setDialogState(() {
          if (joining) {
            joinedAt = picked;
          } else {
            leftAt = picked;
          }
        });
      }
    }

    Widget field(
      String label,
      TextEditingController controller, {
      bool required = false,
      TextInputType? keyboardType,
      int maxLines = 1,
    }) {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Ce champ est obligatoire'
                  : null
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          filled: true,
          fillColor: _background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: _border),
          ),
        ),
      );
    }

    Widget dateButton(
      String label,
      DateTime? value,
      VoidCallback onTap,
      VoidCallback onClear,
    ) {
      return Container(
        decoration: BoxDecoration(
          color: _background,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11)),
                    Text(
                      value == null
                          ? 'Non renseignée'
                          : _date(value.toIso8601String()),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            if (value != null)
              IconButton(
                tooltip: 'Effacer',
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 17),
              ),
          ],
        ),
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _red.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                color: _red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                editing
                                    ? 'Modifier le dossier'
                                    : 'Nouvel employé',
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Informations personnelles',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth > 480 ? 2 : 1;

                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: columns == 2 ? 3.4 : 4.0,
                              children: [
                                field('Prénom', firstName, required: true),
                                field('Nom', lastName, required: true),
                                field('Matricule', number),
                                field(
                                  'E-mail',
                                  email,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                field(
                                  'Téléphone',
                                  phone,
                                  keyboardType: TextInputType.phone,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Informations professionnelles',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth > 480 ? 2 : 1;

                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: columns == 2 ? 3.4 : 4.0,
                              children: [
                                field('Poste occupé', job),
                                field('Département', department),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: InputDecoration(
                            labelText: 'Statut de l’employé',
                            filled: true,
                            fillColor: _background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('Actif'),
                            ),
                            DropdownMenuItem(
                              value: 'on_leave',
                              child: Text('En congé'),
                            ),
                            DropdownMenuItem(
                              value: 'suspended',
                              child: Text('Suspendu'),
                            ),
                            DropdownMenuItem(
                              value: 'departed',
                              child: Text('Parti'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => status = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth > 480 ? 2 : 1;

                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: columns == 2 ? 2.6 : 4.0,
                              children: [
                                dateButton(
                                  'Date d’embauche',
                                  joinedAt,
                                  () => pickDate(true, setDialogState),
                                  () => setDialogState(() => joinedAt = null),
                                ),
                                dateButton(
                                  'Date de départ',
                                  leftAt,
                                  () => pickDate(false, setDialogState),
                                  () => setDialogState(() => leftAt = null),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        field('Notes internes', notes, maxLines: 3),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                              onPressed: saving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }

                                      if (joinedAt != null &&
                                          leftAt != null &&
                                          leftAt!.isBefore(joinedAt!)) {
                                        _showMessage(
                                          'La date de départ doit être '
                                          'postérieure à la date d’embauche.',
                                          error: true,
                                        );
                                        return;
                                      }

                                      setDialogState(() => saving = true);

                                      final data = <String, dynamic>{
                                        'business_id': widget.businessId,
                                        'employee_number': optionalValue(
                                          number.text,
                                        ),
                                        'first_name': firstName.text.trim(),
                                        'last_name': lastName.text.trim(),
                                        'email': optionalValue(email.text),
                                        'phone': optionalValue(phone.text),
                                        'job_title': optionalValue(job.text),
                                        'department': optionalValue(
                                          department.text,
                                        ),
                                        'employment_status': status,
                                        'joined_at': joinedAt == null
                                            ? null
                                            : joinedAt!
                                                  .toIso8601String()
                                                  .substring(0, 10),
                                        'left_at': leftAt == null
                                            ? null
                                            : leftAt!
                                                  .toIso8601String()
                                                  .substring(0, 10),
                                        'notes': optionalValue(notes.text),
                                        'updated_at': DateTime.now()
                                            .toUtc()
                                            .toIso8601String(),
                                      };

                                      try {
                                        if (editing) {
                                          await _db
                                              .from('employees')
                                              .update(data)
                                              .eq('id', employee['id'])
                                              .eq(
                                                'business_id',
                                                widget.businessId,
                                              )
                                              .select('id')
                                              .single();
                                        } else {
                                          data['created_by'] =
                                              _db.auth.currentUser?.id;

                                          await _db
                                              .from('employees')
                                              .insert(data)
                                              .select('id')
                                              .single();
                                        }

                                        if (!mounted) return;

                                        Navigator.pop(dialogContext);
                                        _showMessage(
                                          editing
                                              ? 'Dossier mis à jour.'
                                              : 'Employé ajouté avec succès.',
                                        );
                                        await _loadEmployees();
                                      } on PostgrestException catch (e) {
                                        setDialogState(() => saving = false);
                                        _showMessage(
                                          'Erreur Supabase : ${e.message}',
                                          error: true,
                                        );
                                      } catch (e) {
                                        setDialogState(() => saving = false);
                                        _showMessage(
                                          'Enregistrement impossible : $e',
                                          error: true,
                                        );
                                      }
                                    },
                              icon: saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                saving ? 'Enregistrement…' : 'Enregistrer',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    number.dispose();
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    job.dispose();
    department.dispose();
    notes.dispose();
  }

  // -----------------------------------------------------------------
  // ARCHIVAGE : CONSERVE LE DOSSIER ET SES DOCUMENTS
  // -----------------------------------------------------------------

  Future<void> _archiveEmployee(Map<String, dynamic> employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver cet employé ?'),
        content: Text(
          '${_name(employee)} sera marqué comme parti. '
          'Son dossier et ses documents seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _db
          .from('employees')
          .update({
            'employment_status': 'departed',
            'left_at': DateTime.now().toIso8601String().substring(0, 10),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', employee['id'])
          .eq('business_id', widget.businessId);

      _showMessage('Dossier archivé.');
      await _loadEmployees();
    } catch (e) {
      _showMessage('Archivage impossible : $e', error: true);
    }
  }

  // -----------------------------------------------------------------
  // DÉTAILS D'UN DOSSIER
  // -----------------------------------------------------------------

  Future<void> _showEmployeeDetails(Map<String, dynamic> employee) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: _red.withValues(alpha: 0.09),
                      child: Text(
                        _name(employee).isEmpty
                            ? '?'
                            : _name(employee)[0].toUpperCase(),
                        style: const TextStyle(
                          color: _red,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name(employee),
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            employee['job_title']?.toString().isNotEmpty == true
                                ? employee['job_title'].toString()
                                : 'Poste non renseigné',
                            style: const TextStyle(color: _muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _statusBadge(employee['employment_status']?.toString()),
                const SizedBox(height: 18),
                const Text(
                  'Informations du dossier',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _detailRow('Matricule', employee['employee_number']),
                _detailRow('E-mail', employee['email']),
                _detailRow('Téléphone', employee['phone']),
                _detailRow('Poste', employee['job_title']),
                _detailRow('Département', employee['department']),
                _detailRow('Embauche', _date(employee['joined_at'])),
                _detailRow('Départ', _date(employee['left_at'])),
                _detailRow('Notes', employee['notes']),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      showDialog<void>(
                        context: context,
                        builder: (_) => _EmployeeDocumentsDialog(
                          businessId: widget.businessId,
                          employeeId: employee['id'].toString(),
                          employeeName: _name(employee),
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Gérer les documents RH'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _openEmployeeForm(employee: employee);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier le dossier'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final display = value == null || value.toString().trim().isEmpty
        ? 'Non renseigné'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // CARTES STATISTIQUES COMPACTES
  // -----------------------------------------------------------------

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactInfo(IconData icon, String? value) {
    final text = value == null || value.trim().isEmpty
        ? 'Non renseigné'
        : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _employeeCard(Map<String, dynamic> employee) {
    final name = _name(employee);

    return InkWell(
      onTap: () => _showEmployeeDetails(employee),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: _red.withValues(alpha: 0.09),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: _red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Sans nom' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        employee['job_title']?.toString().isNotEmpty == true
                            ? employee['job_title'].toString()
                            : 'Poste non renseigné',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEmployeeForm(employee: employee);
                    } else if (value == 'archive') {
                      _archiveEmployee(employee);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'archive', child: Text('Archiver')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _statusBadge(employee['employment_status']?.toString()),
            const SizedBox(height: 12),
            _compactInfo(
              Icons.apartment_outlined,
              employee['department']?.toString(),
            ),
            _compactInfo(Icons.phone_outlined, employee['phone']?.toString()),
            _compactInfo(Icons.email_outlined, employee['email']?.toString()),
            const Spacer(),
            const Divider(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 15,
                  color: _muted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Embauche : ${_date(employee['joined_at'])}',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                const Icon(Icons.folder_open_outlined, color: _red, size: 17),
                const SizedBox(width: 4),
                const Text(
                  'Dossier',
                  style: TextStyle(
                    color: _red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
      selectedColor: _red.withValues(alpha: 0.10),
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _red : _border),
      labelStyle: TextStyle(
        color: selected ? _red : _muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final statColumns = constraints.maxWidth >= 950
                ? 4
                : constraints.maxWidth >= 520
                ? 2
                : 1;

            return SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dossiers employés',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Gérez les informations et documents RH de votre équipe.',
                              style: TextStyle(color: _muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualiser',
                        onPressed: _loadEmployees,
                        icon: const Icon(Icons.refresh, color: _navy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Cartes statistiques réduites en hauteur.
                  GridView.count(
                    crossAxisCount: statColumns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: statColumns == 4
                        ? 2.45
                        : statColumns == 2
                        ? 2.5
                        : 3.3,
                    children: [
                      _statCard(
                        title: 'Total employés',
                        value: _employees.length,
                        icon: Icons.groups_outlined,
                        color: _navy,
                      ),
                      _statCard(
                        title: 'Actifs',
                        value: _count('active'),
                        icon: Icons.check_circle_outline,
                        color: _green,
                      ),
                      _statCard(
                        title: 'En congé',
                        value: _count('on_leave'),
                        icon: Icons.event_busy_outlined,
                        color: _orange,
                      ),
                      _statCard(
                        title: 'Partis',
                        value: _count('departed'),
                        icon: Icons.archive_outlined,
                        color: _muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _search = value),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un employé...',
                            prefixIcon: const Icon(Icons.search, color: _muted),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border),
                            ),
                          ),
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => _openEmployeeForm(),
                          style: FilledButton.styleFrom(
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('Tous', 'all'),
                        const SizedBox(width: 8),
                        _filterChip('Actifs', 'active'),
                        const SizedBox(width: 8),
                        _filterChip('En congé', 'on_leave'),
                        const SizedBox(width: 8),
                        _filterChip('Suspendus', 'suspended'),
                        const SizedBox(width: 8),
                        _filterChip('Partis', 'departed'),
                      ],
                    ),
                  ),
                  if (!wide) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openEmployeeForm(),
                        style: FilledButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Ajouter un employé'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(45),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filteredEmployees.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 42,
                            color: _muted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _employees.isEmpty
                                ? 'Aucun employé enregistré.'
                                : 'Aucun résultat pour cette recherche.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _muted),
                          ),
                          if (_employees.isEmpty) ...[
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: () => _openEmployeeForm(),
                              style: FilledButton.styleFrom(
                                backgroundColor: _red,
                              ),
                              child: const Text('Ajouter un employé'),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredEmployees.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth >= 1250
                            ? 3
                            : constraints.maxWidth >= 700
                            ? 2
                            : 1,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 265,
                      ),
                      itemBuilder: (context, index) =>
                          _employeeCard(_filteredEmployees[index]),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =====================================================================
// FENÊTRE DE GESTION DES DOCUMENTS RH
// =====================================================================

class _EmployeeDocumentsDialog extends StatefulWidget {
  const _EmployeeDocumentsDialog({
    required this.businessId,
    required this.employeeId,
    required this.employeeName,
  });

  final String businessId;
  final String employeeId;
  final String employeeName;

  @override
  State<_EmployeeDocumentsDialog> createState() =>
      _EmployeeDocumentsDialogState();
}

class _EmployeeDocumentsDialogState extends State<_EmployeeDocumentsDialog> {
  final SupabaseClient _db = Supabase.instance.client;

  List<Map<String, dynamic>> _documents = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? _red : _navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) return '—';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _loadDocuments() async {
    if (mounted) setState(() => _loading = true);

    try {
      final result = await _db
          .from('employee_documents')
          .select()
          .eq('business_id', widget.businessId)
          .eq('employee_id', widget.employeeId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _documents = List<Map<String, dynamic>>.from(result);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Chargement des documents impossible : $e', error: true);
    }
  }

  // -----------------------------------------------------------------
  // AJOUT D'UN DOCUMENT
  // -----------------------------------------------------------------

  Future<void> _addDocument() async {
    final formKey = GlobalKey<FormState>();

    String documentType = 'CV';
    String documentName = '';
    DateTime? expiresAt;

    Map<String, dynamic>? formResult;

    // Étape 1 : ouvrir le formulaire.
    formResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter un document RH'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: documentType,
                          decoration: const InputDecoration(
                            labelText: 'Type de document',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'CV', child: Text('CV')),
                            DropdownMenuItem(
                              value: 'Contrat',
                              child: Text('Contrat de travail'),
                            ),
                            DropdownMenuItem(
                              value: 'Diplôme',
                              child: Text('Diplôme'),
                            ),
                            DropdownMenuItem(
                              value: 'Certificat',
                              child: Text('Certificat / attestation'),
                            ),
                            DropdownMenuItem(
                              value: 'Pièce administrative',
                              child: Text('Pièce administrative'),
                            ),
                            DropdownMenuItem(
                              value: 'Autre',
                              child: Text('Autre document'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null && dialogContext.mounted) {
                              setDialogState(() {
                                documentType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Nom du document *',
                            hintText: 'Ex. CV actualisé',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            documentName = value;
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le nom du document est obligatoire';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: expiresAt ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2100),
                            );

                            if (selectedDate != null && dialogContext.mounted) {
                              setDialogState(() {
                                expiresAt = selectedDate;
                              });
                            }
                          },
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            expiresAt == null
                                ? 'Date d’expiration (facultative)'
                                : 'Expiration : ${_date(expiresAt!.toIso8601String())}',
                          ),
                        ),

                        if (expiresAt != null)
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                expiresAt = null;
                              });
                            },
                            child: const Text('Effacer la date'),
                          ),

                        const SizedBox(height: 8),

                        const Text(
                          'Formats : PDF, JPG, JPEG et PNG.\n'
                          'Taille maximale : 10 Mo.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _red),
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final date = expiresAt;

                    Navigator.of(dialogContext).pop({
                      'type': documentType,
                      'name': documentName.trim(),
                      'expires_at': date == null
                          ? null
                          : '${date.year.toString().padLeft(4, '0')}-'
                                '${date.month.toString().padLeft(2, '0')}-'
                                '${date.day.toString().padLeft(2, '0')}',
                    });
                  },
                  child: const Text('Choisir le fichier'),
                ),
              ],
            );
          },
        );
      },
    );

    if (formResult == null || !mounted) return;

    // Étape 2 : sélectionner le fichier.
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (!mounted || picked.isEmpty) return;

      final PlatformFile file = picked.first;
      final extension = (file.extension ?? '').toLowerCase();

      const mimeTypes = <String, String>{
        'pdf': 'application/pdf',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
      };

      final contentType = mimeTypes[extension];

      if (contentType == null) {
        _message('Format de fichier non autorisé.', error: true);
        return;
      }

      final Uint8List bytes;

      try {
        bytes = await file.readAsBytes();
      } catch (e) {
        if (mounted) {
          _message('Impossible de lire ce fichier. Réessaie.', error: true);
        }
        return;
      }

      if (!mounted) return;

      if (bytes.length > 10 * 1024 * 1024) {
        _message(
          'Le fichier dépasse la taille maximale de 10 Mo.',
          error: true,
        );
        return;
      }

      setState(() => _uploading = true);

      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

      final storagePath =
          '${widget.businessId}/${widget.employeeId}/'
          '${DateTime.now().microsecondsSinceEpoch}_$safeName';

      var uploaded = false;

      try {
        await _db.storage
            .from('employee-documents')
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: false),
            );

        uploaded = true;

        await _db.from('employee_documents').insert({
          'business_id': widget.businessId,
          'employee_id': widget.employeeId,
          'document_type': formResult['type'],
          'document_name': formResult['name'],
          'storage_path': storagePath,
          'uploaded_by': _db.auth.currentUser?.id,
          'expires_at': formResult['expires_at'],
        });

        if (!mounted) return;

        _message('Document ajouté avec succès.');
        await _loadDocuments();
      } catch (e) {
        if (uploaded) {
          try {
            await _db.storage.from('employee-documents').remove([storagePath]);
          } catch (cleanupError) {
            debugPrint('Erreur de nettoyage du fichier : $cleanupError');
          }
        }

        rethrow;
      }
    } on PostgrestException catch (e) {
      debugPrint('Erreur Supabase : ${e.message}');

      if (mounted) {
        _message('Erreur Supabase : ${e.message}', error: true);
      }
    } catch (e, stackTrace) {
      debugPrint('Erreur ajout document : $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _message('Ajout du document impossible : $e', error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  // -----------------------------------------------------------------
  // OUVERTURE SÉCURISÉE DU DOCUMENT
  // -----------------------------------------------------------------

  Future<void> _openDocument(Map<String, dynamic> document) async {
    try {
      final signedUrl = await _db.storage
          .from('employee-documents')
          .createSignedUrl(document['storage_path'].toString(), 60);

      final uri = Uri.tryParse(signedUrl);

      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _message('Impossible d’ouvrir ce document.', error: true);
      }
    } catch (e) {
      _message('Ouverture impossible : $e', error: true);
    }
  }

  // -----------------------------------------------------------------
  // SUPPRESSION DU DOCUMENT
  // -----------------------------------------------------------------

  Future<void> _deleteDocument(Map<String, dynamic> document) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce document ?'),
        content: Text(
          'Le fichier « ${document['document_name']} » sera supprimé '
          'du dossier de ${widget.employeeName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final path = document['storage_path'].toString();

      await _db.storage.from('employee-documents').remove([path]);

      await _db
          .from('employee_documents')
          .delete()
          .eq('id', document['id'])
          .eq('business_id', widget.businessId)
          .eq('employee_id', widget.employeeId);

      _message('Document supprimé.');
      await _loadDocuments();
    } catch (e) {
      _message('Suppression impossible : $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.folder_copy_outlined, color: _red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Documents RH',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          widget.employeeName,
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_uploading || _loading) ? null : _addDocument,
                  style: FilledButton.styleFrom(
                    backgroundColor: _red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _uploading ? 'Téléversement…' : 'Ajouter un document',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Les fichiers restent privés et s’ouvrent grâce à un lien temporaire.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _documents.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 44,
                                color: _muted,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Aucun document enregistré pour cet employé.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _muted),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _documents.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final document = _documents[index];
                          final expires = document['expires_at'];
                          final expiration = expires == null
                              ? null
                              : DateTime.tryParse(expires.toString());
                          final expired =
                              expiration != null &&
                              expiration.isBefore(DateTime.now());

                          final path = document['storage_path'].toString();
                          final isPdf = path.toLowerCase().endsWith('.pdf');

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isPdf
                                    ? Icons.picture_as_pdf_outlined
                                    : Icons.image_outlined,
                                color: _red,
                              ),
                            ),
                            title: Text(
                              document['document_name'].toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document['document_type']?.toString() ??
                                      'Autre',
                                ),
                                if (expires != null)
                                  Text(
                                    'Expiration : ${_date(expires)}'
                                    '${expired ? ' • Expiré' : ''}',
                                    style: TextStyle(
                                      color: expired ? _red : _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _openDocument(document),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'open') {
                                  _openDocument(document);
                                } else if (value == 'delete') {
                                  _deleteDocument(document);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(Icons.open_in_new),
                                      SizedBox(width: 8),
                                      Text('Ouvrir'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: _red),
                                      SizedBox(width: 8),
                                      Text('Supprimer'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
