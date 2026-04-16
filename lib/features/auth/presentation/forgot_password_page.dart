import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/flow_input.dart';
import '../domain/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(_emailCtrl.text.trim());
    if (mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor:
          context.isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.sp32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _sent
                ? _SuccessState(onBack: () => context.go(AppRoutes.login))
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IconButton(
                          onPressed: () => context.go(AppRoutes.login),
                          icon: const Icon(Icons.arrow_back_rounded),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: AppSpacing.sp24),
                        Text(
                          'Recuperar senha',
                          style: context.theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.sp8),
                        Text(
                          'Enviaremos um link de recuperação para seu e-mail.',
                          style: context.bodySm,
                        ),
                        const SizedBox(height: AppSpacing.sp32),
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
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sp20),
                        FlowButton(
                          label: 'Enviar link',
                          onPressed: isLoading ? null : _handleReset,
                          isLoading: isLoading,
                          fullWidth: true,
                          size: FlowButtonSize.lg,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  final VoidCallback onBack;
  const _SuccessState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.sp20),
        Text('E-mail enviado!', style: context.theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sp8),
        Text(
          'Verifique sua caixa de entrada e siga as instruções.',
          style: context.bodySm,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sp32),
        FlowButton(
          label: 'Voltar ao login',
          onPressed: onBack,
          variant: FlowButtonVariant.outline,
          fullWidth: true,
        ),
      ],
    );
  }
}
