import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/tache_service.dart';
import '../widgets/tache_model.dart';

const Color _red = Color(0xFFF21D3D);
const Color _navy = Color(0xFF14264B);
const Color _background = Color(0xFFF7F8FC);
const Color _muted = Color(0xFF7B8498);
const Color _border = Color(0xFFE9ECF3);
const Color _green = Color(0xFF159B72);

class EquipeTachesPage extends StatefulWidget {
  final String businessId;
  final bool isOwner;
  final List<Map<String, dynamic>> members;

  const EquipeTachesPage({
    super.key,
    required this.businessId,
    required this.isOwner,
    required this.members,
  });

  @override
  State<EquipeTachesPage> createState() => _EquipeTachesPageState();
}

class _EquipeTachesPageState extends State<EquipeTachesPage> {
  final TacheService _service = TacheService();
  List<TacheModel> _tasks = [];
  bool _loading = true;
  bool _saving = false;
  String _filter = 'Toutes';
  DateTime? _selectedDate;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (mounted) setState(() => _loading = true);
    try {
      final tasks = await _service.getTasks(
        businessId: widget.businessId,
        date: _selectedDate,
        onlyMyTasks: _filter == 'Mes tâches',
      );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Impossible de charger les tâches : $e');
    }
  }

  String _memberName(String userId) {
    final found = widget.members.where(
      (m) => m['user_id']?.toString() == userId,
    );
    if (found.isEmpty) return 'Membre de l’équipe';
    final member = found.first;
    final name = (member['full_name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    return (member['email'] ?? 'Membre de l’équipe').toString();
  }

  bool _isAssignedToMe(TacheModel task) {
    final id = _currentUserId;
    if (id == null) return false;
    return task.assignments.any((a) => a['user_id']?.toString() == id);
  }

  Map<String, dynamic>? _myAssignment(TacheModel task) {
    final id = _currentUserId;
    if (id == null) return null;
    for (final assignment in task.assignments) {
      if (assignment['user_id']?.toString() == id) return assignment;
    }
    return null;
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    await _loadTasks();
  }

  Future<void> _openCreateDialog() async {
    if (!widget.isOwner) return;

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime dueDate = _selectedDate ?? DateTime.now();
    TimeOfDay? dueTime;
    String priority = 'normal';
    final selectedIds = <String>{};
    final currentId = _currentUserId;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Créer une tâche',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      maxLength: 180,
                      decoration: _decoration(
                        'Titre de la tâche',
                        Icons.task_alt,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Titre obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: _decoration(
                        'Description (facultatif)',
                        Icons.notes,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month, color: _red),
                      title: const Text(
                        'Date prévue',
                        style: TextStyle(color: _navy),
                      ),
                      subtitle: Text(_formatDate(dueDate)),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null)
                          setDialogState(() => dueDate = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule, color: _red),
                      title: const Text(
                        'Heure limite (facultative)',
                        style: TextStyle(color: _navy),
                      ),
                      subtitle: Text(
                        dueTime == null
                            ? 'Aucune heure'
                            : dueTime!.format(context),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: dueTime ?? TimeOfDay.now(),
                        );
                        if (picked != null)
                          setDialogState(() => dueTime = picked);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: priority,
                      isExpanded: true,
                      decoration: _decoration('Priorité', Icons.flag_outlined),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Basse')),
                        DropdownMenuItem(
                          value: 'normal',
                          child: Text('Normale'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('Haute')),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Text('Urgente'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => priority = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Assigner à',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.members.map((member) {
                      final id = member['user_id']?.toString();
                      if (id == null || id.isEmpty)
                        return const SizedBox.shrink();
                      final name = _memberName(id);
                      final isMe = id == currentId;
                      return CheckboxListTile(
                        value: selectedIds.contains(id),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _red,
                        title: Text(
                          isMe ? '$name (moi)' : name,
                          style: const TextStyle(color: _navy, fontSize: 13),
                        ),
                        subtitle: Text(
                          (member['role'] ?? '').toString(),
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                        onChanged: (checked) => setDialogState(() {
                          if (checked == true) {
                            selectedIds.add(id);
                          } else {
                            selectedIds.remove(id);
                          }
                        }),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedIds.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Choisissez au moins un membre.'),
                          ),
                        );
                        return;
                      }
                      setDialogState(() {});
                      try {
                        final time = dueTime == null
                            ? null
                            : '${dueTime!.hour.toString().padLeft(2, '0')}:'
                                  '${dueTime!.minute.toString().padLeft(2, '0')}:00';
                        await _service.createTask(
                          businessId: widget.businessId,
                          title: titleController.text,
                          description: descriptionController.text,
                          dueDate: dueDate,
                          dueTime: time,
                          priority: priority,
                          assigneeIds: selectedIds.toList(),
                        );
                        if (dialogContext.mounted)
                          Navigator.pop(dialogContext, true);
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Création impossible : $e')),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.add_task),
              label: const Text('Créer la tâche'),
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
    if (saved == true && mounted) {
      _message('Tâche créée.');
      await _loadTasks();
    }
  }

  Future<void> _toggleCompletion(TacheModel task) async {
    final assignment = _myAssignment(task);
    if (assignment == null) {
      _message('Cette tâche ne vous est pas assignée.');
      return;
    }
    try {
      if (assignment['status'] == 'completed') {
        await _service.markPending(assignment['id'].toString());
      } else {
        await _service.markCompleted(assignment['id'].toString());
      }
      await _loadTasks();
    } catch (e) {
      _message('Impossible de mettre à jour la tâche : $e');
    }
  }

  Future<void> _deleteTask(TacheModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette tâche ?'),
        content: Text('« ${task.title} » sera supprimée pour toute l’équipe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteTask(task.id);
      await _loadTasks();
      _message('Tâche supprimée.');
    } catch (e) {
      _message('Suppression impossible : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Tâches de l’équipe',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildIntro(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            if (widget.isOwner)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nouvelle tâche'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: _red)),
              )
            else if (_tasks.isEmpty)
              _empty()
            else
              ..._tasks.map(_taskCard),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF263F70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Une équipe mieux organisée',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Planifiez, attribuez et suivez les tâches du quotidien.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Toutes'),
          selected: _filter == 'Toutes',
          onSelected: (_) {
            setState(() => _filter = 'Toutes');
            _loadTasks();
          },
          selectedColor: const Color(0xFFFFE9ED),
        ),
        ChoiceChip(
          label: const Text('Mes tâches'),
          selected: _filter == 'Mes tâches',
          onSelected: (_) {
            setState(() => _filter = 'Mes tâches');
            _loadTasks();
          },
          selectedColor: const Color(0xFFFFE9ED),
        ),
        OutlinedButton.icon(
          onPressed: _chooseDate,
          icon: const Icon(Icons.calendar_month, size: 18),
          label: Text(
            _selectedDate == null
                ? 'Toutes les dates'
                : _formatDate(_selectedDate!),
          ),
        ),
        if (_selectedDate != null)
          IconButton(
            tooltip: 'Effacer le filtre de date',
            onPressed: () {
              setState(() => _selectedDate = null);
              _loadTasks();
            },
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }

  Widget _taskCard(TacheModel task) {
    final mine = _myAssignment(task);
    final completedCount = task.assignments
        .where((a) => a['status'] == 'completed')
        .length;
    final total = task.assignments.length;
    final completed = total > 0 && completedCount == total;
    final overdue = task.isOverdue;
    final priority = _priorityInfo(task.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFE5F7F0)
                      : const Color(0xFFFFE9ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  completed
                      ? Icons.check_circle_outline
                      : Icons.assignment_outlined,
                  color: completed ? _green : _red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatDate(task.dueDate)}${task.dueTime == null ? '' : ' · ${task.dueTime!.substring(0, 5)}'}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (widget.isOwner)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') _deleteTask(task);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer la tâche'),
                    ),
                  ],
                ),
            ],
          ),
          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              task.description,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _pill(priority.$1, priority.$2, priority.$3),
              _pill(
                overdue
                    ? 'En retard'
                    : completed
                    ? 'Terminée'
                    : 'À faire',
                overdue
                    ? _red
                    : completed
                    ? _green
                    : _navy,
                overdue
                    ? const Color(0xFFFFE9ED)
                    : completed
                    ? const Color(0xFFE5F7F0)
                    : const Color(0xFFF0F1F5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Assignée à',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: task.assignments.map((assignment) {
              final id = assignment['user_id'].toString();
              final done = assignment['status'] == 'completed';
              return _pill(
                '${_memberName(id)}${done ? ' ✓' : ''}',
                done ? _green : _navy,
                done ? const Color(0xFFE5F7F0) : _background,
              );
            }).toList(),
          ),
          if (total > 1) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0 ? 0 : completedCount / total,
              backgroundColor: _border,
              color: _green,
              minHeight: 5,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 5),
            Text(
              '$completedCount sur $total personne(s) ont terminé',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
          if (mine != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _toggleCompletion(task),
                icon: Icon(
                  mine['status'] == 'completed'
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  mine['status'] == 'completed'
                      ? 'Annuler ma confirmation'
                      : 'Marquer comme terminée',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: mine['status'] == 'completed'
                      ? _navy
                      : _green,
                  side: BorderSide(
                    color: mine['status'] == 'completed' ? _border : _green,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, Color foreground, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (String, Color, Color) _priorityInfo(String priority) {
    switch (priority) {
      case 'urgent':
        return ('Urgente', _red, const Color(0xFFFFE9ED));
      case 'high':
        return ('Haute', const Color(0xFFB7791F), const Color(0xFFFFF3DF));
      case 'low':
        return ('Basse', _muted, const Color(0xFFF0F1F5));
      default:
        return ('Normale', _navy, const Color(0xFFEDF1FF));
    }
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.checklist_rounded, color: _red, size: 42),
          SizedBox(height: 12),
          Text(
            'Aucune tâche pour le moment',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Les tâches de votre équipe apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }
}
