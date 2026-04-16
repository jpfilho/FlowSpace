import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/auth/domain/auth_provider.dart';
import '../../../features/auth/domain/data_providers.dart';
import '../common/flow_tags.dart';
import 'sidebar_models.dart';
import '../../../core/services/realtime_service.dart';

class FlowSidebar extends ConsumerStatefulWidget {
  final bool collapsed;
  final ValueChanged<bool>? onCollapseChanged;

  const FlowSidebar({
    super.key,
    this.collapsed = false,
    this.onCollapseChanged,
  });

  @override
  ConsumerState<FlowSidebar> createState() => _FlowSidebarState();
}

class _FlowSidebarState extends ConsumerState<FlowSidebar> {
  static const _navItems = [
    SidebarNavItem(
      route: AppRoutes.dashboard,
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard_rounded,
      label: 'Dashboard',
    ),
    SidebarNavItem(
      route: AppRoutes.tasks,
      icon: Icons.check_box_outline_blank_rounded,
      activeIcon: Icons.check_box_rounded,
      label: 'Tarefas',
    ),
    SidebarNavItem(
      route: AppRoutes.projects,
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: 'Projetos',
    ),
    SidebarNavItem(
      route: AppRoutes.pages,
      icon: Icons.article_outlined,
      activeIcon: Icons.article_rounded,
      label: 'Páginas',
    ),
    SidebarNavItem(
      route: AppRoutes.databases,
      icon: Icons.table_chart_outlined,
      activeIcon: Icons.table_chart_rounded,
      label: 'Databases',
    ),
    SidebarNavItem(
      route: AppRoutes.calendar,
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Agenda',
    ),
    SidebarNavItem(
      route: AppRoutes.gtd,
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology_rounded,
      label: 'GTD',
    ),
  ];

  static const _bottomItems = [
    SidebarNavItem(
      route: AppRoutes.members,
      icon: Icons.group_outlined,
      activeIcon: Icons.group_rounded,
      label: 'Membros',
    ),
    SidebarNavItem(
      route: AppRoutes.reports,
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      label: 'Reports',
    ),
    SidebarNavItem(
      route: AppRoutes.notifications,
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Notificações',
    ),
    SidebarNavItem(
      route: AppRoutes.settings,
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Configurações',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final location = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(currentUserProvider);
    final collapsed = widget.collapsed;
    final unreadCount = ref.watch(unreadCountProvider);
    // Ensure realtime is active
    ref.watch(realtimeInitProvider);

    final sidebarWidth =
        collapsed ? AppSpacing.sidebarCollapsed : AppSpacing.sidebarWidth;

    return AnimatedContainer(
      duration: AppAnimations.normal,
      curve: Curves.easeOutCubic,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? AppColors.sidebarBgDark : AppColors.sidebarBg,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ── Logo / Header ──────────────────────────────
          _SidebarHeader(collapsed: collapsed, onToggle: widget.onCollapseChanged),

          // ── Search ────────────────────────────────────
          if (!collapsed) _SearchButton(onTap: () => context.go(AppRoutes.search)),

          const SizedBox(height: AppSpacing.sp8),

          // ── Main Nav ──────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? AppSpacing.sp8 : AppSpacing.sp8,
                vertical: AppSpacing.sp4,
              ),
              children: [
                if (!collapsed)
                  _SectionLabel('PRINCIPAL'),
                ..._navItems.map(
                  (item) => _SidebarNavItem(
                    item: item,
                    isActive: location.startsWith(item.route),
                    collapsed: collapsed,
                  ),
                ),
                // ── Árvore de Páginas ────────────────────
                if (!collapsed)
                  _PagesTreeSection(currentLocation: location),
              ],
            ),
          ),

          // ── Bottom Nav ────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? AppSpacing.sp8 : AppSpacing.sp8,
              vertical: AppSpacing.sp4,
            ),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sp8),
                ..._bottomItems.map(
                  (item) {
                    // Attach unread badge to notifications item
                    final badge = item.route == AppRoutes.notifications && unreadCount > 0
                        ? unreadCount
                        : item.badge;
                    return _SidebarNavItem(
                      item: item.copyWith(badge: badge),
                      isActive: location.startsWith(item.route),
                      collapsed: collapsed,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sp8),
                _UserTile(user: user, collapsed: collapsed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────
class _SidebarHeader extends StatelessWidget {
  final bool collapsed;
  final ValueChanged<bool>? onToggle;

  const _SidebarHeader({required this.collapsed, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.topbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12),
        child: Row(
          mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            // Logo icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            ),
            if (!collapsed) ...[
              const SizedBox(width: AppSpacing.sp10),
              Expanded(
                child: Text(
                  'FlowSpace',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onToggle?.call(!collapsed),
                icon: Icon(
                  collapsed
                      ? Icons.keyboard_double_arrow_right_rounded
                      : Icons.keyboard_double_arrow_left_rounded,
                  size: 18,
                  color: context.cTextMuted,
                ),
                tooltip: collapsed ? 'Expandir sidebar' : 'Colapsar sidebar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Search button ──────────────────────────────────────────
class _SearchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12,
        vertical: AppSpacing.sp4,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp10),
          decoration: BoxDecoration(
            color: context.isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: context.isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 15,
                color: context.cTextMuted,
              ),
              const SizedBox(width: AppSpacing.sp8),
              Text(
                'Buscar...',
                style: AppTypography.body(context.cTextMuted)
                    .copyWith(fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '⌘K',
                  style: AppTypography.caption(context.cTextMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sp8,
        AppSpacing.sp12,
        AppSpacing.sp8,
        AppSpacing.sp4,
      ),
      child: Text(
        label,
        style: AppTypography.caption(context.cTextMuted).copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Nav Item ───────────────────────────────────────────────
class _SidebarNavItem extends StatefulWidget {
  final SidebarNavItem item;
  final bool isActive;
  final bool collapsed;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.collapsed,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isActive = widget.isActive;
    final collapsed = widget.collapsed;

    final bgColor = isActive
        ? (isDark
            ? AppColors.sidebarItemActiveDark
            : AppColors.sidebarItemActive)
        : _hovering
            ? (isDark
                ? AppColors.sidebarItemHoverDark
                : AppColors.sidebarItemHover)
            : Colors.transparent;

    final iconColor = isActive ? AppColors.primary : context.cTextMuted;
    final textColor = isActive ? AppColors.primary : context.cTextSecondary;

    Widget tile = AnimatedContainer(
      duration: AppAnimations.fast,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? AppSpacing.sp4 : AppSpacing.sp10,
          vertical: AppSpacing.sp8,
        ),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              isActive ? widget.item.activeIcon : widget.item.icon,
              size: 18,
              color: iconColor,
            ),
            if (!collapsed) ...[
              const SizedBox(width: AppSpacing.sp10),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.item.badge != null)
                FlowBadge(count: widget.item.badge!),
            ],
          ],
        ),
      ),
    );

    if (collapsed) {
      tile = Tooltip(
        message: widget.item.label,
        preferBelow: false,
        child: tile,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.item.route),
        child: tile,
      ),
    );
  }
}

// ── User tile ──────────────────────────────────────────────
class _UserTile extends ConsumerWidget {
  final dynamic user;
  final bool collapsed;

  const _UserTile({required this.user, required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (user?.userMetadata?['name'] as String?) ?? 'Usuário';
    final email = user?.email ?? '';

    if (collapsed) {
      return Tooltip(
        message: name,
        child: FlowAvatar(name: name, size: 36),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp10,
        vertical: AppSpacing.sp8,
      ),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          FlowAvatar(name: name, size: 30),
          const SizedBox(width: AppSpacing.sp10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.cTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email,
                  style: AppTypography.caption(context.cTextMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              size: 16,
              color: context.cTextMuted,
            ),
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
            tooltip: 'Sair',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}

// Re-export for convenience
Color get cTextSecondary => AppColors.textSecondary;

extension _ContextExt on BuildContext {
  Color get cTextSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
}

// ── Árvore de Páginas na Sidebar ────────────────────────────
class _PagesTreeSection extends ConsumerStatefulWidget {
  final String currentLocation;
  const _PagesTreeSection({required this.currentLocation});

  @override
  ConsumerState<_PagesTreeSection> createState() => _PagesTreeSectionState();
}

class _PagesTreeSectionState extends ConsumerState<_PagesTreeSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(pagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Separador + header ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp8, AppSpacing.sp12, AppSpacing.sp4, AppSpacing.sp4),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: AppAnimations.fast,
                    child: Icon(Icons.play_arrow_rounded,
                        size: 12, color: context.cTextMuted),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PÁGINAS',
                    style: AppTypography.caption(context.cTextMuted).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                ]),
              ),
            ),
            // Nova página
            Tooltip(
              message: 'Nova página',
              child: GestureDetector(
                onTap: () async {
                  final page =
                      await ref.read(pagesProvider.notifier).createPage();
                  if (page != null && context.mounted) {
                    context.go('/pages/${page.id}');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.add_rounded,
                      size: 14, color: context.cTextMuted),
                ),
              ),
            ),
          ]),
        ),

        // ── Lista de páginas ─────────────────────────────
        AnimatedCrossFade(
          firstChild: pagesAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                minHeight: 2,
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (pages) {
              if (pages.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sp20, 4, AppSpacing.sp8, 8),
                  child: Text(
                    'Nenhuma página ainda',
                    style: AppTypography.caption(context.cTextMuted)
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                );
              }
              return Column(
                children: pages.map((page) {
                  final isActive = widget.currentLocation == '/pages/${page.id}';
                  return _PageTreeItem(page: page, isActive: isActive);
                }).toList(),
              );
            },
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: AppAnimations.fast,
        ),
      ],
    );
  }
}

// ── Item individual da árvore de páginas ─────────────────────
class _PageTreeItem extends StatefulWidget {
  final PageData page;
  final bool isActive;
  const _PageTreeItem({required this.page, required this.isActive});

  @override
  State<_PageTreeItem> createState() => _PageTreeItemState();
}

class _PageTreeItemState extends State<_PageTreeItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isActive = widget.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/pages/${widget.page.id}'),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp10, vertical: AppSpacing.sp6),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                    ? AppColors.sidebarItemActiveDark
                    : AppColors.sidebarItemActive)
                : _hovering
                    ? (isDark
                        ? AppColors.sidebarItemHoverDark
                        : AppColors.sidebarItemHover)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(children: [
            // Icon/emoji
            SizedBox(
              width: 16,
              child: Center(
                child: widget.page.icon != null && widget.page.icon!.isNotEmpty
                    ? Text(widget.page.icon!,
                        style: const TextStyle(fontSize: 12))
                    : Icon(
                        Icons.article_outlined,
                        size: 13,
                        color: isActive
                            ? AppColors.accent
                            : context.cTextMuted,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sp8),
            Expanded(
              child: Text(
                widget.page.title.isEmpty ? 'Sem título' : widget.page.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.accent : context.cTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
