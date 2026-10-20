import 'package:flutter/material.dart';

import '../services/horaire_service.dart';
import '../widget/horaire_model.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);

class HorairePage extends StatefulWidget {
  final String businessId;

  const HorairePage({super.key, required this.businessId});

  @override
  State<HorairePage> createState() => _HorairePageState();
}

class _HorairePageState extends State<HorairePage> {
  final HoraireService _service = HoraireService();

  bool _loading = true;
  bool _saving = false;
  bool _isMonthView = false;

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _employees = [];
  List<HoraireModel> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime get _periodStart {
    if (_isMonthView) {
      return DateTime(_selectedDate.year, _selectedDate.month, 1);
    }

    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime get _periodEnd {
    if (_isMonthView) {
      return DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    }

    return _periodStart.add(const Duration(days: 6));
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _service.getEmployees(widget.businessId),
        _service.getSchedules(
          businessId: widget.businessId,
          startDate: _periodStart,
          endDate: _periodEnd,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _employees = List<Map<String, dynamic>>.from(results[0] as List);
        _schedules = List<HoraireModel>.from(results[1] as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Impossible de charger le planning : $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _movePeriod(int direction) {
    setState(() {
      if (_isMonthView) {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + direction,
          1,
        );
      } else {
        _selectedDate = _selectedDate.add(Duration(days: direction * 7));
      }
    });

    _loadData();
  }

  void _goToToday() {
    setState(() => _selectedDate = DateTime.now());
    _loadData();
  }

  String _dateLabel(DateTime date) {
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

  String _periodLabel() {
    if (_isMonthView) {
      return '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    }

    return '${_dateLabel(_periodStart)} – ${_dateLabel(_periodEnd)}';
  }

  String _dayName(DateTime date) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return days[date.weekday - 1];
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  HoraireModel? _scheduleFor(String employeeId, DateTime date) {
    for (final schedule in _schedules) {
      if (schedule.employeeId == employeeId &&
          _dateKey(schedule.scheduleDate) == _dateKey(date)) {
        return schedule;
      }
    }

    return null;
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'work':
        return const Color(0xFFE5F7ED);
      case 'rest':
        return const Color(0xFFE8EDFF);
      case 'leave':
        return const Color(0xFFFFE8EC);
      case 'public_holiday':
        return const Color(0xFFFFF1D6);
      default:
        return Colors.white;
    }
  }

  Color _typeTextColor(String? type) {
    switch (type) {
      case 'work':
        return const Color(0xFF18794E);
      case 'rest':
        return const Color(0xFF3155A6);
      case 'leave':
        return _red;
      case 'public_holiday':
        return const Color(0xFF9A6700);
      default:
        return _muted;
    }
  }

  String _scheduleText(HoraireModel? schedule) {
    if (schedule == null) return 'Non défini';

    switch (schedule.scheduleType) {
      case 'rest':
        return 'Repos';
      case 'leave':
        return 'Congé';
      case 'public_holiday':
        return 'Férié';
      case 'work':
        return '${schedule.startTime!.substring(0, 5)}\n– ${schedule.endTime!.substring(0, 5)}';
      default:
        return 'Non défini';
    }
  }

  Future<void> _openEditor({
    required Map<String, dynamic> employee,
    required DateTime date,
  }) async {
    final employeeId = employee['id'].toString();
    final existing = _scheduleFor(employeeId, date);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _HoraireEditorDialog(
        employee: employee,
        date: date,
        existing: existing,
        service: _service,
        businessId: widget.businessId,
      ),
    );

    if (result == true) {
      await _loadData();
      _showMessage('Planning enregistré.');
    }
  }

  Future<void> _deleteSchedule(HoraireModel schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cet horaire ?'),
        content: const Text(
          'Cette action supprimera la planification de cette journée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteSchedule(
        id: schedule.id,
        businessId: widget.businessId,
      );
      await _loadData();
      _showMessage('Horaire supprimé.');
    } catch (e) {
      _showMessage('Erreur de suppression : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Container(
      color: _background,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            children: [
              _buildHeader(isMobile),
              const SizedBox(height: 22),
              _buildSummary(),
              const SizedBox(height: 22),
              _buildToolbar(isMobile),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_employees.isEmpty)
                _buildEmptyEmployees()
              else
                _isMonthView
                    ? _buildMonthView(isMobile)
                    : _buildWeekView(isMobile),
              const SizedBox(height: 24),
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: _red,
            size: 25,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planning des horaires',
                style: TextStyle(
                  color: _navy,
                  fontSize: isMobile ? 21 : 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Organisez les horaires de votre équipe.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        if (!isMobile)
          FilledButton.icon(
            onPressed: _employees.isEmpty
                ? null
                : () => _openEditor(
                    employee: _employees.first,
                    date: _selectedDate,
                  ),
            icon: const Icon(Icons.add, size: 19),
            label: const Text('Planifier'),
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    final work = _schedules.where((s) => s.scheduleType == 'work').length;
    final rest = _schedules.where((s) => s.scheduleType == 'rest').length;
    final leave = _schedules
        .where(
          (s) =>
              s.scheduleType == 'leave' || s.scheduleType == 'public_holiday',
        )
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 580;

        final cards = [
          _SummaryCard(
            label: 'Employés actifs',
            value: '${_employees.length}',
            icon: Icons.groups_rounded,
            color: const Color(0xFF3155A6),
          ),
          _SummaryCard(
            label: 'Services planifiés',
            value: '$work',
            icon: Icons.work_history_rounded,
            color: const Color(0xFF18794E),
          ),
          _SummaryCard(
            label: 'Jours de repos',
            value: '$rest',
            icon: Icons.weekend_rounded,
            color: const Color(0xFF3155A6),
          ),
          _SummaryCard(
            label: 'Congés / fériés',
            value: '$leave',
            icon: Icons.event_busy_rounded,
            color: _red,
          ),
        ];

        return GridView.count(
          crossAxisCount: compact ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: compact ? 1.8 : 1.65,
          children: cards,
        );
      },
    );
  }

  Widget _buildToolbar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Période précédente',
                onPressed: () => _movePeriod(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  _periodLabel(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Période suivante',
                onPressed: () => _movePeriod(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              TextButton(
                onPressed: _goToToday,
                child: const Text("Aujourd'hui"),
              ),
            ],
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.view_week_outlined),
                label: Text('Semaine'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.calendar_month_outlined),
                label: Text('Mois'),
              ),
            ],
            selected: {_isMonthView},
            onSelectionChanged: (selection) {
              setState(() => _isMonthView = selection.first);
              _loadData();
            },
            showSelectedIcon: false,
          ),
          if (isMobile)
            FilledButton.icon(
              onPressed: _employees.isEmpty
                  ? null
                  : () => _openEditor(
                      employee: _employees.first,
                      date: _selectedDate,
                    ),
              icon: const Icon(Icons.add),
              label: const Text('Planifier'),
              style: FilledButton.styleFrom(backgroundColor: _red),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyEmployees() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, size: 48, color: _muted),
          SizedBox(height: 12),
          Text(
            'Aucun employé actif',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ajoutez d’abord des employés actifs pour créer le planning.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(bool isMobile) {
    final days = List.generate(
      7,
      (index) => _periodStart.add(Duration(days: index)),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Planning hebdomadaire',
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1, color: _border),
          if (isMobile)
            ..._employees.map((employee) {
              return _buildMobileEmployee(employee, days);
            })
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_background),
                columnSpacing: 14,
                columns: [
                  const DataColumn(
                    label: SizedBox(
                      width: 150,
                      child: Text('Employé', style: TextStyle(color: _navy)),
                    ),
                  ),
                  ...days.map(
                    (day) => DataColumn(
                      label: SizedBox(
                        width: 94,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayName(day),
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                rows: _employees.map((employee) {
                  final employeeId = employee['id'].toString();

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      ...days.map((day) {
                        final schedule = _scheduleFor(employeeId, day);

                        return DataCell(
                          _ScheduleCell(
                            text: _scheduleText(schedule),
                            background: _typeColor(schedule?.scheduleType),
                            foreground: _typeTextColor(schedule?.scheduleType),
                            onTap: () =>
                                _openEditor(employee: employee, date: day),
                            onLongPress: schedule == null
                                ? null
                                : () => _deleteSchedule(schedule),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileEmployee(
    Map<String, dynamic> employee,
    List<DateTime> days,
  ) {
    final employeeId = employee['id'].toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}',
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              final schedule = _scheduleFor(employeeId, day);

              return SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_dayName(day)} ${day.day}',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    _ScheduleCell(
                      text: _scheduleText(schedule),
                      background: _typeColor(schedule?.scheduleType),
                      foreground: _typeTextColor(schedule?.scheduleType),
                      onTap: () => _openEditor(employee: employee, date: day),
                      onLongPress: schedule == null
                          ? null
                          : () => _deleteSchedule(schedule),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(bool isMobile) {
    final firstDay = _periodStart;
    final totalDays = _periodEnd.day;
    final leadingDays = firstDay.weekday - 1;
    final totalCells = ((leadingDays + totalDays + 6) ~/ 7) * 7;

    final dates = List.generate(totalCells, (index) {
      return firstDay.add(Duration(days: index - leadingDays));
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dates.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: isMobile ? 0.68 : 1.05,
            ),
            itemBuilder: (context, index) {
              final date = dates[index];
              final inMonth = date.month == _selectedDate.month;
              final daySchedules = _schedules
                  .where((s) => _dateKey(s.scheduleDate) == _dateKey(date))
                  .toList();

              final workCount = daySchedules
                  .where((s) => s.scheduleType == 'work')
                  .length;

              final restCount = daySchedules
                  .where((s) => s.scheduleType == 'rest')
                  .length;

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final employee = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (dialogContext) {
                      String? selectedId = _employees.first['id'].toString();

                      return StatefulBuilder(
                        builder: (context, setDialogState) {
                          return AlertDialog(
                            title: Text(
                              'Planifier le ${date.day}/${date.month}',
                            ),
                            content: DropdownButtonFormField<String>(
                              initialValue: selectedId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Employé',
                              ),
                              items: _employees.map((e) {
                                return DropdownMenuItem<String>(
                                  value: e['id'].toString(),
                                  child: Text(
                                    '${e['first_name']} ${e['last_name']}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() => selectedId = value);
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Annuler'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  final match = _employees.firstWhere(
                                    (e) => e['id'].toString() == selectedId,
                                  );
                                  Navigator.pop(dialogContext, match);
                                },
                                child: const Text('Continuer'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );

                  if (employee != null && mounted) {
                    await _openEditor(employee: employee, date: date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: inMonth ? Colors.white : _background,
                    border: Border.all(
                      color: _dateKey(date) == _dateKey(DateTime.now())
                          ? _red
                          : _border,
                      width: _dateKey(date) == _dateKey(DateTime.now())
                          ? 1.5
                          : 0.7,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: inMonth ? _navy : _muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (workCount > 0)
                        Text(
                          '$workCount travail',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF18794E),
                            fontSize: 9,
                          ),
                        ),
                      if (restCount > 0)
                        Text(
                          '$restCount repos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF3155A6),
                            fontSize: 9,
                          ),
                        ),
                      if (daySchedules.isEmpty)
                        const Text(
                          '—',
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(String label, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      );
    }

    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        item('Travail', const Color(0xFFE5F7ED)),
        item('Repos', const Color(0xFFE8EDFF)),
        item('Congé', const Color(0xFFFFE8EC)),
        item('Jour férié', const Color(0xFFFFF1D6)),
        item('Non défini', Colors.white),
      ],
    );
  }
}

class _ScheduleCell extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ScheduleCell({
    required this.text,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: foreground.withValues(alpha: 0.12)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoraireEditorDialog extends StatefulWidget {
  final Map<String, dynamic> employee;
  final DateTime date;
  final HoraireModel? existing;
  final HoraireService service;
  final String businessId;

  const _HoraireEditorDialog({
    required this.employee,
    required this.date,
    required this.existing,
    required this.service,
    required this.businessId,
  });

  @override
  State<_HoraireEditorDialog> createState() => _HoraireEditorDialogState();
}

class _HoraireEditorDialogState extends State<_HoraireEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  late String _type;
  late int _breakMinutes;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    _type = existing?.scheduleType ?? 'work';
    _breakMinutes = existing?.breakMinutes ?? 0;
    _notesController.text = existing?.notes ?? '';

    if (existing?.startTime != null) {
      final parts = existing!.startTime!.split(':');
      _start = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      _start = const TimeOfDay(hour: 8, minute: 0);
    }

    if (existing?.endTime != null) {
      final parts = existing!.endTime!.split(':');
      _end = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      _end = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _start! : _end!;

    final picked = await showTimePicker(context: context, initialTime: current);

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.service.saveSchedule(
        id: widget.existing?.id,
        businessId: widget.businessId,
        employeeId: widget.employee['id'].toString(),
        date: widget.date,
        scheduleType: _type,
        startTime: _type == 'work' ? _formatTime(_start) : null,
        endTime: _type == 'work' ? _formatTime(_end) : null,
        breakMinutes: _type == 'work' ? _breakMinutes : 0,
        notes: _notesController.text,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeName =
        '${widget.employee['first_name'] ?? ''} ${widget.employee['last_name'] ?? ''}';

    return AlertDialog(
      title: const Text(
        'Planifier un horaire',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName.trim(),
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.date.day.toString().padLeft(2, '0')}/${widget.date.month.toString().padLeft(2, '0')}/${widget.date.year}',
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type de journée',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'work', child: Text('Travail')),
                    DropdownMenuItem(value: 'rest', child: Text('Repos')),
                    DropdownMenuItem(value: 'leave', child: Text('Congé')),
                    DropdownMenuItem(
                      value: 'public_holiday',
                      child: Text('Jour férié'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _type = value);
                          }
                        },
                ),
                if (_type == 'work') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : () => _pickTime(true),
                          icon: const Icon(Icons.login_rounded),
                          label: Text('Début\n${_formatTime(_start)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : () => _pickTime(false),
                          icon: const Icon(Icons.logout_rounded),
                          label: Text('Fin\n${_formatTime(_end)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _breakMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Pause',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Aucune')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                      DropdownMenuItem(value: 45, child: Text('45 minutes')),
                      DropdownMenuItem(value: 60, child: Text('1 heure')),
                      DropdownMenuItem(value: 90, child: Text('1 h 30')),
                      DropdownMenuItem(value: 120, child: Text('2 heures')),
                      DropdownMenuItem(value: 240, child: Text('4 heures')),
                      DropdownMenuItem(value: 480, child: Text('8 heures')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _breakMinutes = value);
                            }
                          },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (facultatif)',
                    hintText: 'Ex. : service du matin',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
          style: FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
