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
  final TextEditingController _searchController = TextEditingController();

  List<TacheModel> _tasks = [];
  bool _loading = true;
  bool _saving = false;

  String _filter = 'Toutes';
  String _statusFilter = 'Toutes';
  DateTime? _selectedDate;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant EquipeTachesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.businessId != widget.businessId) {
      _tasks = [];
      _selectedDate = null;
      _filter = 'Toutes';
      _statusFilter = 'Toutes';
      _searchController.clear();
      _loadTasks();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // STATUTS ET FILTRES
  // ------------------------------------------------------------

  bool _isTaskCompleted(TacheModel task) {
    return task.assignments.isNotEmpty &&
        task.assignments.every((a) => a['status'] == 'completed');
  }

  bool _isTaskOverdue(TacheModel task) {
    return task.isOverdue && !_isTaskCompleted(task);
  }

  List<TacheModel> get _visibleTasks {
    final query = _searchController.text.trim().toLowerCase();

    return _tasks.where((task) {
      final completed = _isTaskCompleted(task);
      final overdue = _isTaskOverdue(task);

      final matchesStatus = switch (_statusFilter) {
        'À faire' => !completed && !overdue,
        'Terminées' => completed,
        'En retard' => overdue,
        _ => true,
      };

      final matchesSearch =
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  int get _completedCount => _tasks.where(_isTaskCompleted).length;

  int get _overdueCount => _tasks.where(_isTaskOverdue).length;

  int get _pendingCount => _tasks.length - _completedCount - _overdueCount;

  // ------------------------------------------------------------
  // CHARGEMENT DES TACHES
  // ------------------------------------------------------------

  Future<void> _loadTasks() async {
    if (widget.businessId.isEmpty) {
      if (mounted) {
        setState(() {
          _tasks = [];
          _loading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

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

  Map<String, dynamic>? _myAssignment(TacheModel task) {
    final id = _currentUserId;
    if (id == null) return null;

    for (final assignment in task.assignments) {
      if (assignment['user_id']?.toString() == id) {
        return assignment;
      }
    }

    return null;
  }

  // ------------------------------------------------------------
  // FILTRE DE DATE
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // CREATION D'UNE TACHE
  // ------------------------------------------------------------

  Future<void> _openCreateDialog() async {
    if (!widget.isOwner || _saving) return;

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    DateTime dueDate = _selectedDate ?? DateTime.now();
    TimeOfDay? dueTime;
    String priority = 'normal';

    final selectedIds = <String>{};
    final currentId = _currentUserId;

    bool savingDialog = false;

    try {
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
                        validator: (v) => v == null || v.trim().isEmpty
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
                            locale: const Locale('fr', 'FR'),
                          );

                          if (picked != null && dialogContext.mounted) {
                            setDialogState(() {
                              dueDate = picked;
                            });
                          }
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

                          if (picked != null && dialogContext.mounted) {
                            setDialogState(() {
                              dueTime = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: priority,
                        isExpanded: true,
                        decoration: _decoration(
                          'Priorité',
                          Icons.flag_outlined,
                        ),
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
                          if (v != null) {
                            setDialogState(() => priority = v);
                          }
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
                      if (widget.members.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Aucun membre disponible.',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                      ...widget.members.map((member) {
                        final id = member['user_id']?.toString();

                        if (id == null || id.isEmpty) {
                          return const SizedBox.shrink();
                        }

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
                          onChanged: savingDialog
                              ? null
                              : (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selectedIds.add(id);
                                    } else {
                                      selectedIds.remove(id);
                                    }
                                  });
                                },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: savingDialog
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: savingDialog
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

                        setDialogState(() => savingDialog = true);

                        if (mounted) {
                          setState(() => _saving = true);
                        }

                        try {
                          final time = dueTime == null
                              ? null
                              : '${dueTime!.hour.toString().padLeft(2, '0')}:'
                                    '${dueTime!.minute.toString().padLeft(2, '0')}:00';

                          await _service.createTask(
                            businessId: widget.businessId,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            dueDate: dueDate,
                            dueTime: time,
                            priority: priority,
                            assigneeIds: selectedIds.toList(),
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setDialogState(() => savingDialog = false);

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Création impossible : $e'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _saving = false);
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

      if (saved == true && mounted) {
        _message('Tâche créée.');
        await _loadTasks();
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  // ------------------------------------------------------------
  // CONFIRMATION ET SUPPRESSION
  // ------------------------------------------------------------

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
    if (!widget.isOwner) return;

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

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteTask(task.id);
      await _loadTasks();
      _message('Tâche supprimée.');
    } catch (e) {
      _message('Suppression impossible : $e');
    }
  }

  // ------------------------------------------------------------
  // INTERFACE PRINCIPALE
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Gestion de l’équipe',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildIntro(),
            const SizedBox(height: 18),
            _buildStats(),
            const SizedBox(height: 18),
            _buildSearch(),
            const SizedBox(height: 12),
            _buildStatusFilters(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            if (widget.isOwner)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _openCreateDialog,
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
            else if (_visibleTasks.isEmpty)
              _empty()
            else
              _buildKanban(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BANNIERE
  // ------------------------------------------------------------

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.view_kanban_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des tâches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Organisez le travail et suivez les tâches de votre équipe.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STATISTIQUES
  // ------------------------------------------------------------

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 650 ? 4 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 2 ? 2.5 : 3.3,
          children: [
            _statCard('Total', _tasks.length, Icons.checklist_rounded, _navy),
            _statCard('To do', _pendingCount, Icons.pending_actions, _muted),
            _statCard(
              'Terminées',
              _completedCount,
              Icons.check_circle_outline,
              _green,
            ),
            _statCard(
              'En retard',
              _overdueCount,
              Icons.warning_amber_rounded,
              _red,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RECHERCHE
  // ------------------------------------------------------------

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Rechercher une tâche...',
        prefixIcon: const Icon(Icons.search, color: _muted),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _red),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTRES DE STATUT
  // ------------------------------------------------------------

  Widget _buildStatusFilters() {
    const filters = ['Toutes', 'À faire', 'Terminées', 'En retard'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _statusFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() => _statusFilter = filter);
              },
              selectedColor: const Color(0xFFFFE9ED),
              labelStyle: TextStyle(
                color: selected ? _red : _navy,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: selected ? _red : _border),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTRES MEMBRE ET DATE
  // ------------------------------------------------------------

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Toutes les tâches'),
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

  // ------------------------------------------------------------
  // TABLEAU KANBAN : 3 COLONNES
  // ------------------------------------------------------------

  Widget _buildKanban() {
    final columns = <Map<String, dynamic>>[
      {
        'title': 'To do',
        'icon': Icons.radio_button_unchecked_rounded,
        'color': _navy,
        'background': const Color(0xFFEDF1FF),
        'tasks': _visibleTasks.where((task) {
          return !_isTaskCompleted(task) && !_isTaskOverdue(task);
        }).toList(),
      },
      {
        'title': 'Terminé',
        'icon': Icons.check_circle_outline_rounded,
        'color': _green,
        'background': const Color(0xFFE5F7F0),
        'tasks': _visibleTasks.where(_isTaskCompleted).toList(),
      },
      {
        'title': 'En retard',
        'icon': Icons.warning_amber_rounded,
        'color': _red,
        'background': const Color(0xFFFFE9ED),
        'tasks': _visibleTasks.where(_isTaskOverdue).toList(),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth >= 1000 ? 300.0 : 280.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((column) {
              final tasks = column['tasks'] as List<TacheModel>;
              final color = column['color'] as Color;
              final background = column['background'] as Color;

              return Container(
                width: columnWidth,
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            column['icon'] as IconData,
                            color: color,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            column['title'] as String,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${tasks.length}',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (tasks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 22,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: const Text(
                          'Aucune tâche',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      )
                    else
                      ...tasks.map(_kanbanTaskCard),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // CARTE D'UNE TACHE KANBAN
  // ------------------------------------------------------------

  Widget _kanbanTaskCard(TacheModel task) {
    final total = task.assignments.length;
    final completedCount = task.assignments
        .where((a) => a['status'] == 'completed')
        .length;

    final completed = _isTaskCompleted(task);
    final overdue = _isTaskOverdue(task);
    final priority = _priorityInfo(task.priority);
    final mine = _myAssignment(task);

    final statusLabel = overdue
        ? 'En retard'
        : completed
        ? 'Terminé'
        : 'To do';

    final statusColor = overdue
        ? _red
        : completed
        ? _green
        : _navy;

    final statusBackground = overdue
        ? const Color(0xFFFFE9ED)
        : completed
        ? const Color(0xFFE5F7F0)
        : const Color(0xFFEDF1FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.isOwner)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 19,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteTask(task);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
            ],
          ),
          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _pill(priority.$1, priority.$2, priority.$3),
              _pill(statusLabel, statusColor, statusBackground),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_formatDate(task.dueDate)}'
                  '${task.dueTime == null ? '' : ' · ${task.dueTime!.substring(0, 5)}'}',
                  style: TextStyle(
                    color: overdue ? _red : _muted,
                    fontSize: 11,
                    fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'RESPONSABLES',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (task.assignments.isEmpty)
            const Text(
              'Aucun responsable',
              style: TextStyle(color: _muted, fontSize: 11),
            )
          else
            ...task.assignments.map((assignment) {
              final id = assignment['user_id']?.toString() ?? '';
              final done = assignment['status'] == 'completed';

              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.account_circle_outlined,
                      color: done ? _green : _muted,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _memberName(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _navy, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (total > 1) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completedCount / total,
                minHeight: 5,
                backgroundColor: _border,
                color: _green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$completedCount/$total terminées',
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
          if (mine != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _toggleCompletion(task),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  foregroundColor: mine['status'] == 'completed'
                      ? _navy
                      : _green,
                  side: BorderSide(
                    color: mine['status'] == 'completed' ? _border : _green,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  mine['status'] == 'completed'
                      ? 'Annuler ma confirmation'
                      : 'Marquer comme terminée',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BADGES ET PRIORITES
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // ETAT VIDE
  // ------------------------------------------------------------

  Widget _empty() {
    final hasFilters =
        _searchController.text.trim().isNotEmpty ||
        _statusFilter != 'Toutes' ||
        _filter != 'Toutes' ||
        _selectedDate != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(Icons.view_kanban_rounded, color: _red, size: 42),
          const SizedBox(height: 12),
          Text(
            hasFilters ? 'Aucun résultat' : 'Aucune tâche pour le moment',
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Essayez de modifier la recherche ou les filtres.'
                : 'Les tâches de votre équipe apparaîtront ici.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _statusFilter = 'Toutes';
                  _filter = 'Toutes';
                  _selectedDate = null;
                });
                _loadTasks();
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STYLE DES CHAMPS
  // ------------------------------------------------------------

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
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
  }

  // ------------------------------------------------------------
  // UTILITAIRES
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }
}
