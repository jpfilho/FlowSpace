import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/auth/domain/auth_provider.dart';
import '../../../features/auth/domain/data_providers.dart';
import '../../../core/services/realtime_service.dart';
import 'flow_sidebar.dart';
import '../common/command_palette.dart';

final _sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Main application shell with responsive sidebar and topbar
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final isMobile = Responsive.isMobile(context);
    final isCollapsed = ref.watch(_sidebarCollapsedProvider);

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          () => showCommandPalette(context),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
          () => showCommandPalette(context),
    };

    if (isMobile) {
      return CallbackShortcuts(
        bindings: shortcuts,
        child: _MobileShell(child: child),
      );
    }

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Scaffold(
        backgroundColor:
            context.isDark ? AppColors.backgroundDark : AppColors.background,
        body: Row(
          children: [
            // Sidebar
            FlowSidebar(
              collapsed: isTablet || isCollapsed,
              onCollapseChanged: isDesktop
                  ? (v) =>
                      ref.read(_sidebarCollapsedProvider.notifier).state = v
                  : null,
            ),

            // Main content
            Expanded(
              child: Column(
                children: [
                  _FlowTopBar(
                    showMenuButton: false,
                    sidebarCollapsed: isTablet || isCollapsed,
                  ),
                  Expanded(
                    child: child,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile shell with bottom navigation
class _MobileShell extends ConsumerWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith(AppRoutes.tasks)) currentIndex = 1;
    if (location.startsWith(AppRoutes.projects)) currentIndex = 2;
    if (location.startsWith(AppRoutes.gtd)) currentIndex = 3;
    if (location.startsWith(AppRoutes.settings)) currentIndex = 4;

    return Scaffold(
      backgroundColor:
          context.isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: _FlowTopBar(showMenuButton: true),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor:
            context.isDark ? AppColors.surfaceDark : AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        onDestinationSelected: (i) {
          final routes = [
            AppRoutes.dashboard,
            AppRoutes.tasks,
            AppRoutes.projects,
            AppRoutes.gtd,
            AppRoutes.settings,
          ];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outline_blank_rounded),
            selectedIcon: Icon(Icons.check_box_rounded),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Projetos',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology_rounded),
            label: 'GTD',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}

/// Top bar widget
class _FlowTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showMenuButton;
  final bool sidebarCollapsed;

  const _FlowTopBar({
    this.showMenuButton = false,
    this.sidebarCollapsed = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.topbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final user = ref.watch(currentUserProvider);
    final name = (user?.userMetadata?['name'] as String?) ?? 'Usuário';

    return Container(
      height: AppSpacing.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                color: context.cTextMuted,
              ),
            ),

          // Breadcrumb / Page title
          _PageTitle(),

          const Spacer(),

          // Quick actions
          _TopbarActions(name: name),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  static final Map<String, (IconData, String)> _routeMeta = {
    AppRoutes.dashboard:     (Icons.space_dashboard_rounded,   'Início'),
    AppRoutes.tasks:         (Icons.check_box_rounded,          'Tarefas'),
    AppRoutes.projects:      (Icons.folder_rounded,             'Projetos'),
    AppRoutes.calendar:      (Icons.calendar_month_rounded,     'Calendário'),
    AppRoutes.gtd:           (Icons.psychology_rounded,         'GTD'),
    AppRoutes.pages:         (Icons.article_rounded,            'Páginas'),
    AppRoutes.settings:      (Icons.settings_rounded,           'Configurações'),
    AppRoutes.notifications: (Icons.notifications_rounded,      'Notificações'),
    AppRoutes.reports:       (Icons.analytics_rounded,          'Reports'),
    AppRoutes.search:        (Icons.search_rounded,             'Busca'),
  };

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    // Match the most specific route first
    MapEntry<String, (IconData, String)>? match;
    for (final entry in _routeMeta.entries) {
      if (location.startsWith(entry.key)) {
        if (match == null || entry.key.length > match.key.length) {
          match = entry;
        }
      }
    }

    // Special cases for sub-routes
    String label = match?.value.$2 ?? '';
    IconData? icon = match?.value.$1;

    if (location.startsWith('/tasks/')) {
      label = 'Tarefa';
      icon = Icons.task_alt_rounded;
    } else if (location.startsWith('/projects/') && location.length > '/projects/'.length) {
      label = 'Projeto';
      icon = Icons.folder_open_rounded;
    } else if (location.startsWith('/pages/') && location.length > '/pages/'.length) {
      label = 'Editor';
      icon = Icons.edit_note_rounded;
    }

    if (icon == null || label.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: context.cTextMuted),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.cTextMuted,
        ),
      ),
    ]);
  }
}

class _TopbarActions extends ConsumerWidget {
  final String name;
  const _TopbarActions({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // ── Presence Avatars ─────────────────────────────────────────
        Builder(builder: (ctx) {
          final onlineUsers = ref.watch(onlineUsersProvider);
          if (onlineUsers.isEmpty) return const SizedBox.shrink();

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...onlineUsers.take(3).map((u) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: '${u.name} (Online)',
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        u.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }),
              if (onlineUsers.length > 3)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: ctx.isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                    child: Text(
                      '+${onlineUsers.length - 3}',
                      style: TextStyle(fontSize: 9, color: ctx.cTextMuted, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                 const SizedBox(width: 4),

              Container(
                width: 1,
                height: 16,
                color: ctx.isDark ? AppColors.borderDark : AppColors.border,
                margin: const EdgeInsets.only(right: 8),
              ),
            ],
          );
        }),

        // Search — desktop/tablet: Command Palette; mobile: Search Page
        if (!Responsive.isMobile(context))
          GestureDetector(
            onTap: () => showCommandPalette(context),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.sp8),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: context.isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_rounded,
                      size: 14, color: context.cTextMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Buscar...',
                    style: TextStyle(
                        fontSize: 12, color: context.cTextMuted),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ctrl K',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.cTextMuted,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          )
        else
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: context.cTextMuted,
              size: 20,
            ),
            onPressed: () => context.go(AppRoutes.search),
          ),

        // Notifications with unread badge
        Builder(builder: (_) {
          final unread = ref.watch(unreadCountProvider);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: context.cTextMuted,
                  size: 20,
                ),
                onPressed: () => context.go(AppRoutes.notifications),
                tooltip: 'Notificações',
              ),
              if (unread > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                        minWidth: 16, minHeight: 14),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),

        const SizedBox(width: AppSpacing.sp4),

        // Theme toggle — cycles dark → light → system
        Builder(builder: (ctx) {
          final themeMode = ref.watch(themeModeProvider);
          final (icon, tip) = switch (themeMode) {
            ThemeMode.dark   => (Icons.light_mode_outlined,   'Modo claro'),
            ThemeMode.light  => (Icons.dark_mode_outlined,    'Modo escuro'),
            ThemeMode.system => (Icons.brightness_auto_outlined, 'Modo sistema'),
          };
          return IconButton(
            icon: Icon(icon, color: context.cTextMuted, size: 20),
            tooltip: tip,
            onPressed: () {
              final next = switch (themeMode) {
                ThemeMode.system => ThemeMode.dark,
                ThemeMode.dark   => ThemeMode.light,
                ThemeMode.light  => ThemeMode.system,
              };
              ref.read(themeModeProvider.notifier).setTheme(next);
            },
          );
        }),
      ],
    );

  }
}
