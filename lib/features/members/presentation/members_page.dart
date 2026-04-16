import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/index.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/domain/data_providers.dart';

// ─────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────

class WorkspaceMember {
  final String userId;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final DateTime joinedAt;

  const WorkspaceMember({
    required this.userId,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
    required this.joinedAt,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> j) => WorkspaceMember(
        userId: j['user_id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        avatar: j['avatar'] as String?,
        role: j['role'] as String? ?? 'member',
        joinedAt: DateTime.parse(j['joined_at'] as String),
      );
}

class WorkspaceInvite {
  final String id;
  final String invitedEmail;
  final String role;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const WorkspaceInvite({
    required this.id,
    required this.invitedEmail,
    required this.role,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory WorkspaceInvite.fromJson(Map<String, dynamic> j) => WorkspaceInvite(
        id: j['id'] as String,
        invitedEmail: j['invited_email'] as String,
        role: j['role'] as String? ?? 'member',
        status: j['status'] as String? ?? 'pending',
        expiresAt: DateTime.parse(j['expires_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

final workspaceMembersProvider =
    FutureProvider.autoDispose<List<WorkspaceMember>>((ref) async {
  final workspace = await ref.watch(currentWorkspaceProvider.future);
  if (workspace == null) return [];

  final client = ref.read(supabaseProvider);
  final data = await client.rpc('list_workspace_members', params: {
    'p_workspace': workspace.id,
  }) as List<dynamic>;

  return data
      .map((e) => WorkspaceMember.fromJson(e as Map<String, dynamic>))
      .toList();
});

final workspaceInvitesProvider =
    FutureProvider.autoDispose<List<WorkspaceInvite>>((ref) async {
  final workspace = await ref.watch(currentWorkspaceProvider.future);
  if (workspace == null) return [];

  final client = ref.read(supabaseProvider);
  final data = await client
      .from('workspace_invites')
      .select('id, invited_email, role, status, expires_at, created_at')
      .eq('workspace_id', workspace.id)
      .order('created_at', ascending: false) as List<dynamic>;

  return data
      .map((e) => WorkspaceInvite.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─────────────────────────────────────────────────────────────
// MEMBERS PAGE
// ─────────────────────────────────────────────────────────────

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(workspaceMembersProvider);
    final invitesAsync = ref.watch(workspaceInvitesProvider);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sp24),
              decoration: BoxDecoration(
                color:
                    context.isDark ? AppColors.surfaceDark : AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: context.isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Membros',
                          style: Theme.of(context).textTheme.headlineSmall),
                      membersAsync.when(
                        data: (list) => Text(
                          '${list.length} membro${list.length != 1 ? 's' : ''} no workspace',
                          style: context.bodySm,
                        ),
                        loading: () =>
                            Text('Carregando...', style: context.bodySm),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showInviteDialog(context, ref),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Convidar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Members list ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp24, AppSpacing.sp20, AppSpacing.sp24, 0),
              child: Text('Membros ativos',
                  style: context.labelMd
                      .copyWith(color: context.cTextMuted)),
            ),
          ),

          membersAsync.when(
            data: (members) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _MemberTile(member: members[i])
                    .animate()
                    .fadeIn(delay: (i * 40).ms, duration: 300.ms)
                    .slideX(begin: -0.02),
                childCount: members.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sp24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sp24),
                child: Text('Erro ao carregar membros: $e',
                    style: TextStyle(color: AppColors.error)),
              ),
            ),
          ),

          // ── Pending invites ───────────────────────────────
          invitesAsync.when(
            data: (invites) {
              final pending =
                  invites.where((i) => i.status == 'pending').toList();
              if (pending.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sp24, AppSpacing.sp24, AppSpacing.sp24, 8),
                      child: Text('Convites pendentes',
                          style: context.labelMd
                              .copyWith(color: context.cTextMuted)),
                    ),
                    ...pending.map((inv) => _InviteTile(
                          invite: inv,
                          onCancel: () async {
                            final client = ref.read(supabaseProvider);
                            await client
                                .from('workspace_invites')
                                .delete()
                                .eq('id', inv.id);
                            // ignore: unused_result
                            ref.refresh(workspaceInvitesProvider);
                          },
                        )),
                  ],
                ),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _InviteDialog(ref: ref),
    );
  }
}

// -----------------------------------------------------------------
// Member Tile
// -----------------------------------------------------------------

class _MemberTile extends ConsumerWidget {
  final WorkspaceMember member;
  const _MemberTile({required this.member});

  Color get _roleColor => switch (member.role) {
        'owner' => AppColors.warning,
        'admin' => AppColors.primary,
        _ => AppColors.success,
      };

  String get _roleLabel => switch (member.role) {
        'owner' => 'Proprietário',
        'admin' => 'Admin',
        _ => 'Membro',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isMe = currentUser?.id == member.userId;
    final isOwner = member.role == 'owner';
    final canManage = !isMe && !isOwner;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp24, vertical: AppSpacing.sp6),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp16),
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: member.avatar != null ? NetworkImage(member.avatar!) : null,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: member.avatar == null
                ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))
                : null,
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(
                    member.name.isNotEmpty ? member.name : member.email,
                    style: context.bodyMd.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('você', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              Text(member.email, style: context.bodySm.copyWith(color: context.cTextMuted)),
            ]),
          ),
          const SizedBox(width: AppSpacing.sp8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: _roleColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(_roleLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _roleColor)),
          ),
          if (canManage) ...[
            const SizedBox(width: AppSpacing.sp4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 18, color: context.cTextMuted),
              padding: EdgeInsets.zero,
              tooltip: 'Opcoes',
              onSelected: (v) async {
                if (v == 'remove') {
                  await _confirmRemove(context, ref);
                } else {
                  await _changeRole(context, ref, v == 'make_admin' ? 'admin' : 'member');
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: member.role == 'admin' ? 'make_member' : 'make_admin',
                  child: Row(children: [
                    Icon(member.role == 'admin' ? Icons.person_outline_rounded : Icons.admin_panel_settings_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(member.role == 'admin' ? 'Tornar membro' : 'Tornar admin'),
                  ]),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(children: [
                    Icon(Icons.person_remove_outlined, size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Remover do workspace', style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover membro'),
        content: Text('Remover "' + (member.name.isNotEmpty ? member.name : member.email) + '" do workspace? Esta acao nao pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Remover')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      final workspace = await ref.read(currentWorkspaceProvider.future);
      if (workspace == null) return;
      await ref.read(supabaseProvider).from('workspace_members').delete()
          .eq('workspace_id', workspace.id).eq('user_id', member.userId);
      // ignore: unused_result
      ref.refresh(workspaceMembersProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membro removido.'), backgroundColor: AppColors.success));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ' + e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _changeRole(BuildContext context, WidgetRef ref, String newRole) async {
    try {
      final workspace = await ref.read(currentWorkspaceProvider.future);
      if (workspace == null) return;
      await ref.read(supabaseProvider).from('workspace_members').update({'role': newRole})
          .eq('workspace_id', workspace.id).eq('user_id', member.userId);
      // ignore: unused_result
      ref.refresh(workspaceMembersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text((member.name.isNotEmpty ? member.name : member.email) + ' agora e ' + (newRole == 'admin' ? 'Admin' : 'Membro') + '.'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ' + e.toString()), backgroundColor: AppColors.error));
    }
  }
}


// ─────────────────────────────────────────────────────────────
// Invite Tile
// ─────────────────────────────────────────────────────────────

class _InviteTile extends StatelessWidget {
  final WorkspaceInvite invite;
  final VoidCallback onCancel;

  const _InviteTile({required this.invite, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp24, vertical: AppSpacing.sp4),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12),
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: invite.isExpired
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.mail_outline_rounded,
              size: 18,
              color: invite.isExpired ? AppColors.error : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invite.invitedEmail,
                      style: context.bodyMd
                          .copyWith(fontWeight: FontWeight.w500)),
                  Text(
                    invite.isExpired
                        ? 'Expirado'
                        : 'Expira ${_formatDate(invite.expiresAt)}',
                    style: context.bodySm.copyWith(
                        color: invite.isExpired
                            ? AppColors.error
                            : context.cTextMuted),
                  ),
                ],
              ),
            ),
            // Role
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                invite.role,
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            // Cancel
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded, size: 16),
              color: AppColors.error,
              tooltip: 'Cancelar convite',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.inDays > 0) return 'em ${diff.inDays}d';
    if (diff.inHours > 0) return 'em ${diff.inHours}h';
    return 'em breve';
  }
}

// ─────────────────────────────────────────────────────────────
// Invite Dialog
// ─────────────────────────────────────────────────────────────

class _InviteDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _InviteDialog({required this.ref});

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _role = 'member';
  bool _loading = false;
  String? _error;
  String? _successToken;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Email inválido');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final workspace =
          await ref.read(currentWorkspaceProvider.future);
      if (workspace == null) throw Exception('Workspace não encontrado');

      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Não autenticado');

      final client = ref.read(supabaseProvider);

      // Check if already a member
      final existing = await client
          .from('workspace_invites')
          .select('id, status')
          .eq('workspace_id', workspace.id)
          .eq('invited_email', email)
          .eq('status', 'pending')
          .maybeSingle();

      if (existing != null) {
        setState(() {
          _error = 'Já existe um convite pendente para este email';
          _loading = false;
        });
        return;
      }

      // Create invite
      final result = await client
          .from('workspace_invites')
          .insert({
            'workspace_id': workspace.id,
            'invited_email': email,
            'invited_by': user.id,
            'role': _role,
            if (_msgCtrl.text.trim().isNotEmpty)
              'message': _msgCtrl.text.trim(),
          })
          .select('token')
          .single();

      final token = result['token'] as String;

      // ignore: unused_result
      widget.ref.refresh(workspaceInvitesProvider);

      setState(() {
        _successToken = token;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text('Convidar membro'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: _successToken != null
            ? _SuccessView(token: _successToken!)
            : _FormView(
                emailCtrl: _emailCtrl,
                msgCtrl: _msgCtrl,
                role: _role,
                error: _error,
                onRoleChanged: (r) => setState(() => _role = r),
              ),
      ),
      actions: _successToken != null
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: _loading ? null : _sendInvite,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar convite'),
              ),
            ],
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController msgCtrl;
  final String role;
  final String? error;
  final ValueChanged<String> onRoleChanged;

  const _FormView({
    required this.emailCtrl,
    required this.msgCtrl,
    required this.role,
    required this.error,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email do convidado',
            hintText: 'exemplo@empresa.com',
            prefixIcon: Icon(Icons.email_outlined, size: 18),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sp16),
        Text('Função', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'member', label: Text('Membro')),
            ButtonSegment(value: 'admin', label: Text('Admin')),
          ],
          selected: {role},
          onSelectionChanged: (s) => onRoleChanged(s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.sp16),
        TextField(
          controller: msgCtrl,
          decoration: const InputDecoration(
            labelText: 'Mensagem (opcional)',
            hintText: 'Uma mensagem pessoal...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              style: TextStyle(color: AppColors.error, fontSize: 13)),
        ],
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String token;
  const _SuccessView({required this.token});

  @override
  Widget build(BuildContext context) {
    // In a real app this would be an actual deep-link URL
    final inviteUrl = 'https://flowspace.app/invite/$token';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded,
            size: 56, color: AppColors.success)
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: AppSpacing.sp16),
        Text('Convite criado!',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Compartilhe o link abaixo com o convidado.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sp20),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sp12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  inviteUrl,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: inviteUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copiado!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Icon(Icons.copy_rounded,
                    size: 18, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
