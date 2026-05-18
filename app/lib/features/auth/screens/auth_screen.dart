import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_input.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isSignIn = true;
  bool _loading = false;
  bool _submitted = false;
  bool _showPass = false;
  bool _showConfirm = false;
  bool _confirmationSent = false;

  String? _emailError;
  String? _passError;
  String? _confirmError;
  String? _generalError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    String? emailErr;
    String? passErr;
    String? confirmErr;

    if (!_emailCtrl.text.trim().contains('@')) {
      emailErr = 'Enter a valid email address';
    }
    if (_passCtrl.text.length < 6) {
      passErr = 'Password must be at least 6 characters';
    }
    if (!_isSignIn && _confirmCtrl.text != _passCtrl.text) {
      confirmErr = 'Passwords do not match';
    }

    setState(() {
      _emailError = emailErr;
      _passError = passErr;
      _confirmError = confirmErr;
    });

    return emailErr == null && passErr == null && confirmErr == null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_validate()) return;

    setState(() {
      _loading = true;
      _generalError = null;
    });

    try {
      if (_isSignIn) {
        await ref
            .read(authNotifierProvider.notifier)
            .signIn(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        final sessionCreated = await ref
            .read(authNotifierProvider.notifier)
            .signUp(_emailCtrl.text.trim(), _passCtrl.text);
        // signUp returns false when Supabase requires email confirmation.
        // Show "check your inbox" instead of silently doing nothing.
        if (mounted && !sessionCreated) {
          setState(() => _confirmationSent = true);
          return;
        }
        // Session was created — GoRouter redirect fires automatically.
      }
    } on AuthException catch (e) {
      setState(() => _generalError = e.message);
    } catch (_) {
      setState(() => _generalError = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _submitted = false;
      _emailError = null;
      _passError = null;
      _confirmError = null;
      _generalError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: _confirmationSent
            ? _ConfirmationSentView(
                email: _emailCtrl.text.trim(),
                onSignIn: () => setState(() {
                  _confirmationSent = false;
                  _isSignIn = true;
                  _submitted = false;
                  _generalError = null;
                }),
              )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Text(
                'spent',
                style: AppTextStyles.display.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Your money, clearly.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: AppInput(
                  controller: _emailCtrl,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: _submitted ? (_) => _validate() : null,
                ),
              ),
              if (_emailError != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailError!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Password
              AppInput(
                controller: _passCtrl,
                hint: 'Password',
                obscureText: !_showPass,
                autocorrect: false,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
                onChanged: _submitted ? (_) => _validate() : null,
              ),
              if (_passError != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _passError!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ),
              ],
              // Confirm password (sign-up only)
              if (!_isSignIn) ...[
                const SizedBox(height: 12),
                AppInput(
                  controller: _confirmCtrl,
                  hint: 'Confirm Password',
                  obscureText: !_showConfirm,
                  autocorrect: false,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                  onChanged: _submitted ? (_) => _validate() : null,
                ),
                if (_confirmError != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _confirmError!,
                      style:
                          AppTextStyles.caption.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              // Primary button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isSignIn ? 'Sign In' : 'Create Account',
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (_generalError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _generalError!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              // Mode toggle
              Text.rich(
                TextSpan(
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: _isSignIn
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: _toggleMode,
                        child: Text(
                          _isSignIn ? 'Sign up' : 'Sign in',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationSentView extends StatelessWidget {
  const _ConfirmationSentView({required this.email, required this.onSignIn});

  final String email;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.pageMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              color: AppColors.accent, size: 64),
          const SizedBox(height: 24),
          Text('Check your inbox',
              style: AppTextStyles.heading1, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'We sent a confirmation link to\n$email\n\nOpen it to activate your account, then come back to sign in.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                ),
              ),
              child: Text(
                'Back to Sign In',
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
