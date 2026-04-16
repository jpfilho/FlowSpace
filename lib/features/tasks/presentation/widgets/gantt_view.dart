import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/domain/data_providers.dart';
import 'package:intl/intl.dart';

class GanttView extends ConsumerStatefulWidget {
  final List<TaskData> tasks;
  const GanttView({super.key, required this.tasks});

  @override
  ConsumerState<GanttView> createState() => _GanttViewState();
}

class _GanttViewState extends ConsumerState<GanttView> {
  final ScrollController _horizontalHeaderCtrl = ScrollController();
  final ScrollController _horizontalBodyCtrl = ScrollController();
  final ScrollController _verticalCtrl = ScrollController();
  
  bool _isScrollingHeader = false;
  bool _isScrollingBody = false;

  late DateTime _startDate;
  late DateTime _endDate;
  final double _dayWidth = 40.0;
  final double _leftPanelWidth = 260.0;

  List<TaskData> _ganttTasks = [];
  List<TaskData> _unallocatedTasks = [];

  @override
  void initState() {
    super.initState();
    _horizontalHeaderCtrl.addListener(() {
      if (!_isScrollingBody && _horizontalHeaderCtrl.hasClients && _horizontalBodyCtrl.hasClients) {
        _isScrollingHeader = true;
        _horizontalBodyCtrl.jumpTo(_horizontalHeaderCtrl.offset);
        _isScrollingHeader = false;
      }
    });

    _horizontalBodyCtrl.addListener(() {
      if (!_isScrollingHeader && _horizontalHeaderCtrl.hasClients && _horizontalBodyCtrl.hasClients) {
        _isScrollingBody = true;
        _horizontalHeaderCtrl.jumpTo(_horizontalBodyCtrl.offset);
        _isScrollingBody = false;
      }
    });

    _processTasks();
  }

  @override
  void didUpdateWidget(covariant GanttView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _processTasks();
    }
  }

  void _processTasks() {
    _ganttTasks = [];
    _unallocatedTasks = [];

    DateTime? minDate;
    DateTime? maxDate;

    for (var t in widget.tasks) {
      if (t.startDate == null && t.dueDate == null) {
        _unallocatedTasks.add(t);
      } else {
        _ganttTasks.add(t);
        final s = t.startDate ?? t.dueDate!;
        final e = t.dueDate ?? t.startDate!;
        if (minDate == null || s.isBefore(minDate)) minDate = s;
        if (maxDate == null || e.isAfter(maxDate)) maxDate = e;
      }
    }

    final today = DateTime.now();
    _startDate = (minDate ?? today).subtract(const Duration(days: 7));
    _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    
    _endDate = (maxDate ?? today).add(const Duration(days: 30));
    _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalHeaderCtrl.hasClients) {
        final daysFromStartToToday = today.difference(_startDate).inDays;
        final targetOffset = (daysFromStartToToday * _dayWidth) - (MediaQuery.of(context).size.width / 2) + _leftPanelWidth;
        _horizontalHeaderCtrl.jumpTo(targetOffset.clamp(0.0, _horizontalHeaderCtrl.position.maxScrollExtent));
      }
    });
  }

  @override
  void dispose() {
    _horizontalHeaderCtrl.dispose();
    _horizontalBodyCtrl.dispose();
    _verticalCtrl.dispose();
    super.dispose();
  }

  int get _totalDays => _endDate.difference(_startDate).inDays + 1;

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_timeline_outlined, size: 48, color: context.cTextMuted),
            const SizedBox(height: AppSpacing.sp16),
            Text('Nenhuma tarefa para exibir no Gantt', style: context.bodyMd),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.cBorder)),
            color: context.cBackground,
          ),
          child: Row(
            children: [
              // Fixed left corner
              Container(
                width: _leftPanelWidth,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: context.cBorder)),
                  color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
                ),
                child: Text('Tarefas', style: context.labelMd),
              ),
              // Scrollable days
              Expanded(
                child: ListView.builder(
                  controller: _horizontalHeaderCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _totalDays,
                  itemBuilder: (ctx, i) {
                    final day = _startDate.add(Duration(days: i));
                    final isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;
                    return Container(
                      width: _dayWidth,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: context.cBorder.withValues(alpha: 0.5))),
                        color: isToday ? AppColors.primary.withValues(alpha: 0.1) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('MMM').format(day).toUpperCase(), style: TextStyle(fontSize: 9, color: context.cTextMuted)),
                          Text('${day.day}', style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? AppColors.primary : context.cTextPrimary)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Body
        Expanded(
          child: ListView.builder(
            controller: _verticalCtrl,
            itemCount: _ganttTasks.length + (_unallocatedTasks.isNotEmpty ? 1 : 0),
            itemBuilder: (ctx, idx) {
              if (idx == _ganttTasks.length) {
                return _buildUnallocatedSection();
              }
              final t = _ganttTasks[idx];
              return _buildTaskRow(t);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskRow(TaskData task) {
    final start = task.startDate != null ? DateTime(task.startDate!.year, task.startDate!.month, task.startDate!.day) : null;
    final due = task.dueDate != null ? DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day) : null;
    
    final s = start ?? due!;
    final e = due ?? start!;

    final daysFromStart = s.difference(_startDate).inDays;
    final lengthDays = e.difference(s).inDays + 1; // +1 to be inclusive of the day itself

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.cBorder.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          // Left Fixed Column
          Container(
            width: _leftPanelWidth,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: context.cBorder)),
              color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            ),
            child: Row(
              children: [
                Icon(task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 16, color: task.completed ? AppColors.statusDone : context.cTextMuted),
                const SizedBox(width: AppSpacing.sp8),
                Expanded(child: Text(task.title, style: context.bodyMd.copyWith(decoration: task.completed ? TextDecoration.lineThrough : null), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          // Scrollable Gantt Bar Area
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalBodyCtrl,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: _totalDays * _dayWidth,
                child: Stack(
                  children: [
                    // Grid Lines
                    for (int i = 0; i < _totalDays; i++)
                      Positioned(
                        left: i * _dayWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                           width: _dayWidth,
                           decoration: BoxDecoration(
                             border: Border(right: BorderSide(color: context.cBorder.withValues(alpha: 0.1))),
                           ),
                        ),
                      ),
                    
                    // The Task Pill
                    if (daysFromStart >= 0)
                      Positioned(
                        left: (daysFromStart * _dayWidth) + 4,
                        top: 8,
                        bottom: 8,
                        width: (lengthDays * _dayWidth) - 8,
                        child: Tooltip(
                          message: '${task.title}\nInício: ${DateFormat('dd/MM').format(s)}\nFim: ${DateFormat('dd/MM').format(e)}',
                          child: InkWell(
                            onTap: () {
                               // Open edit modal or drag
                            },
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getStatusColor(task.status).withValues(alpha: task.completed ? 0.4 : 0.9),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                task.title,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnallocatedSection() {
    return Container(
      color: context.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.02),
      padding: const EdgeInsets.all(AppSpacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_rounded, size: 16, color: context.cTextMuted),
              const SizedBox(width: AppSpacing.sp8),
              Text('Tarefas Não Alocadas (${_unallocatedTasks.length})', style: context.labelMd),
            ],
          ),
          const SizedBox(height: AppSpacing.sp16),
          Wrap(
            spacing: AppSpacing.sp8,
            runSpacing: AppSpacing.sp8,
            children: _unallocatedTasks.map((t) => Chip(
              label: Text(t.title, style: const TextStyle(fontSize: 11)),
              backgroundColor: context.cBackground,
              side: BorderSide(color: context.cBorder),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'todo': return AppColors.statusTodo;
      case 'in_progress': return AppColors.statusInProgress;
      case 'review': return AppColors.statusReview;
      case 'done': return AppColors.statusDone;
      default: return AppColors.primary;
    }
  }
}
