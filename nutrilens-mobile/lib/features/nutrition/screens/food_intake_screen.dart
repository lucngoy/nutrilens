import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/services/notification_service.dart';
import '../models/food_intake_model.dart';
import '../providers/food_intake_provider.dart';

class FoodIntakeScreen extends ConsumerStatefulWidget {
  const FoodIntakeScreen({super.key});

  @override
  ConsumerState<FoodIntakeScreen> createState() => _FoodIntakeScreenState();
}

class _FoodIntakeScreenState extends ConsumerState<FoodIntakeScreen> {
  static const _primary = Color(0xFFEC6F2D);
  DateTime _selectedDate = DateTime.now();
  final _listScrollController = ScrollController();

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(foodIntakeProvider.notifier).fetchToday(date: _dateKey),
      ref.read(dailySummaryProvider.notifier).fetch(date: _dateKey),
    ]);
  }

  void _goToDate(int offset) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: offset)));
    _loadData();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Food Intake',
            style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/weekly-report'),
            icon: const Icon(Icons.bar_chart, size: 16, color: Color(0xFFEC6F2D)),
            label: const Text('Weekly',
                style: TextStyle(color: Color(0xFFEC6F2D), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: _showLogSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _DateBar(
            date: _selectedDate,
            isToday: _isToday,
            onPrev: () => _goToDate(-1),
            onNext: _isToday ? null : () => _goToDate(1),
          ),
          _SummaryCard(dateKey: _dateKey),
          _AdherenceBanner(onReview: _scrollToList),
          Expanded(child: _IntakeList(
            onDelete: _onDelete,
            onEdit: _showEditSheet,
            scrollController: _listScrollController,
          )),
        ],
      ),
    );
  }

  void _scrollToList() {
    if (_listScrollController.hasClients) {
      _listScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onDelete(int id) async {
    await ref.read(foodIntakeProvider.notifier).deleteIntake(id);
    ref.read(dailySummaryProvider.notifier).fetch(date: _dateKey);
  }

  Future<void> _afterLog() async {
    await Future.wait([
      ref.read(foodIntakeProvider.notifier).fetchToday(date: _dateKey),
      ref.read(dailySummaryProvider.notifier).fetch(date: _dateKey),
    ]);
    ref.read(dailySummaryProvider).whenData((summary) {
      if (summary != null) NotificationService.checkIntakeAdherence(summary);
    });
  }

  void _showLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogIntakeSheet(
        selectedDate: _selectedDate,
        onSaved: _afterLog,
      ),
    );
  }

  void _showEditSheet(FoodIntake intake) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogIntakeSheet(
        existing: intake,
        onSaved: () {
          ref.read(dailySummaryProvider.notifier).fetch(date: _dateKey);
        },
      ),
    );
  }
}

// ── Date navigation bar ───────────────────────────────────────────────────────

class _DateBar extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _DateBar({
    required this.date,
    required this.isToday,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final month = months[date.month - 1];
    final day = date.day;
    final weekday = days[date.weekday - 1];
    final label = isToday ? 'Today — $month $day' : '$weekday, $month $day';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            color: const Color(0xFF2D3142),
          ),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2D3142))),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: onNext != null ? const Color(0xFF2D3142) : Colors.grey.shade300),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Daily summary card ────────────────────────────────────────────────────────

class _SummaryCard extends ConsumerWidget {
  final String dateKey;
  const _SummaryCard({required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dailySummaryProvider);
    return summaryState.when(
      loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(color: Color(0xFFEC6F2D)))),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();
        final target = summary.calorieTarget;
        final pct = (target != null && target > 0)
            ? (summary.totalCalories / target).clamp(0.0, 1.0)
            : 0.0;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${summary.totalCalories.toInt()} kcal',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                      Text(
                          target != null
                              ? 'of ${target.toInt()} kcal target'
                              : '${summary.entryCount} entries',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  if (summary.adherencePct != null)
                    _AdherenceRing(pct: pct, label: '${summary.adherencePct!.toInt()}%'),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              if (summary.remainingCalories != null)
                Text(
                  summary.remainingCalories! > 0
                      ? '${summary.remainingCalories!.toInt()} kcal remaining today'
                      : 'Daily target reached',
                  style: TextStyle(
                      color: summary.remainingCalories! > 0
                          ? Colors.white70
                          : Colors.greenAccent.shade100,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MacroChip('P', '${summary.totalProtein.toInt()}g', summary.proteinTarget, summary.proteinAdherencePct),
                  _MacroChip('C', '${summary.totalCarbs.toInt()}g', summary.carbsTarget, summary.carbsAdherencePct),
                  _MacroChip('F', '${summary.totalFat.toInt()}g', summary.fatTarget, summary.fatAdherencePct),
                  _MacroChip('S', '${summary.totalSugar.toInt()}g', null, null),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdherenceRing extends StatelessWidget {
  final double pct;
  final String label;
  const _AdherenceRing({required this.pct, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: 5,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String letter;
  final String value;
  final double? target;
  final double? adherencePct;
  const _MacroChip(this.letter, this.value, this.target, this.adherencePct);

  Color get _statusColor {
    if (adherencePct == null) return Colors.white70;
    if (adherencePct! > 110) return Colors.orangeAccent;
    if (adherencePct! >= 80) return Colors.greenAccent;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(letter,
            style: TextStyle(
                color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        if (target != null)
          Text('/ ${target!.toInt()}g',
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
        if (adherencePct != null)
          Text('${adherencePct!.toInt()}%',
              style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Adherence banner ─────────────────────────────────────────────────────────

String? _bannerMessage(DailySummary summary) {
  if (summary.adherencePct != null && summary.adherencePct! > 110) {
    return 'Calorie target exceeded — Review your intake';
  }
  if (summary.proteinAdherencePct != null && summary.proteinAdherencePct! > 110) {
    return 'Protein target exceeded — Review your intake';
  }
  if (summary.carbsAdherencePct != null && summary.carbsAdherencePct! > 110) {
    return 'Carbs target exceeded — Review your intake';
  }
  if (summary.fatAdherencePct != null && summary.fatAdherencePct! > 110) {
    return 'Fat target exceeded — Review your intake';
  }
  if (summary.remainingCalories != null &&
      summary.remainingCalories! > 0 &&
      summary.remainingCalories! <= 200) {
    return 'Almost at your limit — ${summary.remainingCalories!.toInt()} kcal remaining';
  }
  return null;
}

class _AdherenceBanner extends ConsumerWidget {
  final VoidCallback onReview;
  const _AdherenceBanner({required this.onReview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dailySummaryProvider);
    return summaryState.maybeWhen(
      data: (summary) {
        if (summary == null || summary.status == 'on_track') return const SizedBox.shrink();
        final message = _bannerMessage(summary);
        if (message == null) return const SizedBox.shrink();
        final isExceeded = summary.status == 'exceeded';
        final color = isExceeded ? Colors.red.shade700 : Colors.orange.shade800;
        final bgColor = isExceeded ? Colors.red.shade50 : Colors.orange.shade50;
        final borderColor = isExceeded ? Colors.red.shade200 : Colors.orange.shade200;
        return GestureDetector(
          onTap: onReview,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  isExceeded ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                        color: color, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right, color: color, size: 18),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── Intake list ───────────────────────────────────────────────────────────────

class _IntakeList extends ConsumerWidget {
  final Future<void> Function(int id) onDelete;
  final void Function(FoodIntake) onEdit;
  final ScrollController? scrollController;
  const _IntakeList({required this.onDelete, required this.onEdit, this.scrollController});

  static const _mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
  static const _mealLabels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
  };
  static const _mealIcons = {
    'breakfast': Icons.wb_sunny_outlined,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
    'snack': Icons.cookie_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodIntakeProvider);
    return state.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Color(0xFFEC6F2D))),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (intakes) {
        if (intakes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('No entries yet',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                SizedBox(height: 4),
                Text('Tap + to log your first meal',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        // Group by meal_type
        final grouped = <String, List<FoodIntake>>{};
        for (final i in intakes) {
          grouped.putIfAbsent(i.mealType, () => []).add(i);
        }

        final sections = _mealOrder.where((m) => grouped.containsKey(m)).toList();

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: sections.length,
          itemBuilder: (ctx, si) {
            final meal = sections[si];
            final items = grouped[meal]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(_mealIcons[meal], size: 16, color: const Color(0xFFEC6F2D)),
                      const SizedBox(width: 6),
                      Text(_mealLabels[meal] ?? meal,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF2D3142))),
                      const SizedBox(width: 8),
                      Text(
                          '${items.fold(0.0, (s, i) => s + i.calories).toInt()} kcal',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                ...items.map((intake) => _IntakeTile(intake: intake, onDelete: onDelete, onEdit: onEdit)),
              ],
            );
          },
        );
      },
    );
  }
}

class _IntakeTile extends StatelessWidget {
  final FoodIntake intake;
  final Future<void> Function(int) onDelete;
  final void Function(FoodIntake) onEdit;
  const _IntakeTile({required this.intake, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('intake_${intake.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => AppDialogs.warning(
        context,
        title: 'Delete entry?',
        message: 'Remove "${intake.name}" from your log?',
        confirmLabel: 'Delete',
      ),
      onDismissed: (_) => onDelete(intake.id),
      child: InkWell(
        onTap: () => onEdit(intake),
        borderRadius: BorderRadius.circular(14),
        child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            if (intake.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  intake.imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              )
            else
              _placeholder(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(intake.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF2D3142))),
                  const SizedBox(height: 2),
                  Text(
                      intake.unitLabel.isNotEmpty
                          ? '${intake.quantity.toInt()} ${intake.unitLabel}'
                          : '${intake.quantity.toInt()}${intake.unit}'
                      '${intake.protein != null ? ' · ${intake.protein!.toInt()}g P' : ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text('${intake.calories.toInt()} kcal',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFFEC6F2D))),
          ],
        ),
      ),
    ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood_outlined, color: Colors.grey, size: 20),
    );
  }
}

// ── Log intake bottom sheet ───────────────────────────────────────────────────

class _LogIntakeSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final FoodIntake? existing;
  final DateTime? selectedDate;
  const _LogIntakeSheet({required this.onSaved, this.existing, this.selectedDate});

  @override
  State<_LogIntakeSheet> createState() => _LogIntakeSheetState();
}

class _LogIntakeSheetState extends State<_LogIntakeSheet> {
  static const _primary = Color(0xFFEC6F2D);

  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitLabelCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  late String _mealType;
  late String _unit;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _mealType = e?.mealType ?? 'snack';
    _unit = e?.unit ?? 'g';
    if (e != null) {
      _nameCtrl.text = e.name;
      _calCtrl.text = e.calories.toString();
      _qtyCtrl.text = e.quantity.toString();
      if (e.unitLabel.isNotEmpty) _unitLabelCtrl.text = e.unitLabel;
      if (e.protein != null) _proteinCtrl.text = e.protein!.toString();
      if (e.carbs != null) _carbsCtrl.text = e.carbs!.toString();
      if (e.fat != null) _fatCtrl.text = e.fat!.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _qtyCtrl.dispose();
    _unitLabelCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(WidgetRef ref) async {
    final name = _nameCtrl.text.trim();
    final cal = double.tryParse(_calCtrl.text);
    final qty = double.tryParse(_qtyCtrl.text);

    if (name.isEmpty || cal == null || qty == null) {
      setState(() => _error = 'Name, calories and quantity are required.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final data = {
        'name': name,
        'calories': cal,
        'quantity': qty,
        'unit': _unit,
        if (_unitLabelCtrl.text.isNotEmpty) 'unit_label': _unitLabelCtrl.text.trim(),
        'meal_type': _mealType,
        'source_type': 'manual',
        if (_proteinCtrl.text.isNotEmpty) 'protein': double.tryParse(_proteinCtrl.text),
        if (_carbsCtrl.text.isNotEmpty) 'carbs': double.tryParse(_carbsCtrl.text),
        if (_fatCtrl.text.isNotEmpty) 'fat': double.tryParse(_fatCtrl.text),
      };

      if (_isEdit) {
        await ref.read(foodIntakeProvider.notifier).updateIntake(widget.existing!.id, data);
      } else {
        final now = DateTime.now();
        final date = widget.selectedDate ?? now;
        final consumedAt = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
        data['consumed_at'] = consumedAt.toIso8601String();
        await ref.read(foodIntakeProvider.notifier).logIntake(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isEdit ? 'Edit Entry' : 'Log Food',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3142))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Meal type selector
              Row(
                children: ['breakfast', 'lunch', 'dinner', 'snack'].map((m) {
                  final isSelected = _mealType == m;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mealType = m),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          m[0].toUpperCase() + m.substring(1, 2),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _Field(controller: _nameCtrl, label: 'Food name *', hint: 'e.g. Chicken breast'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Field(controller: _calCtrl, label: 'Calories *', hint: '250', numeric: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _Field(controller: _qtyCtrl, label: 'Qty *', hint: '100', numeric: true)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _unit,
                          underline: const SizedBox.shrink(),
                          items: ['g', 'ml', 'unit'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (v) => setState(() => _unit = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_unit == 'unit') ...[
                const SizedBox(height: 8),
                _Field(controller: _unitLabelCtrl, label: 'Unit name (optional)', hint: 'banana, slice, cup...'),
              ],
              const SizedBox(height: 12),
              const Text('Macros (optional)',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _Field(controller: _proteinCtrl, label: 'Protein g', hint: '0', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _Field(controller: _carbsCtrl, label: 'Carbs g', hint: '0', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _Field(controller: _fatCtrl, label: 'Fat g', hint: '0', numeric: true)),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : () => _save(ref),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEdit ? 'Save Changes' : 'Log Food',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool numeric;
  const _Field({required this.controller, required this.label, required this.hint, this.numeric = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFEC6F2D))),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}
