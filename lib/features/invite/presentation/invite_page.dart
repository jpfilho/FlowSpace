import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/domain/data_providers.dart';

// ──────────────────────────────────────────────────────────────
// Provider: resolve o convite pelo token (via RPC pública)
// ──────────────────────────────────────────────────────────────
final _inviteInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, token) async {
  final client = ref.read(supabaseProvider);
  try {
    final result = await client
        .rpc('get_invite_preview', params: {'p_token': token});
    final data = result as Map<String, dynamic>;
    if (data['error'] != null) return null;
    // Transforma no formato esperado pelo _InviteCard
    return {
      'invited_email': data['invited_email'],
      'role': data['role'],
      'expires_at': data['expires_at'],
      'workspaces': {'name': data['workspace_name']},
    };
  } catch (_) {
    return null;
  }
});

// ──────────────────────────────────────────────────────────────
// Página principal
// ──────────────────────────────────────────────────────────────
class InvitePage extends ConsumerStatefulWidget {
  final String token;
  const InvitePage({super.key, required this.token});

  @override
  ConsumerState<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends ConsumerState<InvitePage> {
  bool _accepting = false;
  String? _errorMsg;
  bool _success = false;

  Future<void> _accept() async {
    final isAuthenticated =
        ref.read(authStateProvider).valueOrNull?.session != null;

    if (!isAuthenticated) {
      // Redireciona para login com o token preservado como query param
      context.go('${AppRoutes.login}?invite=${widget.token}');
      return;
    }

    setState(() {
      _accepting = true;
      _errorMsg = null;
    });

    try {
      final client = ref.read(supabaseProvider);
      final result = await client
          .rpc('accept_workspace_invite', params: {'p_token': widget.token});

      if (!mounted) return;

      final response = result as Map<String, dynamic>;
      if (response['error'] != null) {
        setState(() {
          _errorMsg = response['error'] as String;
          _accepting = false;
        });
      } else {
        setState(() => _success = true);
        // Aguarda animação e vai ao dashboard
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Erro ao aceitar convite: ${e.toString()}';
          _accepting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteAsync = ref.watch(_inviteInfoProvider(widget.token));
    final isAuthenticated =
        ref.watch(authStateProvider).valueOrNull?.session != null;

    return Scaffold(
      backgroundColor:
          context.isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.sp24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: AppSpacing.sp40),

                // Card do convite
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sp32),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? AppColors.surfaceDark
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: context.isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _success
                      ? _SuccessCard()
                      : inviteAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.sp24),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          error: (_, __) => _InvalidCard(),
                          data: (invite) => invite == null
                              ? _InvalidCard()
                              : _InviteCard(
                                  invite: invite,
                                  isAuthenticated: isAuthenticated,
                                  accepting: _accepting,
                                  errorMsg: _errorMsg,
                                  onAccept: _accept,
                                  onLogin: () => context.go(
                                    '${AppRoutes.login}?invite=${widget.token}',
                                  ),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          child:
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
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
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Card: convite válido
// ──────────────────────────────────────────────────────────────
class _InviteCard extends StatelessWidget {
  final Map<String, dynamic> invite;
  final bool isAuthenticated;
  final bool accepting;
  final String? errorMsg;
  final VoidCallback onAccept;
  final VoidCallback onLogin;

  const _InviteCard({
    required this.invite,
    required this.isAuthenticated,
    required this.accepting,
    required this.errorMsg,
    required this.onAccept,
    required this.onLogin,
  });

  String get _workspaceName {
    final ws = invite['workspaces'];
    if (ws is Map) return ws['name'] as String? ?? 'Workspace';
    return 'Workspace';
  }

  String get _roleLabel => switch (invite['role'] as String? ?? 'member') {
        'admin' => 'Administrador',
        'owner' => 'Proprietário',
        _ => 'Membro',
      };

  Color get _roleColor => switch (invite['role'] as String? ?? 'member') {
        'admin' => AppColors.primary,
        'owner' => AppColors.warning,
        _ => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icone de convite
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.group_add_rounded,
              color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: AppSpacing.sp20),

        Text(
          'Você foi convidado!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sp8),
        Text(
          'Aceite o convite para entrar no workspace:',
          style: TextStyle(fontSize: 14, color: context.cTextMuted),
        ),
        const SizedBox(height: AppSpacing.sp20),

        // Workspace info card
        Container(
          padding: const EdgeInsets.all(AppSpacing.sp16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
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
                child: const Icon(Icons.workspaces_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _workspaceName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.cTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                              color: _roleColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _roleColor,
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sp8),

        // Email invited_to
        Text(
          'Convite para: ${invite['invited_email'] ?? ''}',
          style: TextStyle(fontSize: 12, color: context.cTextMuted),
        ),
        const SizedBox(height: AppSpacing.sp24),

        // Erro
        if (errorMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sp12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(errorMsg!,
                    style: TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.sp16),
        ],

        // Botão
        if (isAuthenticated)
          FlowButton(
            label: accepting ? 'Aceitando...' : 'Aceitar convite',
            onPressed: accepting ? null : onAccept,
            isLoading: accepting,
            fullWidth: true,
            leadingIcon: Icons.check_circle_outline_rounded,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FlowButton(
                label: 'Entrar para aceitar',
                onPressed: onLogin,
                fullWidth: true,
                leadingIcon: Icons.login_rounded,
              ),
              const SizedBox(height: AppSpacing.sp12),
              Text(
                'Faça login com o e-mail do convite para continuar.',
                style: TextStyle(
                    fontSize: 12,
                    color: context.cTextMuted,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Card: convite inválido / expirado
// ──────────────────────────────────────────────────────────────
class _InvalidCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.link_off_rounded,
              color: AppColors.error, size: 32),
        ),
        const SizedBox(height: AppSpacing.sp20),
        Text(
          'Convite inválido ou expirado',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sp12),
        Text(
          'Este link de convite não é válido ou já expirou.\nPeça ao administrador do workspace um novo convite.',
          style: TextStyle(
              fontSize: 14,
              color: context.cTextMuted,
              height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sp24),
        Builder(
          builder: (ctx) => FlowButton(
            label: 'Ir para o início',
            onPressed: () => ctx.go(AppRoutes.dashboard),
            variant: FlowButtonVariant.outline,
            fullWidth: true,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Card: convite aceito com sucesso
// ──────────────────────────────────────────────────────────────
class _SuccessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 32),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 800.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.05, 1.05),
              end: const Offset(1, 1),
              duration: 800.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: AppSpacing.sp20),
        Text(
          'Bem-vindo ao workspace!',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sp8),
        Text(
          'Convite aceito com sucesso. Redirecionando...',
          style: TextStyle(
              fontSize: 14,
              color: context.cTextMuted,
              height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sp20),
        const LinearProgressIndicator(color: AppColors.success),
      ],
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}
