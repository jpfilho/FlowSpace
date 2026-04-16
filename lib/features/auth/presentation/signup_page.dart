import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/flow_input.dart';
import '../domain/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          name: _nameCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor:
          context.isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.sp32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: AppSpacing.sp24),

                  Text(
                    'Criar sua conta',
                    style: context.theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 50.ms),
                  const SizedBox(height: AppSpacing.sp8),
                  Text(
                    'Comece gratuitamente hoje',
                    style: context.bodySm,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: AppSpacing.sp32),

                  FlowInput(
                    controller: _nameCtrl,
                    label: 'Seu nome',
                    hint: 'João Silva',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe seu nome' : null,
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: AppSpacing.sp12),

                  FlowInput(
                    controller: _emailCtrl,
                    label: 'E-mail',
                    hint: 'seu@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe seu e-mail';
                      if (!v.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: AppSpacing.sp12),

                  FlowInput(
                    controller: _passCtrl,
                    label: 'Senha',
                    hint: '••••••••',
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: context.cTextMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: AppSpacing.sp24),
                  FlowButton(
                    label: 'Criar conta',
                    onPressed: isLoading ? null : _handleSignup,
                    isLoading: isLoading,
                    size: FlowButtonSize.lg,
                    fullWidth: true,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: AppSpacing.sp20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Já tem conta? ', style: context.bodySm),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Entrar',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
