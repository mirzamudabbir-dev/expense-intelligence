import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../expenses/providers/home_providers.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetNotifierProvider);
    final monthlySpent = ref.watch(monthlyTotalProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _Header(),
              const SizedBox(height: 24),
              budgetAsync.when(
                loading: () => const _RingCardSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data: (budget) => _BudgetRingCard(
                  budget: budget,
                  spent: monthlySpent,
                  onEdit: () => _showSetBudgetSheet(
                    context,
                    ref,
                    current: budget?.monthlyLimit,
                  ),
                  onSetBudget: () => _showSetBudgetSheet(context, ref),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.05, duration: 600.ms, curve: Curves.easeOutQuart),
      ),
    );
  }

  void _showSetBudgetSheet(
    BuildContext context,
    WidgetRef ref, {
    double? current,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetBudgetSheet(current: current, ref: ref),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('Budget', style: AppTextStyles.heading2),
      ],
    );
  }
}

// ── Ring card ─────────────────────────────────────────────────────────────────

class _BudgetRingCard extends StatelessWidget {
  const _BudgetRingCard({
    required this.budget,
    required this.spent,
    required this.onEdit,
    required this.onSetBudget,
  });

  final Budget? budget;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onSetBudget;

  @override
  Widget build(BuildContext context) {
    if (budget == null) {
      return _EmptyBudgetCard(onSetBudget: onSetBudget);
    }
    return _FilledRingCard(
      spent: spent,
      limit: budget!.monthlyLimit,
      onEdit: onEdit,
    );
  }
}

class _EmptyBudgetCard extends StatelessWidget {
  const _EmptyBudgetCard({required this.onSetBudget});
  final VoidCallback onSetBudget;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.track_changes_rounded,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No budget set',
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Set Budget', onPressed: onSetBudget),
        ],
      ),
    );
  }
}

class _FilledRingCard extends StatefulWidget {
  const _FilledRingCard({
    required this.spent,
    required this.limit,
    required this.onEdit,
  });

  final double spent;
  final double limit;
  final VoidCallback onEdit;

  @override
  State<_FilledRingCard> createState() => _FilledRingCardState();
}

class _FilledRingCardState extends State<_FilledRingCard> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animate = true);
    });
  }

  Color get _statusColor {
    final fraction = widget.limit > 0 ? widget.spent / widget.limit : 0.0;
    if (fraction >= 1.0) return AppColors.error;
    if (fraction >= 0.8) return AppColors.warning;
    return AppColors.accent;
  }

  List<PieChartSectionData> get _sections {
    final fraction =
        widget.limit > 0 ? (widget.spent / widget.limit).clamp(0.0, 1.0) : 0.0;
    final spentVal = _animate ? fraction * 100 : 0.001;
    final remainVal = _animate ? (1.0 - fraction) * 100 : 99.999;

    return [
      PieChartSectionData(
        value: spentVal,
        color: _statusColor,
        radius: 12,
        title: '',
      ),
      PieChartSectionData(
        value: remainVal,
        color: AppColors.bgElevated,
        radius: 12,
        title: '',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fraction =
        widget.limit > 0 ? (widget.spent / widget.limit).clamp(0.0, 1.0) : 0.0;
    final remaining = (widget.limit - widget.spent).clamp(0.0, widget.limit);
    final pct = (fraction * 100).round();

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 68,
                        startDegreeOffset: -90,
                        sections: _sections,
                      ),
                      swapAnimationDuration:
                          const Duration(milliseconds: 700),
                      swapAnimationCurve: Curves.easeOutQuart,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.compact(remaining),
                        style: GoogleFonts.robotoMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text('remaining', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${CurrencyFormatter.compact(widget.spent)} spent of ${CurrencyFormatter.compact(widget.limit)}',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '$pct% used',
                style: AppTextStyles.label.copyWith(color: _statusColor),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: widget.onEdit,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Set / edit sheet ──────────────────────────────────────────────────────────

class _SetBudgetSheet extends StatefulWidget {
  const _SetBudgetSheet({this.current, required this.ref});

  final double? current;
  final WidgetRef ref;

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.current != null
          ? widget.current!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_ctrl.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      await widget.ref
          .read(budgetNotifierProvider.notifier)
          .upsertBudget(amount);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
          ),
          const SizedBox(height: 24),
          Text('Set Monthly Budget', style: AppTextStyles.heading2),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Monthly limit',
              style:
                  AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '₹',
                  style: GoogleFonts.robotoMono(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: GoogleFonts.robotoMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                    ),
                    autofocus: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save Budget',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _RingCardSkeleton extends StatelessWidget {
  const _RingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
