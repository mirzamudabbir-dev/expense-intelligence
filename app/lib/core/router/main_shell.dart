import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _BottomNav(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.home, 'Home'),
      (LucideIcons.barChart2, 'Analytics'),
      (LucideIcons.settings, 'Settings'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final (icon, label) = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: Semantics(
                  label: label,
                  button: true,
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      icon,
                      size: 20,
                      color: isActive ? AppColors.accent : AppColors.textTertiary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
