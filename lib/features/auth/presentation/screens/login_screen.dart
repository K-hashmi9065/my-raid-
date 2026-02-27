import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gradient_button.dart';
import '../../../../core/errors/failures.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    ref.listen(authStateProvider, (previous, next) {
      if (next is AsyncError) {
        final error = next.error;
        String msg = 'Authentication failed. Please try again.';
        if (error is NetworkFailure) msg = 'No internet connection';
        if (error is ServerFailure) msg = error.message;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    _buildHeader(context),
                    const SizedBox(height: 48),
                    _buildForm(context, isLoading),
                    const SizedBox(height: 24),
                    _buildFooter(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child:
              const Icon(Icons.task_alt_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 28),
        Text(
          'Welcome back! 👋',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue managing your tasks',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Enter your username',
            prefixIcon: Icons.person_outline_rounded,
            enabled: !isLoading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username is required';
              if (v.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            enabled: !isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondaryLight,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 32),
          GradientButton(
            onPressed: isLoading ? null : _login,
            isLoading: isLoading,
            text: 'Sign In',
            icon: Icons.login_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () => context.push(AppRoutes.register),
          child: Text(
            'Sign Up',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ],
    );
  }
}
