import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/flow_input.dart';
import '../domain/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? inviteToken;
  const LoginPage({super.key, this.inviteToken});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
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
      } else if (!next.isLoading && !next.hasError) {
        // Verifica se realmente autenticou (sessão ativa)
        final session = ref.read(authStateProvider).valueOrNull?.session;
        final token = widget.inviteToken;
        if (session != null && token != null && token.isNotEmpty) {
          context.go('${AppRoutes.invite}/$token');
        }
      }
    });

    return Scaffold(
      backgroundColor:
          context.isDark ? AppColors.backgroundDark : AppColors.background,
      body: Row(
        children: [
          // Left -- Branding Panel (desktop only)
          if (Responsive.isDesktop(context))
            Expanded(
              child: _BrandingPanel(),
            ),

          // Right -- Login Form
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.sp32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Logo(),
                        const SizedBox(height: AppSpacing.sp32),
                        Text(
                          'Bem-vindo de volta',
                          style: context.theme.textTheme.headlineMedium,
                        ).animate().fadeIn(duration: 400.ms).slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 400.ms,
                            ),
                        const SizedBox(height: AppSpacing.sp8),
                        Text(
                          'Entre na sua conta para continuar',
                          style: context.theme.textTheme.bodyMedium?.copyWith(
                            color: context.cTextMuted,
                          ),
                        ).animate().fadeIn(delay: 50.ms, duration: 400.ms),
                        const SizedBox(height: AppSpacing.sp32),

                        // Email
                        FlowInput(
                          controller: _emailCtrl,
                          label: 'E-mail',
                          hint: 'seu@email.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline_rounded,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe seu e-mail';
                            }
                            if (!v.contains('@')) return 'E-mail inválido';
                            return null;
                          },
                        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                        const SizedBox(height: AppSpacing.sp12),

                        // Password
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
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                          onSubmitted: (_) => _handleLogin(),
                        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                        const SizedBox(height: AppSpacing.sp8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.go(AppRoutes.forgotPassword),
                            child: Text(
                              'Esqueceu a senha?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sp20),
                        FlowButton(
                          label: 'Entrar',
                          onPressed: isLoading ? null : _handleLogin,
                          isLoading: isLoading,
                          size: FlowButtonSize.lg,
                          fullWidth: true,
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                        const SizedBox(height: AppSpacing.sp24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Não tem conta? ',
                              style: context.bodySm,
                            ),
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.signup),
                              child: Text(
                                'Criar conta',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: AppSpacing.sp12),
        Text(
          'FlowSpace',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.cTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1F4E), Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sp48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sp16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp24),
                const Text(
                  'Seu trabalho,\nsua forma —\nem perfeito fluxo.',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp16),
                Text(
                  'Unifique tarefas, projetos, documentos e agenda numa única plataforma elegante e poderosa.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp40),
                _buildFeatureBadge(Icons.check_circle_outline, 'Gestão GTD integrada'),
                const SizedBox(height: AppSpacing.sp12),
                _buildFeatureBadge(Icons.view_kanban_outlined, 'Kanban, lista e calendário'),
                const SizedBox(height: AppSpacing.sp12),
                _buildFeatureBadge(Icons.article_outlined, 'Editor de documentos em blocos'),
                const Spacer(),
                Text(
                  '© 2025 FlowSpace',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryLight, size: 18),
        const SizedBox(width: AppSpacing.sp8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
