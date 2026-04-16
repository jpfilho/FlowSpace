import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/index.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/domain/data_providers.dart';

// Providers autoDispose para dados de configurações
final _profileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(currentUserProvider)?.id;
  if (uid == null) return null;
  final client = ref.read(supabaseProvider);
  return await client.from('profiles').select().eq('id', uid).maybeSingle();
});

final _membersProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, wsId) async {
  final client = ref.read(supabaseProvider);
  return await client
      .from('workspace_members')
      .select('role, profiles(name, bio)')
      .eq('workspace_id', wsId);
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(_profileProvider);
    final workspaceAsync = ref.watch(currentWorkspaceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.sp24),
        children: [
          // ── Header ───────────────────────────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configurações',
                        style: Theme.of(context).textTheme.headlineSmall)
                    .animate()
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: AppSpacing.sp4),
                Text(user?.email ?? '', style: context.bodySm),
                const SizedBox(height: AppSpacing.sp28),

                // ── CONTA ─────────────────────────────────────
                _buildSection(
                  context,
                  'CONTA',
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.primary,
                      title: 'Perfil',
                      subtitle: profileAsync.value?['name'] as String? ??
                          'Nome, bio',
                      onTap: () =>
                          _showEditProfile(context, ref, profileAsync.value),
                    ),
                    _buildDivider(context),
                    _buildTile(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      iconColor: AppColors.primary,
                      title: 'Alterar senha',
                      subtitle: 'Atualizar senha de acesso',
                      onTap: () => _showChangePassword(context, ref),
                    ),
                    _buildDivider(context),
                    _buildTile(
                      context: context,
                      icon: Icons.mail_outline_rounded,
                      iconColor: AppColors.primary,
                      title: 'E-mail',
                      subtitle: user?.email ?? '—',
                      onTap: null,
                    ),
                  ],
                ).animate().fadeIn(delay: 50.ms),

                const SizedBox(height: AppSpacing.sp20),

                // ── APARÊNCIA ─────────────────────────────────
                _buildSection(
                  context,
                  'APARÊNCIA',
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.dark_mode_outlined,
                      iconColor: AppColors.accent,
                      title: 'Tema da interface',
                      subtitle: themeNotifier.label,
                      onTap: () =>
                          _showThemePicker(context, ref, themeMode),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: AppSpacing.sp20),

                // ── WORKSPACE ─────────────────────────────────
                _buildSection(
                  context,
                  'WORKSPACE',
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.business_rounded,
                      iconColor: AppColors.success,
                      title: 'Nome do workspace',
                      subtitle:
                          workspaceAsync.value?.name ?? 'Carregando...',
                      onTap: () => _showEditWorkspace(
                          context, ref, workspaceAsync.value),
                    ),
                    _buildDivider(context),
                    _buildTile(
                      context: context,
                      icon: Icons.people_outline_rounded,
                      iconColor: AppColors.success,
                      title: 'Membros',
                      subtitle: 'Gerenciar membros do workspace',
                      onTap: workspaceAsync.value != null
                          ? () => _showMembers(
                              context, ref, workspaceAsync.value!.id)
                          : null,
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: AppSpacing.sp20),

                // ── DADOS E EXPORTAÇÃO ─────────────────────────
                _buildSection(
                  context,
                  'DADOS E EXPORTAÇÃO',
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.table_view_rounded,
                      iconColor: AppColors.primary,
                      title: 'Exportar Tarefas (.csv)',
                      subtitle: 'Baixar todas as tarefas do workspace ativo',
                      onTap: () => _exportData(context, ref, 'csv'),
                    ),
                    _buildDivider(context),
                    _buildTile(
                      context: context,
                      icon: Icons.data_object_rounded,
                      iconColor: AppColors.primary,
                      title: 'Exportar Tarefas (.json)',
                      subtitle: 'Baixar todas as tarefas do workspace ativo',
                      onTap: () => _exportData(context, ref, 'json'),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: AppSpacing.sp20),

                // ── INTEGRAÇÕES ───────────────────────────────
                _buildSection(
                  context,
                  'INTEGRAÇÕES',
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFF464EB8), // Teams Blurple
                      title: 'Microsoft Teams / Outlook',
                      subtitle: 'Sincronizar agenda corporativa',
                      onTap: () => _linkMicrosoftAccount(context, ref),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: AppSpacing.sp20),

                // ── SESSÃO ────────────────────────────────────
                _buildSection(
                  context,
                  'SESSÃO',
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.error,
                      title: 'Sair',
                      subtitle: 'Encerrar sessão atual',
                      titleColor: AppColors.error,
                      onTap: () => _confirmSignOut(context, ref),
                      showChevron: false,
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: AppSpacing.sp40),

                Center(
                  child: Text(
                    'FlowSpace v1.0.0 • Supabase local',
                    style: AppTypography.caption(context.cTextMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.sp24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref, String format) async {
    final tasks = ref.read(tasksProvider).valueOrNull;
    if (tasks == null || tasks.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sem tarefas para exportar')));
      }
      return;
    }

    String content = '';
    String mime = '';
    if (format == 'csv') {
      mime = 'text/csv;charset=utf-8';
      content = 'id,title,status,priority,dueDate,completed,isSomeday\n';
      content += tasks.map((t) => '${t.id},"${t.title.replaceAll('"', '""')}","${t.status}","${t.priority}","${t.dueDate?.toIso8601String() ?? ''}",${t.completed},${t.isSomeday}').join('\n');
    } else {
      mime = 'application/json;charset=utf-8';
      content = jsonEncode(tasks.map((t) => {
        'id': t.id,
        'title': t.title,
        'status': t.status,
        'priority': t.priority,
        'dueDate': t.dueDate?.toIso8601String(),
        'completed': t.completed,
        'isSomeday': t.isSomeday,
      }).toList());
    }

    if (kIsWeb) {
      html.AnchorElement(href: 'data:$mime,${Uri.encodeComponent(content)}')
        ..setAttribute('download', 'flowspace_tasks.$format')
        ..click();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportação suportada apenas na Web por enquanto.')));
      }
    }
  }

  // ── Builder helpers ─────────────────────────────────────────
  Future<void> _linkMicrosoftAccount(BuildContext context, WidgetRef ref) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Iniciando vinculação com Microsoft...')));
      }
      final service = ref.read(msGraphServiceProvider);
      await service.linkTeamsAccount();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao conectar: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sp8),
          child: Text(
            title,
            style: AppTypography.caption(context.cTextMuted).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Material(
          color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color:
                    context.isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16,
          vertical: AppSpacing.sp14,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? context.cTextPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: context.bodySm),
                ],
              ),
            ),
            if (showChevron && onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: context.cTextMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      color: context.isDark ? AppColors.borderDark : AppColors.border,
    );
  }

  // ── Editar Perfil ──────────────────────────────────────────
  void _showEditProfile(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? profile) {
    final nameCtrl =
        TextEditingController(text: profile?['name'] as String? ?? '');
    final bioCtrl =
        TextEditingController(text: profile?['bio'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final uid = ref.read(currentUserProvider)?.id;
              if (uid == null) return;
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final client = ref.read(supabaseProvider);
              await client.from('profiles').update({
                'name': name,
                'bio': bioCtrl.text.trim(),
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', uid);
              // ignore: unused_result
              ref.refresh(_profileProvider);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Perfil atualizado!'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ── Alterar Senha ─────────────────────────────────────────
  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Alterar senha'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirmar senha'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (newCtrl.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Mínimo 6 caracteres'),
                                  backgroundColor: AppColors.error));
                          return;
                        }
                        if (newCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Senhas não coincidem'),
                                  backgroundColor: AppColors.error));
                          return;
                        }
                        setState(() => loading = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await Supabase.instance.client.auth.updateUser(
                              UserAttributes(password: newCtrl.text));
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            messenger.showSnackBar(const SnackBar(
                              content: Text('Senha alterada!'),
                              backgroundColor: AppColors.success,
                            ));
                          }
                        } catch (e) {
                          setState(() => loading = false);
                          messenger.showSnackBar(SnackBar(
                              content: Text('Erro: $e'),
                              backgroundColor: AppColors.error));
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar'),
              ),
            ],
          );
          },
        );
      },
    );
  }

  // ── Seletor de Tema ───────────────────────────────────────
  void _showThemePicker(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Tema da interface'),
        children: [
          _themeOption(ctx, ref, Icons.light_mode_outlined, 'Claro',
              ThemeMode.light, current),
          _themeOption(ctx, ref, Icons.dark_mode_outlined, 'Escuro',
              ThemeMode.dark, current),
          _themeOption(ctx, ref, Icons.brightness_auto_rounded,
              'Sistema (padrão)', ThemeMode.system, current),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext ctx, WidgetRef ref, IconData icon,
      String label, ThemeMode mode, ThemeMode current) {
    final selected = mode == current;
    return SimpleDialogOption(
      onPressed: () {
        ref.read(themeModeProvider.notifier).setTheme(mode);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon,
              size: 20, color: selected ? AppColors.primary : null),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : null,
                )),
          ),
          if (selected)
            const Icon(Icons.check_rounded,
                size: 18, color: AppColors.primary),
        ]),
      ),
    );
  }

  // ── Editar Workspace ──────────────────────────────────────
  void _showEditWorkspace(
      BuildContext context, WidgetRef ref, WorkspaceData? workspace) {
    if (workspace == null) return;
    final ctrl = TextEditingController(text: workspace.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome do workspace'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final client = ref.read(supabaseProvider);
              await client
                  .from('workspaces')
                  .update({'name': ctrl.text.trim()})
                  .eq('id', workspace.id);
              // ignore: unused_result
              ref.refresh(currentWorkspaceProvider);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Workspace atualizado!'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ── Membros ───────────────────────────────────────────────
  void _showMembers(
      BuildContext context, WidgetRef ref, String workspaceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MembersSheet(workspaceId: workspaceId),
    );
  }

  // ── Sair ─────────────────────────────────────────────────
  Future<void> _confirmSignOut(
      BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do FlowSpace'),
        content:
            const Text('Tem certeza que deseja encerrar sua sessão?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }
}

// ── Members Sheet ──────────────────────────────────────────────
class _MembersSheet extends ConsumerWidget {
  final String workspaceId;
  const _MembersSheet({required this.workspaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(_membersProvider(workspaceId));

    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.sp24,
        left: AppSpacing.sp24,
        right: AppSpacing.sp24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sp32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: context.isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
          ),
          const SizedBox(height: AppSpacing.sp20),
          Text('Membros do workspace',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sp16),
          membersAsync.when(
            data: (members) => members.isEmpty
                ? const Text('Nenhum membro encontrado')
                : Column(
                    children: members.map((m) {
                      final profile =
                          m['profiles'] as Map<String, dynamic>?;
                      final name =
                          profile?['name'] as String? ?? 'Sem nome';
                      final role = m['role'] as String? ?? 'member';
                      final (roleLabel, roleColor) = switch (role) {
                        'admin' => ('Admin', AppColors.primary),
                        'manager' => ('Gerente', AppColors.accent),
                        _ => ('Membro', AppColors.success),
                      };
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(name,
                            style: context.bodyMd
                                .copyWith(fontWeight: FontWeight.w500)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sp8, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(roleLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: roleColor)),
                        ),
                      );
                    }).toList(),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.sp20),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, _) => Text('Erro: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
