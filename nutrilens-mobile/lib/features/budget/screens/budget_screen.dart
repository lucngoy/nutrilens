import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/budget_model.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/providers/currency_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  static const primaryColor = Color(0xFFEC6F2D);

  NumberFormat _fmt(String symbol) =>
      NumberFormat.currency(symbol: symbol, decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(budgetProvider.notifier).fetch();
      final budget = ref.read(budgetProvider).valueOrNull;
      if (budget != null) await NotificationService.checkBudgetPace(budget);
    });
  }

  String get _currentMonth => DateFormat('yyyy-MM').format(DateTime.now());
  String get _monthLabel => DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetProvider);
    final currencySymbol = ref.watch(currencyProvider.notifier).symbol;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          _buildHeader(context, state.valueOrNull),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
              error: (e, _) => _buildError(e.toString()),
              data: (budget) => budget == null
                  ? _buildSetupView(currencySymbol)
                  : _buildDashboard(budget, currencySymbol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MonthlyBudget? budget) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 16, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, color: primaryColor, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Grocery Budget',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
          ),
          if (budget != null)
            GestureDetector(
              onTap: () => _showEditBudgetSheet(budget),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, color: primaryColor, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(msg, style: const TextStyle(color: Colors.red)),
        ),
      );

  // ── Setup View ────────────────────────────────────────────────────────────

  Widget _buildSetupView(String currencySymbol) {
    final controller = TextEditingController();
    String selectedCurrency = ref.read(currencyProvider);
    return StatefulBuilder(builder: (context, setSetup) => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: primaryColor, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Set your monthly budget',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Track your grocery spending for $_monthLabel',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 32),
            _BudgetAmountField(controller: controller),
            const SizedBox(height: 16),
            _CurrencyPicker(
              selected: selectedCurrency,
              onChanged: (v) => setSetup(() => selectedCurrency = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(currencyProvider.notifier).setCurrency(selectedCurrency);
                  _submitBudget(controller);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Set Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _submitBudget(TextEditingController controller) async {
    final text = controller.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    try {
      await ref.read(budgetProvider.notifier).setBudget(amount, month: _currentMonth);
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Widget _buildDashboard(MonthlyBudget budget, String currencySymbol) {
    final grouped = _groupByDay(budget.entries);
    final dayKeys = grouped.keys.toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSummaryCard(budget, currencySymbol),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expenses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => _showAddSpendingSheet(budget),
                icon: const Icon(Icons.add, color: primaryColor),
                label: const Text('Add', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (budget.entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black26),
                SizedBox(height: 12),
                Text('No expenses yet', style: TextStyle(color: Colors.black38)),
              ],
            ),
          )
        else
          for (final day in dayKeys) ...[
            _buildDayHeader(day),
            ...grouped[day]!.map((e) => _buildEntryTile(e, currencySymbol: currencySymbol)),
          ],
        const SizedBox(height: 32),
      ],
    );
  }

  Map<String, List<SpendingEntry>> _groupByDay(List<SpendingEntry> entries) {
    final map = <String, List<SpendingEntry>>{};
    for (final e in entries) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  Widget _buildDayHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final parsed = DateTime(date.year, date.month, date.day);

    String label;
    if (parsed == today) {
      label = 'Today';
    } else if (parsed == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black45)),
    );
  }

  Widget _buildSummaryCard(MonthlyBudget budget, String currencySymbol) {
    final fmt = _fmt(currencySymbol);
    final pct = (budget.percentageUsed / 100).clamp(0.0, 1.0);
    final isOver = budget.remaining < 0;
    final barColor = isOver ? Colors.red : (pct > 0.8 ? Colors.orange : primaryColor);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC6F2D), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Budget', style: TextStyle(color: Colors.white70, fontSize: 13)),
              _buildPaceChip(budget.paceStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(fmt.format(budget.amount),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'At this pace: ${fmt.format(budget.projectedSpent)} this month',
            style: TextStyle(
              color: budget.paceStatus == 'on_track' ? Colors.white60 : Colors.white,
              fontSize: 12,
              fontWeight: budget.paceStatus != 'on_track' ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(barColor == primaryColor ? Colors.white : barColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip('Spent', fmt.format(budget.totalSpent)),
              const SizedBox(width: 12),
              _statChip(
                isOver ? 'Over by' : 'Remaining',
                fmt.format(budget.remaining.abs()),
                isWarning: isOver,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaceChip(String status) {
    final (icon, label, color) = switch (status) {
      'exceeded' => (Icons.cancel_outlined, 'Budget exceeded', Colors.red[300]!),
      'warning' => (Icons.warning_amber_rounded, 'Spending too fast', Colors.orange[300]!),
      _ => (Icons.check_circle_outline, 'On track', Colors.green[300]!),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, {bool isWarning = false}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isWarning ? Colors.red.withOpacity(0.2) : Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: isWarning ? Colors.red[200] : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  Widget _buildEntryTile(SpendingEntry entry, {String currencySymbol = r'$'}) {
    final fmt = _fmt(currencySymbol);
    return Dismissible(
      key: Key('entry_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => AppDialogs.warning(
        context,
        title: 'Delete expense?',
        message: 'Remove "${entry.description}" from your expenses?',
        confirmLabel: 'Delete',
      ),
      onDismissed: (_) => ref.read(budgetProvider.notifier).deleteSpending(entry.id),
      child: InkWell(
        onTap: () => _showEditEntrySheet(entry),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _categoryColor(entry.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon(entry.category),
                    color: _categoryColor(entry.category), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.description,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(_categoryLabel(entry.category),
                        style: TextStyle(
                            color: _categoryColor(entry.category),
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(fmt.format(entry.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: primaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category helpers ──────────────────────────────────────────────────────

  IconData _categoryIcon(String cat) => switch (cat) {
        'restaurant' => Icons.restaurant_outlined,
        'snack' => Icons.cookie_outlined,
        'other' => Icons.category_outlined,
        _ => Icons.local_grocery_store_outlined,
      };

  Color _categoryColor(String cat) => switch (cat) {
        'restaurant' => const Color(0xFF9C27B0),
        'snack' => const Color(0xFF2196F3),
        'other' => Colors.grey,
        _ => primaryColor,
      };

  String _categoryLabel(String cat) => switch (cat) {
        'restaurant' => 'Restaurant',
        'snack' => 'Snack',
        'other' => 'Other',
        _ => 'Groceries',
      };

  // ── Sheets ────────────────────────────────────────────────────────────────

  void _showAddSpendingSheet(MonthlyBudget budget) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCategory = 'groceries';
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Add Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                if (error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                TextField(
                  controller: descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Description (e.g. Supermarket)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: _inputDecoration('Amount (\$)'),
                ),
                const SizedBox(height: 12),
                _CategoryPicker(
                  selected: selectedCategory,
                  onChanged: (v) => setSheet(() => selectedCategory = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final desc = descCtrl.text.trim();
                      final amt = double.tryParse(amountCtrl.text.trim().replaceAll(',', '.'));
                      if (desc.isEmpty || amt == null || amt <= 0) {
                        setSheet(() => error = 'Please fill in all fields with valid values.');
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        await ref.read(budgetProvider.notifier).addSpending(
                              description: desc,
                              amount: amt,
                              category: selectedCategory,
                              month: _currentMonth,
                            );
                      } catch (e) {
                        _showError(e.toString());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showEditEntrySheet(SpendingEntry entry) {
    final descCtrl = TextEditingController(text: entry.description);
    final amountCtrl = TextEditingController(text: entry.amount.toStringAsFixed(2));
    String selectedCategory = entry.category;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(entry.description,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                    maxLines: 2,
                    overflow: TextOverflow.visible),
                const SizedBox(height: 16),
                if (error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                TextField(
                  controller: descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: _inputDecoration('Amount (\$)'),
                ),
                const SizedBox(height: 12),
                _CategoryPicker(
                  selected: selectedCategory,
                  onChanged: (v) => setSheet(() => selectedCategory = v),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final confirmed = await AppDialogs.warning(
                            context,
                            title: 'Delete expense?',
                            message: 'Remove "${entry.description}" from your expenses?',
                            confirmLabel: 'Delete',
                          );
                          if (confirmed) {
                            try {
                              await ref.read(budgetProvider.notifier).deleteSpending(entry.id);
                            } catch (e) {
                              _showError(e.toString());
                            }
                          }
                        },
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final desc = descCtrl.text.trim();
                            final amt = double.tryParse(amountCtrl.text.trim().replaceAll(',', '.'));
                            if (desc.isEmpty || amt == null || amt <= 0) {
                              setSheet(() => error = 'Please fill in all fields with valid values.');
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              await ref.read(budgetProvider.notifier).deleteSpending(entry.id);
                              await ref.read(budgetProvider.notifier).addSpending(
                                    description: desc,
                                    amount: amt,
                                    category: selectedCategory,
                                    date: entry.date,
                                    month: _currentMonth,
                                  );
                            } catch (e) {
                              _showError(e.toString());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showEditBudgetSheet(MonthlyBudget budget) {
    final ctrl = TextEditingController(text: budget.amount.toStringAsFixed(2));
    String selectedCurrency = ref.read(currencyProvider);
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Edit Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                if (error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: _inputDecoration('Monthly budget'),
                ),
                const SizedBox(height: 12),
                _CurrencyPicker(
                  selected: selectedCurrency,
                  onChanged: (v) => setSheet(() => selectedCurrency = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amt = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
                      if (amt == null || amt <= 0) {
                        setSheet(() => error = 'Please enter a valid amount.');
                        return;
                      }
                      Navigator.pop(ctx);
                      await ref.read(currencyProvider.notifier).setCurrency(selectedCurrency);
                      try {
                        await ref.read(budgetProvider.notifier).setBudget(amt, month: _currentMonth);
                      } catch (e) {
                        _showError(e.toString());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}

// ── Category Picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({required this.selected, required this.onChanged});

  static const _categories = [
    ('groceries', 'Groceries', Icons.local_grocery_store_outlined),
    ('restaurant', 'Restaurant', Icons.restaurant_outlined),
    ('snack', 'Snack', Icons.cookie_outlined),
    ('other', 'Other', Icons.category_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _categories.map((cat) {
        final (value, label, icon) = cat;
        final isSelected = selected == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEC6F2D) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black45),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black45)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CurrencyPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Currency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kCurrencies.map((c) {
            final (code, symbol, name) = c;
            final isSelected = selected == code;
            return GestureDetector(
              onTap: () => onChanged(code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEC6F2D) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? null : Border.all(color: Colors.black12),
                ),
                child: Text(
                  '$symbol  $code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BudgetAmountField extends StatelessWidget {
  final TextEditingController controller;
  const _BudgetAmountField({required this.controller});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          prefixText: '\$ ',
          prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFEC6F2D)),
          hintText: '0.00',
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 28),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      );
}
