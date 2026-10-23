import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/financial_service.dart';
import '../widgets/obligations_model.dart';

class DettesCreancesPage extends StatefulWidget {
  final String businessId;

  const DettesCreancesPage({super.key, required this.businessId});

  @override
  State<DettesCreancesPage> createState() => _DettesCreancesPageState();
}

class _DettesCreancesPageState extends State<DettesCreancesPage> {
  final FinancialService _service = FinancialService();
  final TextEditingController _searchController = TextEditingController();

  List<FinancialObligationModel> _items = [];
  bool _loading = true;
  String _filter = 'all';
  String _statusFilter = 'all';
  String _search = '';
  String? _error;

  static const _red = Color(0xFFF21D3D);
  static const _navy = Color(0xFF14264B);
  static const _muted = Color(0xFF7B8498);
  static const _border = Color(0xFFE9ECF3);
  static const _background = Color(0xFFF7F8FC);

  final NumberFormat _money = NumberFormat('#,##0.000', 'fr_FR');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final rows = await _service.getObligations(
        businessId: widget.businessId,
        type: _filter == 'all' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString();
    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Accès refusé. Vérifiez vos autorisations pour cette entreprise.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  List<FinancialObligationModel> get _visibleItems {
    final q = _search.trim().toLowerCase();
    return _items.where((item) {
      final matchesSearch =
          q.isEmpty ||
          item.thirdPartyName.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          (item.reference ?? '').toLowerCase().contains(q);
      final matchesStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'overdue' && item.isOverdue) ||
          (_statusFilter == 'settled' && item.isSettled) ||
          (_statusFilter == 'pending' && !item.isSettled && !item.isOverdue);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  double _total(String type) => _items
      .where((e) => e.type == type)
      .fold(0, (sum, e) => sum + e.remainingAmount);

  double get _totalPaid => _items.fold(0, (sum, e) => sum + e.paidAmount);

  int get _overdueCount => _items.where((e) => e.isOverdue).length;

  String _formatMoney(double value) => '${_money.format(value)} DT';

  String _formatDate(DateTime? date) =>
      date == null ? 'Non définie' : _dateFormat.format(date);

  Future<void> _create() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ObligationDialog(businessId: widget.businessId, service: _service),
    );
    if (result == true) await _load();
  }

  Future<void> _registerPayment(FinancialObligationModel item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentDialog(item: item, service: _service),
    );
    if (result == true) await _load();
  }

  Future<void> _showDetails(FinancialObligationModel item) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DetailsDialog(
        item: item,
        service: _service,
        formatMoney: _formatMoney,
        formatDate: _formatDate,
        onPayment: () async {
          if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
          await _registerPayment(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSummary(),
            const SizedBox(height: 22),
            _buildFilters(),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildError()
            else if (_visibleItems.isEmpty)
              _buildEmpty()
            else
              ..._visibleItems.map(_buildObligationCard),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dettes et créances',
              style: TextStyle(
                color: _navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Suivez les montants à recevoir et à payer.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        );
        final button = FilledButton.icon(
          onPressed: _create,
          style: FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouvelle opération'),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: button),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            button,
          ],
        );
      },
    );
  }

  Widget _buildSummary() {
    final cards = [
      _SummaryData(
        'Créances restantes',
        _total('receivable'),
        Icons.call_received_rounded,
        const Color(0xFFB7791F),
      ),
      _SummaryData(
        'Dettes restantes',
        _total('payable'),
        Icons.call_made_rounded,
        _red,
      ),
      _SummaryData(
        'Total déjà réglé',
        _totalPaid,
        Icons.check_circle_outline_rounded,
        const Color(0xFF16845B),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 560
            ? 1
            : (constraints.maxWidth < 950 ? 2 : 3);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) {
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: card.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(card.icon, color: card.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _formatMoney(card.value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Rechercher un tiers, un motif, une référence...',
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
              filled: true,
              fillColor: _background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tout', 'all'),
                const SizedBox(width: 8),
                _filterChip('Créances', 'receivable'),
                const SizedBox(width: 8),
                _filterChip('Dettes', 'payable'),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => setState(() => _statusFilter = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'all',
                      child: Text('Tous les statuts'),
                    ),
                    PopupMenuItem(value: 'pending', child: Text('En attente')),
                    PopupMenuItem(value: 'overdue', child: Text('En retard')),
                    PopupMenuItem(value: 'settled', child: Text('Réglées')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list_rounded,
                          size: 17,
                          color: _navy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel,
                          style: const TextStyle(fontSize: 12, color: _navy),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _statusLabel => switch (_statusFilter) {
    'pending' => 'En attente',
    'overdue' => 'En retard',
    'settled' => 'Réglées',
    _ => 'Tous les statuts',
  };

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = value;
          _loading = true;
        });
        _load();
      },
      selectedColor: const Color(0xFFFFE4E9),
      labelStyle: TextStyle(
        color: selected ? _red : _muted,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(color: selected ? const Color(0xFFFFC5D0) : _border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    );
  }

  Widget _buildObligationCard(FinancialObligationModel item) {
    final receivable = item.type == 'receivable';
    final accent = receivable ? const Color(0xFFB7791F) : _red;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final main = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  receivable
                      ? Icons.call_received_rounded
                      : Icons.call_made_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.thirdPartyName,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _statusBadge(item),
                        _smallTag(receivable ? 'Créance' : 'Dette', accent),
                        if (item.dueDate != null)
                          _smallTag(
                            'Échéance ${_formatDate(item.dueDate)}',
                            _muted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final amounts = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(item.remainingAmount),
                style: const TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'sur ${_formatMoney(item.initialAmount)}',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _showDetails(item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text('Détails'),
              ),
              if (!item.isSettled)
                FilledButton(
                  onPressed: () => _registerPayment(item),
                  style: FilledButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text('Règlement'),
                ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                main,
                const SizedBox(height: 14),
                amounts,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: main),
              const SizedBox(width: 16),
              amounts,
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _statusBadge(FinancialObligationModel item) {
    final color = item.isSettled
        ? const Color(0xFF16845B)
        : item.isOverdue
        ? _red
        : item.paidAmount > 0
        ? const Color(0xFFB7791F)
        : _muted;
    return _smallTag(item.status, color);
  }

  Widget _smallTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );

  Widget _buildEmpty() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          size: 46,
          color: _muted,
        ),
        const SizedBox(height: 12),
        Text(
          _search.isNotEmpty ? 'Aucun résultat' : 'Aucune dette ou créance',
          style: const TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _search.isNotEmpty
              ? 'Essayez une autre recherche ou modifiez les filtres.'
              : 'Ajoutez manuellement une dette ou une créance pour commencer.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        if (_search.isEmpty) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _create,
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter une opération'),
          ),
        ],
      ],
    ),
  );

  Widget _buildError() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        const Icon(Icons.error_outline_rounded, color: _red, size: 34),
        const SizedBox(height: 8),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _navy),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Réessayer'),
        ),
      ],
    ),
  );
}

class _SummaryData {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  const _SummaryData(this.title, this.value, this.icon, this.color);
}

class _ObligationDialog extends StatefulWidget {
  final String businessId;
  final FinancialService service;
  const _ObligationDialog({required this.businessId, required this.service});

  @override
  State<_ObligationDialog> createState() => _ObligationDialogState();
}

class _ObligationDialogState extends State<_ObligationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();
  final _reference = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'receivable';
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _description.dispose();
    _reference.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool due}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: due ? (_dueDate ?? _date) : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: due ? 'Choisir l’échéance' : 'Date de l’opération',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (due) {
        _dueDate = picked;
      } else {
        _date = picked;
        if (_dueDate != null && _dueDate!.isBefore(_date)) _dueDate = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final parsed = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      setState(() => _error = 'Saisissez un montant valide et positif.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.createObligation(
        businessId: widget.businessId,
        type: _type,
        thirdPartyName: _name.text,
        thirdPartyPhone: _phone.text,
        description: _description.text,
        reference: _reference.text,
        amount: parsed,
        obligationDate: _date,
        dueDate: _dueDate,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _saving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle dette ou créance'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'receivable',
                      child: Text('Créance — on doit me payer'),
                    ),
                    DropdownMenuItem(
                      value: 'payable',
                      child: Text('Dette — je dois payer'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _type = v);
                        },
                ),
                const SizedBox(height: 10),
                _field(_name, 'Nom du tiers *', required: true),
                _field(
                  _phone,
                  'Téléphone (facultatif)',
                  keyboard: TextInputType.phone,
                ),
                _field(_description, 'Motif / description *', required: true),
                _field(
                  _amount,
                  'Montant initial *',
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _field(_reference, 'Référence (facultatif)'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _pickDate(due: false),
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 17,
                        ),
                        label: Text(
                          'Date : ${DateFormat('dd/MM/yyyy').format(_date)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _pickDate(due: true),
                        icon: const Icon(Icons.event_outlined, size: 17),
                        label: Text(
                          _dueDate == null
                              ? 'Définir échéance'
                              : 'Échéance : ${DateFormat('dd/MM/yyyy').format(_dueDate!)}',
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        tooltip: 'Retirer l’échéance',
                        onPressed: _saving
                            ? null
                            : () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                _field(_notes, 'Notes (facultatif)', maxLines: 3),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
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
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF21D3D),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Ce champ est obligatoire.'
                : null
          : null,
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  final FinancialObligationModel item;
  final FinancialService service;
  const _PaymentDialog({required this.item, required this.service});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  String _method = 'cash';
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount <= 0) {
      setState(() => _error = 'Montant invalide.');
      return;
    }
    if (amount - widget.item.remainingAmount > 0.0005) {
      setState(() => _error = 'Le montant dépasse le solde restant.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.registerPayment(
        obligationId: widget.item.id,
        businessId: widget.item.businessId,
        amount: amount,
        paymentDate: _date,
        paymentMethod: _method,
        reference: _reference.text,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _saving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Enregistrer un règlement'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Solde restant : ${NumberFormat('#,##0.000', 'fr_FR').format(widget.item.remainingAmount)} DT',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Montant du règlement *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Montant obligatoire.';
                  final n = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (n == null || !n.isFinite || n <= 0)
                    return 'Montant invalide.';
                  if (n - widget.item.remainingAmount > 0.0005)
                    return 'Supérieur au solde restant.';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('Virement bancaire'),
                  ),
                  DropdownMenuItem(value: 'card', child: Text('Carte')),
                  DropdownMenuItem(
                    value: 'mobile_money',
                    child: Text('Mobile Money'),
                  ),
                  DropdownMenuItem(value: 'check', child: Text('Chèque')),
                  DropdownMenuItem(value: 'other', child: Text('Autre')),
                ],
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v != null) setState(() => _method = v);
                      },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null && mounted)
                          setState(() => _date = picked);
                      },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Date : ${DateFormat('dd/MM/yyyy').format(_date)}'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Référence (facultatif)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (facultatif)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
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
      FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF21D3D)),
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Confirmer le règlement'),
      ),
    ],
  );
}

class _DetailsDialog extends StatefulWidget {
  final FinancialObligationModel item;
  final FinancialService service;
  final String Function(double) formatMoney;
  final String Function(DateTime?) formatDate;
  final Future<void> Function() onPayment;

  const _DetailsDialog({
    required this.item,
    required this.service,
    required this.formatMoney,
    required this.formatDate,
    required this.onPayment,
  });

  @override
  State<_DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends State<_DetailsDialog> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.getPayments(
      obligationId: widget.item.id,
      businessId: widget.item.businessId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AlertDialog(
      title: const Text('Détail de l’opération'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.thirdPartyName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(item.description),
              const Divider(height: 24),
              _detailLine(
                'Type',
                item.type == 'receivable' ? 'Créance' : 'Dette',
              ),
              _detailLine('Statut', item.status),
              _detailLine(
                'Montant initial',
                widget.formatMoney(item.initialAmount),
              ),
              _detailLine('Déjà réglé', widget.formatMoney(item.paidAmount)),
              _detailLine(
                'Solde restant',
                widget.formatMoney(item.remainingAmount),
              ),
              _detailLine('Date', widget.formatDate(item.obligationDate)),
              _detailLine('Échéance', widget.formatDate(item.dueDate)),
              if (item.thirdPartyPhone != null)
                _detailLine('Téléphone', item.thirdPartyPhone!),
              if (item.reference != null)
                _detailLine('Référence', item.reference!),
              if (item.notes != null) _detailLine('Notes', item.notes!),
              const Divider(height: 24),
              const Text(
                'Historique des règlements',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Impossible de charger les règlements : ${snapshot.error}',
                    );
                  }
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty)
                    return const Text(
                      'Aucun règlement enregistré.',
                      style: TextStyle(color: Colors.grey),
                    );
                  return Column(
                    children: rows.map((row) {
                      final date = DateTime.tryParse(
                        row['payment_date'].toString(),
                      );
                      final amount =
                          double.tryParse(row['amount'].toString()) ?? 0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF16845B),
                        ),
                        title: Text(
                          widget.formatMoney(amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${widget.formatDate(date)} • ${_methodLabel(row['payment_method']?.toString() ?? 'other')}',
                        ),
                        dense: true,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        if (!item.isSettled)
          FilledButton(
            onPressed: widget.onPayment,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF21D3D),
            ),
            child: const Text('Ajouter un règlement'),
          ),
      ],
    );
  }

  Widget _detailLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  String _methodLabel(String method) => switch (method) {
    'cash' => 'Espèces',
    'bank_transfer' => 'Virement bancaire',
    'card' => 'Carte',
    'mobile_money' => 'Mobile Money',
    'check' => 'Chèque',
    _ => 'Autre',
  };
}
