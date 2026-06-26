import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    // Router redirect handles logged-in users hitting /auth → /home automatically
    context.go(onboardingDone ? '/auth' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Image.asset(
          'assets/images/app_icon.png',
          width: 120,
          height: 120,
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 800.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 800.ms)
            .shimmer(delay: 400.ms, duration: 1000.ms),
      ),
    );
  }
}
