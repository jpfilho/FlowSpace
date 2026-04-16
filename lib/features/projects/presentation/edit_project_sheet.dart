import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../auth/domain/data_providers.dart';

/// Bottom sheet para edição completa de um projeto existente.
class EditProjectSheet extends ConsumerStatefulWidget {
  final ProjectData project;
  const EditProjectSheet({super.key, required this.project});

  @override
  ConsumerState<EditProjectSheet> createState() => _EditProjectSheetState();
}

class _EditProjectSheetState extends ConsumerState<EditProjectSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _status;
  late String _priority;
  late int _progress;
  bool _loading = false;
  String? _error;

  static const _statuses = [
    ('active', 'Ativo', AppColors.success),
    ('in_progress', 'Em progresso', AppColors.primary),
    ('review', 'Em revisão', AppColors.warning),
    ('completed', 'Concluído', AppColors.statusDone),
    ('archived', 'Arquivado', AppColors.textMuted),
  ];

  static const _priorities = [
    ('urgent', 'Urgente', AppColors.error),
    ('high', 'Alta', AppColors.warning),
    ('medium', 'Média', AppColors.primary),
    ('low', 'Baixa', AppColors.textMuted),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.name);
    _descCtrl =
        TextEditingController(text: widget.project.description ?? '');
    _status = widget.project.status;
    _priority = widget.project.priority;
    _progress = widget.project.progress;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'O nome do projeto é obrigatório');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final descChanged = _descCtrl.text.trim() != (widget.project.description ?? '');
    final clearDesc = descChanged && _descCtrl.text.trim().isEmpty;

    final err = await ref.read(projectsProvider.notifier).updateProject(
          projectId: widget.project.id,
          name: _nameCtrl.text,
          description:
              descChanged && !clearDesc ? _descCtrl.text : null,
          status: _status,
          priority: _priority,
          progress: _progress,
          clearDescription: clearDesc,
        );

    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        setState(() => _error = err);
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Projeto atualizado!'),
          ]),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.sp24,
        right: AppSpacing.sp24,
        top: AppSpacing.sp24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sp24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      context.isDark ? AppColors.borderDark : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // Header
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.folder_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Text('Editar projeto',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                color: context.cTextMuted,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),
            const SizedBox(height: AppSpacing.sp20),

            // ── Nome ─────────────────────────────────────────
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nome do projeto',
                errorText: _error,
                prefixIcon:
                    const Icon(Icons.folder_outlined, size: 18),
              ),
              style:
                  TextStyle(fontSize: 15, color: context.cTextPrimary),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: AppSpacing.sp16),

            // ── Descrição ────────────────────────────────────
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes_rounded, size: 18),
                ),
              ),
              style:
                  TextStyle(fontSize: 14, color: context.cTextPrimary),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // ── Status ───────────────────────────────────────
            Text('Status', style: context.labelMd),
            const SizedBox(height: AppSpacing.sp8),
            Wrap(
              spacing: AppSpacing.sp8,
              runSpacing: AppSpacing.sp6,
              children: _statuses.map((s) {
                final (value, label, color) = s;
                final sel = _status == value;
                return _Chip(
                  label: label,
                  color: color,
                  isSelected: sel,
                  onTap: () => setState(() => _status = value),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // ── Prioridade ───────────────────────────────────
            Text('Prioridade', style: context.labelMd),
            const SizedBox(height: AppSpacing.sp8),
            Wrap(
              spacing: AppSpacing.sp8,
              runSpacing: AppSpacing.sp6,
              children: _priorities.map((p) {
                final (value, label, color) = p;
                final sel = _priority == value;
                return _Chip(
                  label: label,
                  color: color,
                  isSelected: sel,
                  onTap: () => setState(() => _priority = value),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // ── Progresso ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progresso', style: context.labelMd),
                Text(
                  '$_progress%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _progress > 70
                        ? AppColors.success
                        : _progress > 40
                            ? AppColors.primary
                            : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
                trackHeight: 6,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: _progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20, // steps of 5%
                label: '$_progress%',
                onChanged: (v) => setState(() => _progress = v.round()),
              ),
            ),
            // Progress quick-select buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [0, 25, 50, 75, 100].map((v) {
                final sel = _progress == v;
                return InkWell(
                  onTap: () => setState(() => _progress = v),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : (context.isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                      ),
                    ),
                    child: Text(
                      '$v%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel
                            ? AppColors.primary
                            : context.cTextMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sp28),

            // ── Botões ───────────────────────────────────────
            Row(children: [
              Expanded(
                child: FlowButton(
                  label: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                  variant: FlowButtonVariant.outline,
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: FlowButton(
                  label: _loading ? 'Salvando...' : 'Salvar projeto',
                  onPressed: _loading ? null : _save,
                  leadingIcon: _loading ? null : Icons.save_rounded,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Chip reutilizável ────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12, vertical: AppSpacing.sp6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? color
                : (context.isDark
                    ? AppColors.borderDark
                    : AppColors.border),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : context.cTextMuted,
          ),
        ),
      ),
    );
  }
}
