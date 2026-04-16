import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_tags.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/domain/data_providers.dart';

// ── Search Result Model ───────────────────────────────────────

enum SearchResultType { task, project, page }

class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final SearchResultType type;
  final String? statusOrIcon;

  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.statusOrIcon,
  });
}

// ── Search Provider ───────────────────────────────────────────

final _searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  final query = ref.watch(_searchQueryProvider).trim();
  if (query.length < 2) return [];

  final client = ref.read(supabaseProvider);
  final workspace = ref.watch(currentWorkspaceProvider).valueOrNull;
  final user = ref.watch(currentUserProvider);

  if (workspace == null || user == null) return [];

  try {
    // ── Postgres fulltext search via RPC ──────────────
    final data = await client.rpc('search_all', params: {
      'p_query': query,
      'p_workspace': workspace.id,
      'p_user_id': user.id,
      'p_limit': 30,
    }) as List<dynamic>;

    return data.map((row) {
      final type = switch (row['result_type'] as String) {
        'task' => SearchResultType.task,
        'project' => SearchResultType.project,
        _ => SearchResultType.page,
      };
      return SearchResult(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        subtitle: row['subtitle'] as String?,
        type: type,
        statusOrIcon: row['status_icon'] as String?,
      );
    }).toList();
  } catch (_) {
    // Fallback: client-side search from cached providers
    final tasks = ref.read(tasksProvider).valueOrNull ?? [];
    final projects = ref.read(projectsProvider).valueOrNull ?? [];
    final pages = ref.read(pagesProvider).valueOrNull ?? [];
    final q = query.toLowerCase();
    final results = <SearchResult>[];

    for (final t in tasks) {
      if (t.title.toLowerCase().contains(q)) {
        results.add(SearchResult(
          id: t.id,
          title: t.title,
          subtitle: t.projectName != null ? 'Projeto: ${t.projectName}' : null,
          type: SearchResultType.task,
          statusOrIcon: t.status,
        ));
      }
    }
    for (final p in projects) {
      if (p.name.toLowerCase().contains(q) ||
          (p.description?.toLowerCase().contains(q) ?? false)) {
        results.add(SearchResult(
          id: p.id,
          title: p.name,
          subtitle: p.description,
          type: SearchResultType.project,
          statusOrIcon: p.status,
        ));
      }
    }
    for (final pg in pages) {
      if (pg.title.toLowerCase().contains(q)) {
        results.add(SearchResult(
          id: pg.id,
          title: pg.title,
          subtitle: null,
          type: SearchResultType.page,
          statusOrIcon: pg.icon,
        ));
      }
    }
    return results;
  }
});

// ─────────────────────────────────────────────────────────────
// SearchPage
// ─────────────────────────────────────────────────────────────

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late TextEditingController _ctrl;
  late FocusNode _focusNode;

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
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(_searchQueryProvider.notifier).state = value;
  }

  void _clear() {
    _ctrl.clear();
    ref.read(_searchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Column(
        children: [
          // ── Search Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? AppSpacing.sp32 : AppSpacing.sp20,
              vertical: AppSpacing.sp16,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sp12),
                    Text('Busca global',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp16),
                // Search input
                Container(
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : (context.isDark
                              ? AppColors.borderDark
                              : AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sp16),
                        child: Icon(Icons.search_rounded,
                            size: 20, color: context.cTextMuted),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          onChanged: _onChanged,
                          style: TextStyle(
                            fontSize: 15,
                            color: context.cTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Buscar tarefas, projetos, páginas...',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: context.cTextMuted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sp14),
                          ),
                        ),
                      ),
                      // Keyboard shortcut hint
                      if (query.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _KbdHint(label: '⌘K'),
                        ),
                      // Clear button
                      if (query.isNotEmpty)
                        GestureDetector(
                          onTap: _clear,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: context.cTextMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Results
          Expanded(
            child: query.length < 2
                ? _EmptyPrompt()
                : resultsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                    error: (e, _) => Center(
                      child: Text('Erro: $e', style: context.bodySm),
                    ),
                    data: (results) => results.isEmpty
                        ? _NoResults(query: query)
                        : _ResultsList(
                            results: results,
                            query: query,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Result List ───────────────────────────────────────────────
class _ResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final String query;

  const _ResultsList({required this.results, required this.query});

  @override
  Widget build(BuildContext context) {
    // Group by type
    final tasks =
        results.where((r) => r.type == SearchResultType.task).toList();
    final projects =
        results.where((r) => r.type == SearchResultType.project).toList();
    final pages =
        results.where((r) => r.type == SearchResultType.page).toList();
    final isDesktop = Responsive.isDesktop(context);

    return ListView(
      padding: EdgeInsets.all(isDesktop ? AppSpacing.sp24 : AppSpacing.sp16),
      children: [
        Text(
          '${results.length} resultado${results.length > 1 ? 's' : ''} para "$query"',
          style: context.bodySm.copyWith(color: context.cTextMuted),
        ),
        const SizedBox(height: AppSpacing.sp16),
        if (tasks.isNotEmpty) ...[
          _SectionLabel(label: 'Tarefas', icon: Icons.task_alt_rounded, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sp8),
          ...tasks.asMap().entries.map((e) => _SearchResultTile(
                result: e.value,
                query: query,
              ).animate().fadeIn(delay: (e.key * 30).ms, duration: 250.ms)),
          const SizedBox(height: AppSpacing.sp20),
        ],
        if (projects.isNotEmpty) ...[
          _SectionLabel(label: 'Projetos', icon: Icons.folder_rounded, color: AppColors.accent),
          const SizedBox(height: AppSpacing.sp8),
          ...projects.asMap().entries.map((e) => _SearchResultTile(
                result: e.value,
                query: query,
              ).animate().fadeIn(delay: (e.key * 30).ms, duration: 250.ms)),
          const SizedBox(height: AppSpacing.sp20),
        ],
        if (pages.isNotEmpty) ...[
          _SectionLabel(label: 'Páginas', icon: Icons.article_rounded, color: AppColors.warning),
          const SizedBox(height: AppSpacing.sp8),
          ...pages.asMap().entries.map((e) => _SearchResultTile(
                result: e.value,
                query: query,
              ).animate().fadeIn(delay: (e.key * 30).ms, duration: 250.ms)),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    ]);
  }
}

class _SearchResultTile extends StatefulWidget {
  final SearchResult result;
  final String query;

  const _SearchResultTile({
    required this.result,
    required this.query,
  });

  @override
  State<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<_SearchResultTile> {
  bool _hovering = false;

  void _navigate(BuildContext context) {
    switch (widget.result.type) {
      case SearchResultType.task:
        context.go('/tasks/${widget.result.id}');
      case SearchResultType.project:
        context.go('/projects');
      case SearchResultType.page:
        context.go('/pages/${widget.result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final (icon, color) = switch (result.type) {
      SearchResultType.task => (Icons.task_alt_rounded, AppColors.primary),
      SearchResultType.project => (Icons.folder_rounded, AppColors.accent),
      SearchResultType.page => (Icons.article_rounded, AppColors.warning),
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigate(context),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          margin: const EdgeInsets.only(bottom: AppSpacing.sp6),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp12,
          ),
          decoration: BoxDecoration(
            color: _hovering
                ? (context.isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant)
                : (context.isDark
                    ? AppColors.surfaceDark
                    : AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hovering
                  ? color.withValues(alpha: 0.3)
                  : (context.isDark
                      ? AppColors.borderDark
                      : AppColors.border),
            ),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: result.type == SearchResultType.page &&
                      result.statusOrIcon != null &&
                      result.statusOrIcon!.isNotEmpty
                  ? Center(
                      child: Text(result.statusOrIcon!,
                          style: const TextStyle(fontSize: 16)))
                  : Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(
                    text: result.title,
                    query: widget.query,
                    baseStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.cTextPrimary,
                    ),
                    highlightColor: AppColors.primary,
                  ),
                  if (result.subtitle != null && result.subtitle!.isNotEmpty)
                    Text(
                      result.subtitle!,
                      style: context.bodySm
                          .copyWith(color: context.cTextMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Status tag for tasks
            if (result.type == SearchResultType.task &&
                result.statusOrIcon != null)
              StatusTag(status: result.statusOrIcon!),
            // Project status badge
            if (result.type == SearchResultType.project &&
                result.statusOrIcon != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  result.statusOrIcon!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sp8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: context.cTextMuted),
          ]),
        ),
      ),
    );
  }
}

/// Highlights matching query text in bold/colored
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final Color highlightColor;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final idx = lower.indexOf(lowerQ);

    if (idx == -1) return Text(text, style: baseStyle);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          if (idx > 0)
            TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: baseStyle.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.w700,
              backgroundColor: highlightColor.withValues(alpha: 0.12),
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

// ── Empty / Prompt states ─────────────────────────────────────
class _EmptyPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      ('Tarefas', Icons.task_alt_rounded, AppColors.primary),
      ('Projetos', Icons.folder_rounded, AppColors.accent),
      ('Páginas', Icons.article_rounded, AppColors.warning),
    ];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sp16),
          Text(
            'O que você está procurando?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            'Digite pelo menos 2 caracteres para buscar.',
            style: context.bodySm.copyWith(color: context.cTextMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sp24),
          Wrap(
            spacing: AppSpacing.sp12,
            children: tips.map((t) {
              final (label, icon, color) = t;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp12, vertical: AppSpacing.sp8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500)),
                ]),
              );
            }).toList(),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).scale(
            begin: const Offset(0.95, 0.95),
            duration: 300.ms,
          ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sp16),
          Text(
            'Nada encontrado para "$query"',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            'Tente outros termos ou verifique a ortografia.',
            style: context.bodySm.copyWith(color: context.cTextMuted),
          ),
        ],
      ).animate().fadeIn(duration: 250.ms),
    );
  }
}

class _KbdHint extends StatelessWidget {
  final String label;
  const _KbdHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.borderDark : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.cTextMuted,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
