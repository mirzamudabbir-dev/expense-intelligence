import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/primary_button.dart';

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

const _slides = [
  _SlideData(
    icon: LucideIcons.zap,
    title: 'Track instantly',
    subtitle: 'Add expenses in under 5 seconds.',
  ),
  _SlideData(
    icon: LucideIcons.barChart2,
    title: 'See your patterns',
    subtitle: 'Beautiful charts that make sense of your spending.',
  ),
  _SlideData(
    icon: LucideIcons.target,
    title: 'Stay on budget',
    subtitle: 'Set limits. Know where you stand.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go('/auth');
  }

  void _nextOrFinish() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top 60% — icon area driven by PageView
            Expanded(
              flex: 6,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => Center(
                  child: Icon(
                    _slides[i].icon,
                    size: 96,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
            // Bottom 40% — text + dots + buttons
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.pageMargin,
                  0,
                  AppConstants.pageMargin,
                  AppConstants.pageMargin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(slide.title, style: AppTextStyles.heading1),
                    const SizedBox(height: 8),
                    Text(
                      slide.subtitle,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.accent
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _page == _slides.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      onPressed: _nextOrFinish,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _finish,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
