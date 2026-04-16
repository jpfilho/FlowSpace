import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/flow_tags.dart';
import '../../../shared/widgets/common/skeleton.dart';
import '../../../features/auth/domain/data_providers.dart';
import 'edit_project_sheet.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Column(
        children: [
          // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp24,
              vertical: AppSpacing.sp16,
            ),
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: context.isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projetos',
                        style: Theme.of(context).textTheme.headlineSmall),
                    projectsAsync.when(
                      data: (list) => Text(
                        '${list.length} projeto${list.length == 1 ? '' : 's'}',
                        style: context.bodySm,
                      ),
                      loading: () => Text('Carregando...', style: context.bodySm),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const Spacer(),
                FlowButton(
                  label: 'Novo projeto',
                  onPressed: () => _showCreateProject(context, ref),
                  leadingIcon: Icons.add_rounded,
                  size: FlowButtonSize.sm,
                ),
              ],
            ),
          ),

          // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: projectsAsync.when(
              loading: () => const _ProjectsLoadingSkeleton(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.sp12),
                    Text('Erro ao carregar projetos', style: context.bodyMd),
                    const SizedBox(height: AppSpacing.sp8),
                    Text(e.toString(),
                        style: context.bodySm,
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sp16),
                    FlowButton(
                      label: 'Tentar novamente',
                      onPressed: () =>
                          ref.refresh(projectsProvider),
                    ),
                  ],
                ),
              ),
              data: (projects) => projects.isEmpty
                  ? _EmptyState(onCreateTap: () => _showCreateProject(context, ref))
                  : GridView.builder(
                      padding: EdgeInsets.all(
                        isDesktop ? AppSpacing.sp24 : AppSpacing.sp16,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 3 : 2,
                        mainAxisSpacing: AppSpacing.sp16,
                        crossAxisSpacing: AppSpacing.sp16,
                        childAspectRatio: isDesktop ? 1.6 : 1.3,
                      ),
                      itemCount: projects.length,
                      itemBuilder: (_, i) => _ProjectCard(
                        project: projects[i],
                        onDelete: () => _confirmDelete(context, ref, projects[i]),
                        onEdit: () => _showEditProject(context, projects[i]),
                        onTap: () => context.go('/projects/${projects[i].id}'),
                      )
                          .animate()
                          .fadeIn(delay: (i * 60).ms, duration: 350.ms)
                          .scale(
                            begin: const Offset(0.97, 0.97),
                            delay: (i * 60).ms,
                          ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Criar Projeto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showCreateProject(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String status = 'active';
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Novo projeto'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome do projeto *',
                    hintText: 'Ex: FlowSpace MVP',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status', style: TextStyle(
                          fontSize: 12, color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8)),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Ativo')),
                            DropdownMenuItem(value: 'in_progress', child: Text('Em progresso')),
                            DropdownMenuItem(value: 'review', child: Text('Em revisão')),
                            DropdownMenuItem(value: 'completed', child: Text('Concluído')),
                          ],
                          onChanged: (v) => setState(() => status = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prioridade', style: TextStyle(
                          fontSize: 12, color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: priority,
                          decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8)),
                          items: const [
                            DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                            DropdownMenuItem(value: 'high', child: Text('Alta')),
                            DropdownMenuItem(value: 'medium', child: Text('Média')),
                            DropdownMenuItem(value: 'low', child: Text('Baixa')),
                          ],
                          onChanged: (v) => setState(() => priority = v!),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final err = await ref
                    .read(projectsProvider.notifier)
                    .createProject(
                      name: nameCtrl.text,
                      description: descCtrl.text,
                      status: status,
                      priority: priority,
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Projeto criado com sucesso!'),
                        ]),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Criar projeto'),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Detalhes do Projeto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // -- Editar Projeto
  void _showEditProject(BuildContext context, ProjectData project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProjectSheet(project: project),
    );
  }

  // â”€â”€ Confirmar ExclusÃ£o â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ProjectData project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir projeto'),
        content: Text(
          'Deseja excluir "${project.name}"?\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final err = await ref
          .read(projectsProvider.notifier)
          .deleteProject(project.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? 'Projeto excluído'),
          backgroundColor: err != null ? AppColors.error : AppColors.success,
        ));
      }
    }
  }
}

// ——— Project Card ————————————————————————————————————————
class _ProjectCard extends StatefulWidget {
  final ProjectData project;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovering = false;

  Color get _progressColor {
    final p = widget.project.progress;
    if (p > 70) return AppColors.success;
    if (p > 40) return AppColors.primary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(AppSpacing.sp20),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hovering
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : (context.isDark ? AppColors.borderDark : AppColors.border),
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.folder_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const Spacer(),
                  StatusTag(status: project.status),
                  const SizedBox(width: 6),
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
                        if (v == 'edit') widget.onEdit();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Editar projeto'),
                          ]),
                        ),
                        const PopupMenuDivider(),
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
                ],
              ),

              const SizedBox(height: AppSpacing.sp12),

              // Name
              Text(
                project.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.cTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),

              const SizedBox(height: AppSpacing.sp4),

              // Description
              if (project.description != null &&
                  project.description!.isNotEmpty)
                Text(
                  project.description!,
                  style: context.bodySm.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),

              const Spacer(),

              // Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${project.progress}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _progressColor,
                        ),
                      ),
                      Text(
                        project.memberCount > 0
                            ? '${project.memberCount} membro${project.memberCount == 1 ? '' : 's'}'
                            : 'Sem membros',
                        style: context.labelMd,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: _progressColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(_progressColor),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Empty State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sp20),
          Text('Nenhum projeto ainda',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            'Crie seu primeiro projeto para organizar seu trabalho',
            style: context.bodySm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sp24),
          FlowButton(
            label: 'Criar primeiro projeto',
            onPressed: onCreateTap,
            leadingIcon: Icons.add_rounded,
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, duration: 400.ms),
    );
  }
}


// ── Skeleton loading ─────────────────────────────────────────
class _ProjectsLoadingSkeleton extends StatelessWidget {
  const _ProjectsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context) || Responsive.isTablet(context);
    final count = 6;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? AppSpacing.sp24 : AppSpacing.sp16),
      child: isDesktop
          ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sp16,
                mainAxisSpacing: AppSpacing.sp16,
                childAspectRatio: 1.8,
              ),
              itemCount: count,
              itemBuilder: (_, __) => const SkeletonProjectCard(),
            )
          : ListView.separated(
              itemCount: count,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp12),
              itemBuilder: (_, __) => const SkeletonProjectCard(),
            ),
    );
  }
}
