import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/budget/providers/budget_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/widgets/app_card.dart';

final _packageInfoProvider =
    FutureProvider<PackageInfo>((_) => PackageInfo.fromPlatform());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = supabase.auth.currentUser;
    final budgetAsync = ref.watch(budgetNotifierProvider);
    final packageInfo = ref.watch(_packageInfoProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppConstants.pageMargin,
            20,
            AppConstants.pageMargin,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          children: [
            Text('Settings', style: AppTextStyles.heading1),
            const SizedBox(height: 24),

            // ── Group 1: Account ──────────────────────────────────────────
            AppCard(
              padding: EdgeInsets.zero,
              child: _SettingsRow(
                icon: Icons.person_outline,
                title: 'Account',
                subtitle: user?.email,
              ),
            ),
            const SizedBox(height: 12),

            // ── Group 2: Preferences ──────────────────────────────────────
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SettingsRow(
                    icon: Icons.track_changes_rounded,
                    title: 'Monthly Budget',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        budgetAsync.whenOrNull(
                              data: (b) => b != null
                                  ? Text(
                                      CurrencyFormatter.compact(b.monthlyLimit),
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary),
                                    )
                                  : null,
                            ) ??
                            const SizedBox.shrink(),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.textTertiary),
                      ],
                    ),
                    onTap: () => context.push('/budget'),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: AppColors.border, indent: 48),
                  const _SettingsRow(
                    icon: Icons.currency_rupee,
                    title: 'Currency',
                    trailing: Text('₹ INR'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Group 3: App ──────────────────────────────────────────────
            AppCard(
              padding: EdgeInsets.zero,
              child: _SettingsRow(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                  activeThumbColor: AppColors.accent,
                  trackColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? AppColors.accentMuted
                          : AppColors.bgElevated),
                  thumbColor:
                      const WidgetStatePropertyAll(AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Group 4: About ────────────────────────────────────────────
            AppCard(
              padding: EdgeInsets.zero,
              child: _SettingsRow(
                icon: Icons.info_outline,
                title: 'Version',
                trailing: Text(
                  packageInfo.whenOrNull(data: (p) => p.version) ?? '—',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Sign out ──────────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => _confirmSignOut(context, ref),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                  ),
                ),
                child: Text(
                  'Sign Out',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Sign out?', style: AppTextStyles.heading2),
        content: Text(
          "You'll be returned to the login screen.",
          style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(
              'Sign Out',
              style: AppTextStyles.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable row ──────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              DefaultTextStyle(
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        splashColor: AppColors.bgElevated,
        highlightColor: AppColors.bgElevated.withAlpha(128),
        child: content,
      ),
    );
  }
}
