import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_states.dart';
import '../../auth/domain/data_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.sp32 : AppSpacing.sp20,
            vertical: AppSpacing.sp20,
          ),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: context.isDark
                    ? AppColors.borderDark
                    : AppColors.border,
              ),
            ),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.notifications_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notificações',
                        style: Theme.of(context).textTheme.titleLarge),
                    if (unread > 0)
                      Text(
                        '$unread não lida${unread > 1 ? 's' : ''}',
                        style: AppTypography.caption(AppColors.primary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                  ]),
            ),
            if (unread > 0)
              TextButton.icon(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Marcar tudo como lido'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ]),
        ),

        // ── Content ─────────────────────────────────────────
        Expanded(
          child: notifsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => FlowErrorState(
              message: 'Erro ao carregar: $e',
              onRetry: () => ref.refresh(notificationsProvider),
            ),
            data: (notifs) {
              if (notifs.isEmpty) {
                return const FlowEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Sem notificações',
                  subtitle:
                      'Você está em dia! Novas notificações aparecerão aqui.',
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? AppSpacing.sp32 : AppSpacing.sp16,
                  vertical: AppSpacing.sp12,
                ),
                itemCount: notifs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sp4),
                itemBuilder: (_, i) {
                  final n = notifs[i];
                  return _NotificationTile(notification: n)
                      .animate()
                      .fadeIn(delay: (i * 30).ms, duration: 250.ms);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _NotificationTile extends ConsumerStatefulWidget {
  final NotificationData notification;
  const _NotificationTile({required this.notification});

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  bool _hovering = false;

  IconData _iconForType(String type) {
    return switch (type) {
      'task_assigned'  => Icons.check_box_rounded,
      'task_completed' => Icons.task_alt_rounded,
      'comment'        => Icons.comment_rounded,
      'mention'        => Icons.alternate_email_rounded,
      'project_update' => Icons.folder_rounded,
      'deadline'       => Icons.alarm_rounded,
      _                => Icons.notifications_rounded,
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'task_assigned'  => AppColors.primary,
      'task_completed' => AppColors.success,
      'comment'        => AppColors.accent,
      'mention'        => AppColors.warning,
      'project_update' => AppColors.accent,
      'deadline'       => AppColors.error,
      _                => AppColors.primary,
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final icon = _iconForType(n.type);
    final color = _colorForType(n.type);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () {
          if (!n.isRead) {
            ref.read(notificationsProvider.notifier).markRead(n.id);
          }
        },
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(AppSpacing.sp16),
          decoration: BoxDecoration(
            color: n.isRead
                ? Colors.transparent
                : (context.isDark
                    ? color.withValues(alpha: 0.06)
                    : color.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hovering
                  ? color.withValues(alpha: 0.3)
                  : (n.isRead
                      ? Colors.transparent
                      : color.withValues(alpha: 0.12)),
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.sp12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                      color: context.cTextPrimary,
                    ),
                  ),
                  if (n.body != null && n.body!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        n.body!,
                        style: TextStyle(
                            fontSize: 12, color: context.cTextMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(n.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: context.cTextMuted),
                  ),
                ],
              ),
            ),

            // Unread dot + dismiss
            Column(mainAxisSize: MainAxisSize.min, children: [
              if (!n.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              if (_hovering)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 14, color: context.cTextMuted),
                    iconSize: 14,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: EdgeInsets.zero,
                    tooltip: 'Remover',
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).delete(n.id),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
