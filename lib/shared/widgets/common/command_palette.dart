import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../features/auth/domain/data_providers.dart';
import '../common/flow_tags.dart';

// ── Provider ─────────────────────────────────────────────────

final _paletteQueryProvider = StateProvider<String>((ref) => '');
final _paletteIndexProvider = StateProvider<int>((ref) => 0);

enum _ResultType { task, project, page, quickAction }

class _PaletteResult {
  final String id;
  final String title;
  final String? subtitle;
  final _ResultType type;
  final String? badge;
  final IconData icon;
  final Color color;

  const _PaletteResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.badge,
    required this.icon,
    required this.color,
  });
}

final _paletteResultsProvider =
    Provider.autoDispose<List<_PaletteResult>>((ref) {
  final query = ref.watch(_paletteQueryProvider).trim().toLowerCase();
  final results = <_PaletteResult>[];

  // Quick actions (always shown or when query matches)
  final quickActions = [
    _PaletteResult(
      id: 'qa_tasks',
      title: 'Ir para Tarefas',
      type: _ResultType.quickAction,
      icon: Icons.check_box_rounded,
      color: AppColors.primary,
      badge: '→',
    ),
    _PaletteResult(
      id: 'qa_projects',
      title: 'Ir para Projetos',
      type: _ResultType.quickAction,
      icon: Icons.folder_rounded,
      color: AppColors.accent,
      badge: '→',
    ),
    _PaletteResult(
      id: 'qa_calendar',
      title: 'Ir para Calendário',
      type: _ResultType.quickAction,
      icon: Icons.calendar_month_rounded,
      color: AppColors.success,
      badge: '→',
    ),
    _PaletteResult(
      id: 'qa_pages',
      title: 'Ir para Páginas',
      type: _ResultType.quickAction,
      icon: Icons.article_rounded,
      color: AppColors.warning,
      badge: '→',
    ),
    _PaletteResult(
      id: 'qa_settings',
      title: 'Ir para Configurações',
      type: _ResultType.quickAction,
      icon: Icons.settings_rounded,
      color: AppColors.textMuted,
      badge: '→',
    ),
  ];

  if (query.length < 2) {
    // Show quick actions when empty
    results.addAll(quickActions
        .where((a) => a.title.toLowerCase().contains(query) || query.isEmpty));
    return results;
  }

  // Filter quick actions
  final filteredQA =
      quickActions.where((a) => a.title.toLowerCase().contains(query));
  results.addAll(filteredQA);

  // Tasks
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  for (final t in tasks) {
    if (t.title.toLowerCase().contains(query)) {
      results.add(_PaletteResult(
        id: 'task_${t.id}',
        title: t.title,
        subtitle: t.projectName != null ? '📁 ${t.projectName}' : null,
        type: _ResultType.task,
        badge: t.status,
        icon: Icons.task_alt_rounded,
        color: AppColors.primary,
      ));
    }
  }

  // Projects
  final projects = ref.watch(projectsProvider).valueOrNull ?? [];
  for (final p in projects) {
    if (p.name.toLowerCase().contains(query) ||
        (p.description?.toLowerCase().contains(query) ?? false)) {
      results.add(_PaletteResult(
        id: 'project_${p.id}',
        title: p.name,
        subtitle: p.description,
        type: _ResultType.project,
        badge: p.status,
        icon: Icons.folder_rounded,
        color: AppColors.accent,
      ));
    }
  }

  // Pages
  final pages = ref.watch(pagesProvider).valueOrNull ?? [];
  for (final pg in pages) {
    if (pg.title.toLowerCase().contains(query)) {
      results.add(_PaletteResult(
        id: 'page_${pg.id}',
        title: pg.title,
        subtitle: pg.icon,
        type: _ResultType.page,
        icon: Icons.article_rounded,
        color: AppColors.warning,
      ));
    }
  }

  return results;
});

// ── CommandPalette Widget ────────────────────────────────────

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  late TextEditingController _ctrl;
  late FocusNode _focusNode;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _navigate(_PaletteResult result) {
    Navigator.of(context).pop();
    switch (result.type) {
      case _ResultType.quickAction:
        final route = switch (result.id) {
          'qa_tasks' => '/tasks',
          'qa_projects' => '/projects',
          'qa_calendar' => '/calendar',
          'qa_pages' => '/pages',
          'qa_settings' => '/settings',
          _ => '/dashboard',
        };
        context.go(route);
      case _ResultType.task:
        context.go('/tasks/${result.id.replaceFirst('task_', '')}');
      case _ResultType.project:
        context.go('/projects/${result.id.replaceFirst('project_', '')}');
      case _ResultType.page:
        context.go('/pages/${result.id.replaceFirst('page_', '')}');
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final results = ref.read(_paletteResultsProvider);
    final current = ref.read(_paletteIndexProvider);

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      ref.read(_paletteIndexProvider.notifier).state =
          (current + 1).clamp(0, results.length - 1);
      _scrollToIndex(ref.read(_paletteIndexProvider));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      ref.read(_paletteIndexProvider.notifier).state =
          (current - 1).clamp(0, results.length - 1);
      _scrollToIndex(ref.read(_paletteIndexProvider));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (results.isNotEmpty && current < results.length) {
        _navigate(results[current]);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scrollToIndex(int i) {
    const itemH = 56.0;
    final offset = i * itemH;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
        duration: 120.ms,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(_paletteResultsProvider);
    final selectedIndex = ref.watch(_paletteIndexProvider);
    final query = ref.watch(_paletteQueryProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 200 : 20,
        vertical: isDesktop ? 120 : 60,
      ),
      child: Focus(
        onKeyEvent: _handleKey,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: context.isDark ? AppColors.borderDark : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Search Input
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp16, vertical: AppSpacing.sp4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: context.isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                    ),
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded,
                      size: 20, color: context.cTextMuted),
                  const SizedBox(width: AppSpacing.sp12),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.cTextPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar tarefas, projetos, páginas...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: context.cTextMuted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) {
                        ref.read(_paletteQueryProvider.notifier).state = v;
                        ref.read(_paletteIndexProvider.notifier).state = 0;
                      },
                    ),
                  ),
                  if (query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        ref.read(_paletteQueryProvider.notifier).state = '';
                        ref.read(_paletteIndexProvider.notifier).state = 0;
                        _focusNode.requestFocus();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: context.cTextMuted),
                      ),
                    )
                  else
                    _KbdChip(label: 'ESC'),
                ]),
              ),

              // ── Results
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.sp32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.search_off_rounded,
                              size: 36, color: context.cTextMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum resultado para "$query"',
                            style: TextStyle(
                                fontSize: 14, color: context.cTextMuted),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sp6),
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final r = results[i];
                          final isSelected = i == selectedIndex;
                          return _PaletteItem(
                            result: r,
                            isSelected: isSelected,
                            query: query,
                            onTap: () => _navigate(r),
                            onHover: (v) {
                              if (v) {
                                ref
                                    .read(_paletteIndexProvider.notifier)
                                    .state = i;
                              }
                            },
                          );
                        },
                      ),
              ),

              // ── Footer hints
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp16, vertical: AppSpacing.sp10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: context.isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                    ),
                  ),
                ),
                child: Row(children: [
                  _KbdChip(label: '↑↓'),
                  const SizedBox(width: 4),
                  Text(' Navegar',
                      style: TextStyle(
                          fontSize: 11, color: context.cTextMuted)),
                  const SizedBox(width: 12),
                  _KbdChip(label: '↵'),
                  const SizedBox(width: 4),
                  Text(' Abrir',
                      style: TextStyle(
                          fontSize: 11, color: context.cTextMuted)),
                  const Spacer(),
                  Text(
                    '${results.length} resultado${results.length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 11, color: context.cTextMuted),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 150.ms).scale(
          begin: const Offset(0.97, 0.97),
          duration: 150.ms,
          curve: Curves.easeOut,
        );
  }
}

class _PaletteItem extends StatelessWidget {
  final _PaletteResult result;
  final bool isSelected;
  final String query;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _PaletteItem({
    required this.result,
    required this.isSelected,
    required this.query,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp8, vertical: 1),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp12, vertical: AppSpacing.sp10),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected
                  ? result.color.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: result.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: result.type == _ResultType.page &&
                      result.subtitle != null &&
                      result.subtitle!.length <= 2
                  ? Center(
                      child: Text(result.subtitle!,
                          style: const TextStyle(fontSize: 14)))
                  : Icon(result.icon, size: 16, color: result.color),
            ),
            const SizedBox(width: AppSpacing.sp12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HighlightText(
                    text: result.title,
                    query: query,
                    color: result.color,
                    baseStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.cTextPrimary,
                    ),
                  ),
                  if (result.subtitle != null &&
                      result.type != _ResultType.page)
                    Text(
                      result.subtitle!,
                      style: TextStyle(
                          fontSize: 11, color: context.cTextMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Badge
            if (result.type == _ResultType.task && result.badge != null)
              StatusTag(status: result.badge!),
            if (result.type == _ResultType.quickAction)
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: context.cTextMuted),
          ]),
        ),
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final Color color;
  final TextStyle baseStyle;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.color,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.length < 2) return Text(text, style: baseStyle, maxLines: 1);
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx == -1) return Text(text, style: baseStyle, maxLines: 1);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: [
        if (idx > 0) TextSpan(text: text.substring(0, idx)),
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: baseStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ),
        if (idx + query.length < text.length)
          TextSpan(text: text.substring(idx + query.length)),
      ]),
    );
  }
}

class _KbdChip extends StatelessWidget {
  final String label;
  const _KbdChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceVariantDark : AppColors.border,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: context.cTextMuted,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ── Helper to open Command Palette ───────────────────────────

void showCommandPalette(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => const CommandPalette(),
  );
}
