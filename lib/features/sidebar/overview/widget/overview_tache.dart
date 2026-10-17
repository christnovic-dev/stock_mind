import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../equipe/service/tache_service.dart';
import '../../equipe/widgets/tache_model.dart';

class TacheOverview extends StatefulWidget {
  final String businessId;
  final VoidCallback onViewTasks;

  const TacheOverview({
    super.key,
    required this.businessId,
    required this.onViewTasks,
  });

  @override
  State<TacheOverview> createState() => _TacheOverviewState();
}

class _TacheOverviewState extends State<TacheOverview> {
  final TacheService _service = TacheService();

  bool _isLoading = true;
  String? _error;
  List<TacheModel> _tasks = [];

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant TacheOverview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    if (widget.businessId.isEmpty) {
      setState(() {
        _tasks = [];
        _isLoading = false;
        _error = 'Aucune entreprise sélectionnée.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _service.getTasks(
        businessId: widget.businessId,
        onlyMyTasks: true,
      );

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Impossible de charger les tâches.';
        _isLoading = false;
      });
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<String, dynamic>? _myAssignment(TacheModel task) {
    final userId = _userId;

    if (userId == null) return null;

    for (final assignment in task.assignments) {
      if (assignment['user_id']?.toString() == userId) {
        return assignment;
      }
    }

    return null;
  }

  bool _isMyTaskCompleted(TacheModel task) {
    final assignment = _myAssignment(task);

    return assignment?['status']?.toString() == 'completed';
  }

  List<TacheModel> get _todayTasks {
    final tasks = _tasks.where((task) {
      return _dateOnly(task.dueDate) == _today;
    }).toList();

    tasks.sort((a, b) {
      final timeA = a.dueTime ?? '23:59';
      final timeB = b.dueTime ?? '23:59';
      return timeA.compareTo(timeB);
    });

    return tasks;
  }

  List<TacheModel> get _overdueTasks {
    final tasks = _tasks.where((task) {
      return _dateOnly(task.dueDate).isBefore(_today) &&
          !_isMyTaskCompleted(task);
    }).toList();

    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return tasks;
  }

  List<TacheModel> get _upcomingTasks {
    final tasks = _tasks.where((task) {
      return _dateOnly(task.dueDate).isAfter(_today) &&
          !_isMyTaskCompleted(task);
    }).toList();

    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return tasks.take(5).toList();
  }

  String _formatDate(DateTime date) {
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(String? time) {
    if (time == null || time.trim().isEmpty) {
      return 'Horaire non défini';
    }

    final parts = time.split(':');

    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return time;
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFF21D3D);
      case 'high':
      case 'haute':
      case 'élevée':
        return const Color(0xFFE67E22);
      case 'low':
      case 'basse':
      case 'faible':
        return const Color(0xFF16A085);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _priorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'Urgente';
      case 'high':
      case 'haute':
      case 'élevée':
        return 'Haute';
      case 'low':
      case 'basse':
      case 'faible':
        return 'Basse';
      default:
        return 'Normale';
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF14264B);
    const muted = Color(0xFF7B8498);
    const border = Color(0xFFE9ECF3);
    const background = Color(0xFFF7F8FC);
    const red = Color(0xFFF21D3D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.task_alt_rounded, color: red, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes tâches',
                      style: TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre programme du jour',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _isLoading ? null : _loadTasks,
                icon: const Icon(Icons.refresh_rounded, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: red)),
            )
          else if (_error != null)
            _buildMessage(
              icon: Icons.info_outline_rounded,
              message: _error!,
              actionLabel: 'Réessayer',
              onAction: _loadTasks,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(
                  todayCount: _todayTasks.length,
                  overdueCount: _overdueTasks.length,
                ),
                const SizedBox(height: 22),
                _buildTaskGroup(
                  title: 'À faire aujourd’hui',
                  subtitle: 'Vos priorités du jour',
                  icon: Icons.today_rounded,
                  tasks: _todayTasks,
                  emptyMessage: 'Aucune tâche prévue aujourd’hui.',
                  emptyIcon: Icons.event_available_rounded,
                  background: background,
                  navy: navy,
                  muted: muted,
                  red: red,
                ),
                if (_overdueTasks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildTaskGroup(
                    title: 'En retard',
                    subtitle: 'À traiter dès que possible',
                    icon: Icons.warning_amber_rounded,
                    tasks: _overdueTasks,
                    emptyMessage: 'Aucune tâche en retard.',
                    emptyIcon: Icons.check_circle_outline_rounded,
                    background: background,
                    navy: navy,
                    muted: muted,
                    red: red,
                    isOverdue: true,
                  ),
                ],
                if (_upcomingTasks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildTaskGroup(
                    title: 'À venir',
                    subtitle: 'Les prochaines échéances',
                    icon: Icons.upcoming_rounded,
                    tasks: _upcomingTasks,
                    emptyMessage: 'Aucune tâche à venir.',
                    emptyIcon: Icons.event_available_rounded,
                    background: background,
                    navy: navy,
                    muted: muted,
                    red: red,
                    showDate: true,
                  ),
                ],
              ],
            ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onViewTasks,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Voir toutes mes tâches'),
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                side: const BorderSide(color: border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary({required int todayCount, required int overdueCount}) {
    const navy = Color(0xFF14264B);
    const red = Color(0xFFF21D3D);
    const muted = Color(0xFF7B8498);

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.today_rounded,
            label: 'Aujourd’hui',
            value: todayCount.toString(),
            color: navy,
            background: const Color(0xFFF2F5FA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.warning_amber_rounded,
            label: 'En retard',
            value: overdueCount.toString(),
            color: overdueCount > 0 ? red : muted,
            background: overdueCount > 0
                ? red.withValues(alpha: 0.06)
                : const Color(0xFFF7F8FC),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7B8498),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskGroup({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<TacheModel> tasks,
    required String emptyMessage,
    required IconData emptyIcon,
    required Color background,
    required Color navy,
    required Color muted,
    required Color red,
    bool isOverdue = false,
    bool showDate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: isOverdue ? red : navy, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isOverdue ? red : navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOverdue ? red.withValues(alpha: 0.08) : background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tasks.length.toString(),
                style: TextStyle(
                  color: isOverdue ? red : navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(emptyIcon, color: muted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _buildTaskTile(
                task: task,
                background: background,
                navy: navy,
                muted: muted,
                red: red,
                isOverdue: isOverdue,
                showDate: showDate,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskTile({
    required TacheModel task,
    required Color background,
    required Color navy,
    required Color muted,
    required Color red,
    bool isOverdue = false,
    bool showDate = false,
  }) {
    final completed = _isMyTaskCompleted(task);
    final priorityColor = _priorityColor(task.priority);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isOverdue
              ? red.withValues(alpha: 0.15)
              : const Color(0xFFE9ECF3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: completed ? const Color(0xFF16A085) : muted,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: completed ? muted : navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (showDate)
                      _smallTag(
                        icon: Icons.calendar_today_rounded,
                        label: _formatDate(task.dueDate),
                        color: navy,
                      ),
                    _smallTag(
                      icon: Icons.access_time_rounded,
                      label: _formatTime(task.dueTime),
                      color: muted,
                    ),
                    _smallTag(
                      icon: Icons.flag_rounded,
                      label: _priorityLabel(task.priority),
                      color: priorityColor,
                    ),
                    if (isOverdue && !completed)
                      _smallTag(
                        icon: Icons.error_outline_rounded,
                        label: 'En retard',
                        color: red,
                      ),
                    if (completed)
                      _smallTag(
                        icon: Icons.check_rounded,
                        label: 'Terminée',
                        color: const Color(0xFF16A085),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    const muted = Color(0xFF7B8498);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: muted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}
