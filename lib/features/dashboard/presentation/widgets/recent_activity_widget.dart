import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/index.dart';
import '../../../auth/domain/data_providers.dart';

class RecentActivityWidget extends ConsumerWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sp20),
            child: Row(
              children: [
                Text(
                  'Atividade recente',
                  style: AppTypography.heading(context.cTextPrimary)
                      .copyWith(fontSize: 16),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp6),
                Text(
                  'Ao vivo',
                  style: AppTypography.caption(AppColors.success).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          notifAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.sp24),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.sp20),
              child: Text('Erro ao carregar: $e',
                  style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.sp32,
                      horizontal: AppSpacing.sp20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 36, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'Nenhuma atividade recente',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final items = notifications.take(8).toList();
              return Column(
                children: items.asMap().entries.map((e) {
                  final notif = e.value;
                  return _ActivityRow(
                    notification: notif,
                    isLast: e.key == items.length - 1,
                  )
                      .animate()
                      .fadeIn(delay: (e.key * 30).ms, duration: 250.ms);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final NotificationData notification;
  final bool isLast;

  const _ActivityRow({
    required this.notification,
    required this.isLast,
  });

  IconData get _icon => switch (notification.type) {
        'task_assigned' => Icons.assignment_ind_rounded,
        'task_completed' => Icons.check_circle_outline_rounded,
        'comment_added' => Icons.comment_outlined,
        'project_update' => Icons.folder_outlined,
        'mention' => Icons.alternate_email_rounded,
        'invite_accepted' => Icons.person_add_alt_1_rounded,
        _ => Icons.notifications_outlined,
      };

  Color get _color => switch (notification.type) {
        'task_assigned' => AppColors.primary,
        'task_completed' => AppColors.success,
        'comment_added' => AppColors.accent,
        'project_update' => AppColors.warning,
        'mention' => AppColors.primaryLight,
        'invite_accepted' => AppColors.success,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: !notification.isRead
            ? AppColors.primary.withValues(alpha: 0.03)
            : Colors.transparent,
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: context.isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  width: 0.5,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp20,
        vertical: AppSpacing.sp12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(_icon, size: 15, color: _color),
              ),
              if (!notification.isRead)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cTextPrimary,
                    height: 1.4,
                    fontWeight: notification.isRead
                        ? FontWeight.w400
                        : FontWeight.w500,
                  ),
                ),
                if (notification.body != null &&
                    notification.body!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notification.body!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.cTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  timeago.format(notification.createdAt, locale: 'pt_BR'),
                  style: AppTypography.caption(context.cTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
