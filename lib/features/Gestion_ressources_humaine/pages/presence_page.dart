import 'package:flutter/material.dart';

import '../services/horaire_service.dart';
import '../services/presence_service.dart';
import '../widget/horaire_model.dart';
import '../widget/presence_model.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);

class PresencePage extends StatefulWidget {
  final String businessId;

  const PresencePage({super.key, required this.businessId});

  @override
  State<PresencePage> createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  final PresenceService _service = PresenceService();
  final TextEditingController _searchController = TextEditingController();

  final HoraireService _horaireService = HoraireService();

  List<HoraireModel> _horaires = [];

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  List<PresenceModel> _presences = [];
  bool _loading = true;
  String _search = '';

  HoraireModel? _horaireFor(String employeeId) {
    for (final horaire in _horaires) {
      if (horaire.employeeId == employeeId) {
        return horaire;
      }
    }

    return null;
  }

  String _plannedHours(HoraireModel? horaire) {
    if (horaire == null) return 'Non planifié';

    switch (horaire.scheduleType) {
      case 'rest':
        return 'Repos';
      case 'leave':
        return 'Congé';
      case 'public_holiday':
        return 'Jour férié';
      case 'work':
        if (horaire.startTime == null || horaire.endTime == null) {
          return 'Horaire incomplet';
        }

        return '${horaire.startTime!.substring(0, 5)} – '
            '${horaire.endTime!.substring(0, 5)}';
      default:
        return 'Non planifié';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPresences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPresences() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final results = await Future.wait([
        _service.getPresences(
          businessId: widget.businessId,
          date: _selectedDate,
        ),
        _horaireService.getSchedules(
          businessId: widget.businessId,
          startDate: _selectedDate,
          endDate: _selectedDate,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _presences = List<PresenceModel>.from(results[0]);
        _horaires = List<HoraireModel>.from(results[1]);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement : $e'),
          backgroundColor: _red,
        ),
      );
    }
  }

  List<PresenceModel> get _filteredPresences {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return _presences;

    return _presences.where((p) {
      return p.employeeFullName.toLowerCase().contains(query) ||
          (p.employeeNumber ?? '').toLowerCase().contains(query);
    }).toList();
  }

  int get _recordedCount => _presences.where((p) => p.id.isNotEmpty).length;

  int get _presentCount =>
      _presences.where((p) => p.id.isNotEmpty && p.status == 'present').length;

  int get _absentCount =>
      _presences.where((p) => p.id.isNotEmpty && p.status == 'absent').length;

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Choisir la date du pointage',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _red,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    setState(() => _selectedDate = DateUtils.dateOnly(date));
    await _loadPresences();
  }

  Future<TimeOfDay?> _chooseTime(TimeOfDay? initial) {
    return showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _red,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _navy,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  DateTime? _combineDateAndTime(DateTime date, TimeOfDay? time) {
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  TimeOfDay? _toTimeOfDay(DateTime? value) {
    if (value == null) return null;
    return TimeOfDay.fromDateTime(value.toLocal());
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';

    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _editPresence(PresenceModel presence) async {
    TimeOfDay? checkIn = _toTimeOfDay(presence.checkInAt);
    TimeOfDay? checkOut = _toTimeOfDay(presence.checkOutAt);

    String status = presence.id.isEmpty ? 'present' : presence.status;

    final notesController = TextEditingController(text: presence.notes ?? '');

    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                presence.employeeFullName,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(color: _muted),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Statut de présence',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: status,
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        items: PresenceService.statuses.map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(
                              PresenceModel.statusLabels[value] ?? value,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      _timePickerField(
                        label: 'Heure d’arrivée',
                        value: checkIn,
                        onTap: () async {
                          final picked = await _chooseTime(checkIn);
                          if (picked != null) {
                            setDialogState(() => checkIn = picked);
                          }
                        },
                        onClear: () {
                          setDialogState(() => checkIn = null);
                        },
                      ),
                      const SizedBox(height: 14),
                      _timePickerField(
                        label: 'Heure de départ',
                        value: checkOut,
                        onTap: () async {
                          final picked = await _chooseTime(checkOut);
                          if (picked != null) {
                            setDialogState(() => checkOut = picked);
                          }
                        },
                        onClear: () {
                          setDialogState(() => checkOut = null);
                        },
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: _inputDecoration().copyWith(
                          labelText: 'Observations (facultatif)',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Annuler', style: TextStyle(color: _muted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final arrival = _combineDateAndTime(
                            _selectedDate,
                            checkIn,
                          );
                          final departure = _combineDateAndTime(
                            _selectedDate,
                            checkOut,
                          );

                          if (arrival != null &&
                              departure != null &&
                              departure.isBefore(arrival)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Le départ doit être après l’arrivée.',
                                ),
                                backgroundColor: _red,
                              ),
                            );
                            return;
                          }

                          if (status == 'absent' &&
                              (checkIn != null || checkOut != null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pour un employé absent, '
                                  'efface les heures de présence.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            await _service.savePresence(
                              businessId: widget.businessId,
                              employeeId: presence.employeeId,
                              date: _selectedDate,
                              status: status,
                              checkInAt: arrival,
                              checkOutAt: departure,
                              notes: notesController.text,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setDialogState(() => saving = false);

                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Enregistrement impossible : $e'),
                                backgroundColor: _red,
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    notesController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pointage enregistré avec succès.'),
          backgroundColor: Color(0xFF18794E),
        ),
      );

      await _loadPresences();
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: _background,
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
    );
  }

  Widget _timePickerField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: _muted, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        value?.format(context) ?? 'Choisir une heure',
                        style: const TextStyle(color: _navy),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (value != null)
              IconButton(
                tooltip: 'Effacer l’heure',
                onPressed: onClear,
                icon: const Icon(Icons.close, color: _muted),
              ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: const TextStyle(
              color: _navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF18794E);
      case 'late':
        return const Color(0xFFB7791F);
      case 'absent':
        return _red;
      case 'half_day':
        return const Color(0xFF6D5BD0);
      case 'remote':
        return const Color(0xFF2875C7);
      default:
        return _muted;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        PresenceModel.statusLabels[status] ?? status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _employeeRow(PresenceModel presence) {
    final recorded = presence.id.isNotEmpty;

    return InkWell(
      onTap: () => _editPresence(presence),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: _navy.withValues(alpha: 0.07),
              child: Text(
                presence.employeeFirstName.isNotEmpty
                    ? presence.employeeFirstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presence.employeeFullName.isEmpty
                        ? 'Employé sans nom'
                        : presence.employeeFullName,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((presence.employeeNumber ?? '').isNotEmpty)
                    Text(
                      'Matricule : ${presence.employeeNumber}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _plannedHours(_horaireFor(presence.employeeId)),
                style: const TextStyle(color: _navy, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatTime(presence.checkInAt),
                style: const TextStyle(color: _navy),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatTime(presence.checkOutAt),
                style: const TextStyle(color: _navy),
              ),
            ),
            Expanded(
              flex: 3,
              child: recorded
                  ? _statusBadge(presence.status)
                  : const Text(
                      'Non pointé',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
            ),
            IconButton(
              tooltip: 'Modifier le pointage',
              onPressed: () => _editPresence(presence),
              icon: const Icon(Icons.edit_outlined, color: _red, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _employeeCard(PresenceModel presence) {
    final recorded = presence.id.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _editPresence(presence),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE9ECF3),
                  child: Icon(Icons.person_outline, color: _navy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    presence.employeeFullName,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.edit_outlined, color: _red),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 17,
                    color: _muted,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Prévu : ',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      _plannedHours(_horaireFor(presence.employeeId)),
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Arrivée\n${_formatTime(presence.checkInAt)}',
                    style: const TextStyle(color: _navy, height: 1.6),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Départ\n${_formatTime(presence.checkOutAt)}',
                    style: const TextStyle(color: _navy, height: 1.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            recorded
                ? _statusBadge(presence.status)
                : const Text('Non pointé', style: TextStyle(color: _muted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 850;
    final filtered = _filteredPresences;

    return Container(
      color: _background,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPresences,
          color: _red,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 16,
                spacing: 16,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des présences',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Suivez les heures et les présences de votre équipe.',
                        style: TextStyle(color: _muted),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _chooseDate,
                    icon: const Icon(Icons.calendar_month, color: _red),
                    label: Text(
                      _formatShortDate(_selectedDate),
                      style: const TextStyle(color: _navy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 3
                      : constraints.maxWidth >= 520
                      ? 2
                      : 1;

                  final cards = [
                    _statCard(
                      title: 'Employés actifs',
                      value: _presences.length,
                      icon: Icons.groups_outlined,
                      color: _navy,
                      subtitle: 'Dans cette entreprise',
                    ),
                    _statCard(
                      title: 'Présents',
                      value: _presentCount,
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF18794E),
                      subtitle: 'Statut enregistré',
                    ),
                    _statCard(
                      title: 'Absents',
                      value: _absentCount,
                      icon: Icons.person_off_outlined,
                      color: _red,
                      subtitle: 'Statut enregistré',
                    ),
                  ];

                  final spacing = 14.0;
                  final width =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: cards
                        .map((card) => SizedBox(width: width, child: card))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pointages du jour',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '$_recordedCount / ${_presences.length}',
                          style: const TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadPresences,
                          tooltip: 'Actualiser',
                          icon: const Icon(Icons.refresh, color: _navy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _search = value);
                      },
                      decoration: _inputDecoration().copyWith(
                        hintText: 'Rechercher un employé ou un matricule',
                        prefixIcon: const Icon(Icons.search, color: _muted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(color: _red),
                        ),
                      )
                    else if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 42, color: _muted),
                            SizedBox(height: 10),
                            Text(
                              'Aucun employé trouvé.',
                              style: TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      )
                    else if (isWide)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 50),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'EMPLOYÉ',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 3,
                                  child: Text(
                                    'PRÉVU',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'ARRIVÉE',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'DÉPART',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'STATUT',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 48),
                              ],
                            ),
                          ),
                          ...filtered.map(_employeeRow),
                        ],
                      )
                    else
                      ...filtered.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _employeeCard(p),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Les pointages sont enregistrés par entreprise et par date. '
                'Les employés sans pointage restent affichés jusqu’à '
                'leur enregistrement.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
