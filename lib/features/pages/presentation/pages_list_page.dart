import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/skeleton.dart';
import '../../auth/domain/data_providers.dart';

class PagesListPage extends ConsumerWidget {
  const PagesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(pagesProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Column(children: [
        // ── Header ─────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.sp32 : AppSpacing.sp20,
            vertical: AppSpacing.sp20,
          ),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: context.isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.article_rounded,
                  color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: AppSpacing.sp12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Páginas',
                  style: Theme.of(context).textTheme.titleLarge),
              pagesAsync.maybeWhen(
                data: (pages) => Text(
                  '${pages.length} ${pages.length == 1 ? 'documento' : 'documentos'}',
                  style:
                      context.bodySm.copyWith(color: context.cTextMuted),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ]),
            const Spacer(),
            FlowButton(
              label: 'Nova página',
              leadingIcon: Icons.add_rounded,
              onPressed: () => _createPage(context, ref),
            ),
          ]),
        ),

        // ── Content ────────────────────────────────────────
        Expanded(
          child: pagesAsync.when(
            loading: () => const _PagesLoadingSkeleton(),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Erro ao carregar páginas', style: context.bodyMd),
                const SizedBox(height: 8),
                FlowButton(
                  label: 'Tentar novamente',
                  onPressed: () => ref.refresh(pagesProvider),
                  variant: FlowButtonVariant.outline,
                ),
              ]),
            ),
            data: (pages) => pages.isEmpty
                ? _EmptyState(onTap: () => _createPage(context, ref))
                : ListView.builder(
                    padding: EdgeInsets.all(
                        isDesktop ? AppSpacing.sp32 : AppSpacing.sp16),
                    itemCount: pages.length,
                    itemBuilder: (_, i) => _PageCard(
                      page: pages[i],
                      onTap: () =>
                          context.go('/pages/${pages[i].id}'),
                      onDelete: () =>
                          _confirmDelete(context, ref, pages[i]),
                    )
                        .animate()
                        .fadeIn(delay: (i * 50).ms, duration: 300.ms)
                        .slideY(
                          begin: 0.04,
                          delay: (i * 50).ms,
                          duration: 300.ms,
                        ),
                  ),
          ),
        ),
      ]),
    );
  }

  Future<void> _createPage(BuildContext context, WidgetRef ref) async {
    final page = await ref.read(pagesProvider.notifier).createPage();
    if (page != null && context.mounted) {
      context.go('/pages/${page.id}');
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, PageData page) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir página'),
        content: Text(
            'Deseja excluir "${page.title}"?\nTodo o conteúdo será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(pagesProvider.notifier).deletePage(page.id);
    }
  }
}

// ── Empty state ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const Icon(Icons.article_outlined,
              size: 40, color: AppColors.accent),
        ),
        const SizedBox(height: AppSpacing.sp20),
        Text('Nenhuma página ainda',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.cTextPrimary)),
        const SizedBox(height: AppSpacing.sp8),
        Text(
          'Crie documentos, notas e wikis\ncom o editor Notion-style.',
          style: context.bodySm.copyWith(color: context.cTextMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sp24),
        FlowButton(
          label: 'Criar primeira página',
          leadingIcon: Icons.add_rounded,
          onPressed: onTap,
        ),
      ]).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

// ── Page card ────────────────────────────────────────────────
class _PageCard extends StatefulWidget {
  final PageData page;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PageCard({
    required this.page,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_PageCard> createState() => _PageCardState();
}

class _PageCardState extends State<_PageCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final timeStr = _formatDate(page.updatedAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp16, vertical: AppSpacing.sp14),
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
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : (context.isDark
                      ? AppColors.borderDark
                      : AppColors.border),
            ),
          ),
          child: Row(children: [
            // Icon / emoji
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: page.icon != null && page.icon!.isNotEmpty
                    ? Text(page.icon!,
                        style: const TextStyle(fontSize: 18))
                    : const Icon(Icons.article_outlined,
                        size: 18, color: AppColors.accent),
              ),
            ),
            const SizedBox(width: AppSpacing.sp12),

            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.title.isEmpty ? 'Sem título' : page.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.cTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Editado $timeStr',
                    style: context.bodySm
                        .copyWith(color: context.cTextMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Actions
            Visibility(
              visible: _hovering,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded,
                    size: 16, color: context.cTextMuted),
                padding: EdgeInsets.zero,
                onSelected: (v) {
                  if (v == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Excluir',
                          style: TextStyle(color: AppColors.error)),
                    ]),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ── Skeleton loading ─────────────────────────────────────────
class _PagesLoadingSkeleton extends StatelessWidget {
  const _PagesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return Padding(
      padding: EdgeInsets.all(isDesktop ? AppSpacing.sp32 : AppSpacing.sp20),
      child: ListView.separated(
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp10),
        itemBuilder: (_, __) => const SkeletonPageCard(),
      ),
    );
  }
}
