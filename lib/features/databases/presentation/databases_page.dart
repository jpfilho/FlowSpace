import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/flow_states.dart';
import '../domain/database_providers.dart';

class DatabasesPage extends ConsumerWidget {
  const DatabasesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbsAsync = ref.watch(databasesProvider);

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        title: const Text('Bancos de Dados'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FlowButton(
              onPressed: () => _showCreateDbDialog(context, ref),
              label: 'Novo Banco',
              leadingIcon: Icons.add_rounded,
            ),
          )
        ],
      ),
      body: dbsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (dbs) {
          if (dbs.isEmpty) {
            return FlowEmptyState(
              icon: Icons.table_chart_rounded,
              title: 'Nenhum Banco de Dados',
              subtitle:
                  'Crie bancos de dados para rastrear qualquer coisa. Clientes, inventário, ideias, o céu é o limite.',
              actionLabel: 'Criar Banco',
              onAction: () => _showCreateDbDialog(context, ref),
            ).animate().fadeIn(duration: 400.ms);
          }

          final isDesktop = Responsive.isDesktop(context);
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.sp24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (Responsive.isTablet(context) ? 3 : 2),
              crossAxisSpacing: AppSpacing.sp16,
              mainAxisSpacing: AppSpacing.sp16,
              childAspectRatio: 1.5,
            ),
            itemCount: dbs.length,
            itemBuilder: (context, index) {
              final db = dbs[index];
              return _DatabaseCard(
                db: db,
                onTap: () => context.go('/databases/${db.id}'),
              ).animate().fadeIn(delay: (50 * index).ms, duration: 400.ms);
            },
          );
        },
      ),
    );
  }

  void _showCreateDbDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => const _CreateDbDialog(),
    );
  }
}

class _DatabaseCard extends StatelessWidget {
  final DatabaseData db;
  final VoidCallback onTap;

  const _DatabaseCard({required this.db, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color parsedColor;
    try {
      parsedColor = Color(int.parse(db.color.replaceFirst('#', ''), radix: 16) | 0xFF000000);
    } catch (_) {
      parsedColor = AppColors.primary;
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        hoverColor: parsedColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sp16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: parsedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.table_chart_rounded, color: parsedColor),
              ),
              const Spacer(),
              Text(
                db.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (db.description != null && db.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  db.description!,
                  style: context.bodySm.copyWith(color: context.cTextMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateDbDialog extends ConsumerStatefulWidget {
  const _CreateDbDialog();

  @override
  ConsumerState<_CreateDbDialog> createState() => _CreateDbDialogState();
}

class _CreateDbDialogState extends ConsumerState<_CreateDbDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _creating = true);
    try {
      final newDb = await ref
          .read(databasesProvider.notifier)
          .create(name, description: _descCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        context.go('/databases/${newDb.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Banco de Dados'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome do Banco', style: context.labelMd),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ex: CRM de Clientes, Content Calendar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Descrição (opcional)', style: context.labelMd),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Qual o propósito deste banco de dados?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FlowButton(
          onPressed: _creating ? () {} : _create,
          label: _creating ? 'Criando...' : 'Criar Banco',
        ),
      ],
    );
  }
}
