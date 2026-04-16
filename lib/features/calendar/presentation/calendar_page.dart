import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_tags.dart';
import '../../auth/domain/data_providers.dart';

// ── Providers ────────────────────────────────────────────────

/// Currently selected month (year + month)
final _calMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month),
);

/// Currently selected day (nullable)
final _calSelectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// Calendar view mode
enum CalView { month, week, day }
final _calViewProvider = StateProvider<CalView>((ref) => CalView.month);

// ─────────────────────────────────────────────────────────────
// CalendarPage
// ─────────────────────────────────────────────────────────────

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final currentMonth = ref.watch(_calMonthProvider);
    final selectedDay = ref.watch(_calSelectedDayProvider);
    final calView = ref.watch(_calViewProvider);
    final isDesktop = Responsive.isDesktop(context);
    final focusDay = selectedDay ?? DateTime.now();
    // Watch real calendar events
    final eventsAsync = ref.watch(calendarEventsProvider(currentMonth));
    final events = eventsAsync.valueOrNull ?? [];
    
    // Watch MS Graph events
    final msEventsAsync = ref.watch(msGraphEventsProvider(currentMonth));
    final msEvents = msEventsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: context.cBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEventDialog(
            context, ref, selectedDay ?? DateTime.now()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo evento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Header
          _CalendarHeader(currentMonth: currentMonth, focusDay: focusDay),

          // ── Content
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Erro: $e', style: context.bodySm),
              ),
              data: (tasks) {
                // Group tasks by date
                final tasksByDay = <String, List<TaskData>>{};
                
                // Set calendar limits for recurrence generation
                final calStart = DateTime(currentMonth.year, currentMonth.month - 1, 1);
                final calEnd = DateTime(currentMonth.year, currentMonth.month + 2, 0);

                for (final t in tasks) {
                  if (t.dueDate == null) continue;
                  
                  // Base instance
                  final key = _dayKey(t.dueDate!);
                  tasksByDay.putIfAbsent(key, () => []).add(t);

                  // Projected recurring instances
                  if (t.isRecurring) {
                    DateTime curr = t.dueDate!;
                    while (true) {
                      if (t.recurrenceType == 'daily') {
                        curr = DateTime(curr.year, curr.month, curr.day + t.recurrenceInterval);
                      } else if (t.recurrenceType == 'weekly') {
                        curr = DateTime(curr.year, curr.month, curr.day + (7 * t.recurrenceInterval));
                      } else if (t.recurrenceType == 'monthly') {
                        curr = DateTime(curr.year, curr.month + t.recurrenceInterval, curr.day);
                      } else if (t.recurrenceType == 'yearly') {
                        curr = DateTime(curr.year + t.recurrenceInterval, curr.month, curr.day);
                      } else {
                        break;
                      }

                      // Check end conditions
                      if (t.recurrenceEndsAt != null && curr.isAfter(t.recurrenceEndsAt!)) break;
                      if (curr.isAfter(calEnd)) break;
                      
                      // Skip past instances heavily out of calendar window bound
                      if (curr.isBefore(calStart)) continue;

                      final recKey = _dayKey(curr);
                      tasksByDay.putIfAbsent(recKey, () => []).add(t.copyWith(dueDate: curr));
                    }
                  }
                }

                // Group all calendar events by date
                final eventsByDay = <String, List<CalendarEventData>>{};
                final allEvents = [...events, ...msEvents];
                for (final e in allEvents.where((e) => e.eventType == 'event')) {
                  final key = _dayKey(e.startsAt);
                  eventsByDay.putIfAbsent(key, () => []).add(e);
                }

                // ── Week view
                if (calView == CalView.week) {
                  return _WeekView(
                      focusDay: focusDay, tasksByDay: tasksByDay);
                }

                // ── Day view
                if (calView == CalView.day) {
                  return _DayView(
                    day: focusDay,
                    tasks: tasksByDay[_dayKey(focusDay)] ?? [],
                    dayEvents:
                        eventsByDay[_dayKey(focusDay)] ?? [],
                  );
                }

                // ── Month view (original)
                if (isDesktop && selectedDay != null) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _MonthGrid(
                          currentMonth: currentMonth,
                          tasksByDay: tasksByDay,
                          eventsByDay: eventsByDay,
                          selectedDay: selectedDay,
                        ),
                      ),
                      Container(
                        width: 300,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: context.isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                            ),
                          ),
                        ),
                        child: _DayDetail(
                          day: selectedDay,
                          tasks: tasksByDay[_dayKey(selectedDay)] ?? [],
                          dayEvents:
                              eventsByDay[_dayKey(selectedDay)] ?? [],
                        ),
                      ),
                    ],
                  );
                }

                return _MonthGrid(
                  currentMonth: currentMonth,
                  tasksByDay: tasksByDay,
                  eventsByDay: eventsByDay,
                  selectedDay: selectedDay,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Criar Evento ─────────────────────────────────────────────
  static void _showCreateEventDialog(
      BuildContext context, WidgetRef ref, DateTime initialDate) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var pickedDate = initialDate;
    const colors = [
      '#5B6AF3', '#8B5CF6', '#EC4899', '#EF4444',
      '#F59E0B', '#10B981', '#3B82F6', '#6B7280',
    ];
    var selectedColor = colors.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Novo evento'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Título do evento', hintText: 'Reunião, Prazo...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Date picker
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: pickedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => pickedDate = d);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primary.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Color picker
                const Text('Cor do evento',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((c) {
                    final color = _hexColor(c);
                    final isSelected = c == selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = c),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final event = await ref
                    .read(calendarEventsProvider(
                            DateTime(pickedDate.year, pickedDate.month))
                        .notifier)
                    .createEvent(
                      title: titleCtrl.text,
                      startsAt: pickedDate,
                      allDay: true,
                      color: selectedColor,
                      description: descCtrl.text.trim().isNotEmpty
                          ? descCtrl.text
                          : null,
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (event != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Evento "${event.title}" criado!'),
                      backgroundColor: AppColors.success,
                    ));
                  }
                }
              },
              child: const Text('Criar evento'),
            ),
          ],
        ),
      ),
    );
  }

  static Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── Header ───────────────────────────────────────────────────
class _CalendarHeader extends ConsumerWidget {
  final DateTime currentMonth;
  final DateTime focusDay;
  const _CalendarHeader(
      {required this.currentMonth, required this.focusDay});

  static const _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril',
    'Maio', 'Junho', 'Julho', 'Agosto',
    'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  static const _weekDays = [
    'Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb',
  ];

  String get _weekRangeLabel {
    final start = focusDay.subtract(Duration(days: focusDay.weekday % 7));
    final end = start.add(const Duration(days: 6));
    return '${start.day}–${end.day} de ${_months[start.month - 1]}';
  }

  String get _dayLabel =>
      '${_weekDays[focusDay.weekday % 7]}, ${focusDay.day} de ${_months[focusDay.month - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calView = ref.watch(_calViewProvider);

    String titleText = switch (calView) {
      CalView.month => '${_months[currentMonth.month - 1]} ${currentMonth.year}',
      CalView.week => _weekRangeLabel,
      CalView.day => _dayLabel,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp24,
        vertical: AppSpacing.sp10,
      ),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Line 1: icon + title + today ────────────
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titleText,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  final now = DateTime.now();
                  ref.read(_calMonthProvider.notifier).state =
                      DateTime(now.year, now.month);
                  ref.read(_calSelectedDayProvider.notifier).state =
                      DateTime(now.year, now.month, now.day);
                },
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text('Hoje',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Line 2: view switcher + prev/next ───────
          Row(
            children: [
              Expanded(
                child: SegmentedButton<CalView>(
                  segments: const [
                    ButtonSegment(
                        value: CalView.month,
                        label: Text('Mês'),
                        icon: Icon(Icons.grid_view_rounded, size: 13)),
                    ButtonSegment(
                        value: CalView.week,
                        label: Text('Semana'),
                        icon: Icon(Icons.view_week_rounded, size: 13)),
                    ButtonSegment(
                        value: CalView.day,
                        label: Text('Dia'),
                        icon: Icon(Icons.view_day_rounded, size: 13)),
                  ],
                  selected: {calView},
                  onSelectionChanged: (s) =>
                      ref.read(_calViewProvider.notifier).state = s.first,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 11),
                    visualDensity:
                        const VisualDensity(horizontal: -3, vertical: -2),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _navigate(ref, calView, -1),
                color: context.cTextMuted,
                padding: const EdgeInsets.all(4),
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _navigate(ref, calView, 1),
                color: context.cTextMuted,
                padding: const EdgeInsets.all(4),
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigate(WidgetRef ref, CalView view, int dir) {
    switch (view) {
      case CalView.month:
        final m = ref.read(_calMonthProvider);
        ref.read(_calMonthProvider.notifier).state =
            DateTime(m.year, m.month + dir);
      case CalView.week:
        final d = ref.read(_calSelectedDayProvider) ?? DateTime.now();
        ref.read(_calSelectedDayProvider.notifier).state =
            d.add(Duration(days: 7 * dir));
      case CalView.day:
        final d = ref.read(_calSelectedDayProvider) ?? DateTime.now();
        ref.read(_calSelectedDayProvider.notifier).state =
            d.add(Duration(days: dir));
    }
  }
}

// ── Month Grid ───────────────────────────────────────────────
class _MonthGrid extends ConsumerWidget {
  final DateTime currentMonth;
  final Map<String, List<TaskData>> tasksByDay;
  final Map<String, List<CalendarEventData>> eventsByDay;
  final DateTime? selectedDay;

  const _MonthGrid({
    required this.currentMonth,
    required this.tasksByDay,
    required this.eventsByDay,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    // Calculate days
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    // weekday: 1=Mon, 7=Sun — offset to start on Sunday (0-indexed)
    final startOffset = (firstDayOfMonth.weekday % 7); // 0=Sun,1=Mon,...
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();
    final todayKey = _dayKey(DateTime(today.year, today.month, today.day));

    const weekLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Column(
      children: [
        // Week day headers
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp16, vertical: AppSpacing.sp8),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: context.isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: weekLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.cTextMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.sp8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: isDesktop ? 1.4 : 0.9,
              crossAxisSpacing: AppSpacing.sp4,
              mainAxisSpacing: AppSpacing.sp4,
            ),
            itemCount: rows * 7,
            itemBuilder: (_, index) {
              final dayNum = index - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = DateTime(currentMonth.year, currentMonth.month, dayNum);
              final key = _dayKey(day);
              final tasks = tasksByDay[key] ?? [];
              final events = eventsByDay[key] ?? [];
              final isToday = key == todayKey;
              final isSelected = selectedDay != null &&
                  _dayKey(selectedDay!) == key;

              return _DayCell(
                day: dayNum,
                tasks: tasks,
                events: events,
                isToday: isToday,
                isSelected: isSelected,
                onTap: () {
                  ref.read(_calSelectedDayProvider.notifier).state = day;
                  // On mobile, show bottom sheet
                  if (!isDesktop) {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _DayDetailSheet(
                          day: day, tasks: tasks, dayEvents: events),
                    );
                  }
                },
              ).animate().fadeIn(
                    delay: Duration(milliseconds: index * 8),
                    duration: 200.ms,
                  );
            },
          ),
        ),
      ],
    );
  }
}

// ── Day Cell ─────────────────────────────────────────────────
class _DayCell extends StatefulWidget {
  final int day;
  final List<TaskData> tasks;
  final List<CalendarEventData> events;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.tasks,
    this.events = const [],
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    Color bgColor;
    Color borderColor;
    if (widget.isSelected) {
      bgColor = AppColors.primary.withValues(alpha: 0.12);
      borderColor = AppColors.primary;
    } else if (widget.isToday) {
      bgColor = AppColors.primary.withValues(alpha: 0.06);
      borderColor = AppColors.primary.withValues(alpha: 0.3);
    } else if (_hovering) {
      bgColor = context.isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant;
      borderColor = context.isDark ? AppColors.borderDark : AppColors.border;
    } else {
      bgColor =
          context.isDark ? AppColors.surfaceDark : AppColors.surface;
      borderColor = context.isDark ? AppColors.borderDark : AppColors.border;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day number
                Row(
                  children: [
                    if (widget.isToday)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.day}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        '${widget.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: widget.isSelected
                              ? AppColors.primary
                              : context.cTextPrimary,
                        ),
                      ),
                    const Spacer(),
                    if (widget.tasks.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${widget.tasks.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                // Desktop: show mini labels for tasks and events
                if (isDesktop && (widget.tasks.isNotEmpty || widget.events.isNotEmpty)) ...[
                  const SizedBox(height: 4),
                  // Real events first (with their color)
                  ...widget.events.take(2).map((e) => _EventDot(event: e)),
                  // Then tasks
                  ...widget.tasks.take(3 - widget.events.take(2).length).map((t) => _TaskDot(task: t)),
                  if (widget.tasks.length + widget.events.length > 3)
                    Text(
                      '+${widget.tasks.length + widget.events.length - 3} mais',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.cTextMuted,
                      ),
                    ),
                ] else if (!isDesktop && (widget.tasks.isNotEmpty || widget.events.isNotEmpty)) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 2,
                    children: [
                      // Event dots with their real color
                      ...widget.events.take(2).map((e) {
                        final hex = e.color.replaceAll('#', '');
                        final color = Color(int.parse('FF$hex', radix: 16));
                        return Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        );
                      }),
                      // Task dots
                      ...widget.tasks.take(3).map((t) {
                        final color = _statusColor(t.status);
                        return Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'done' => AppColors.statusDone,
        'in_progress' => AppColors.statusInProgress,
        'review' => AppColors.statusReview,
        'cancelled' => AppColors.statusCancelled,
        _ => AppColors.statusTodo,
      };
}

class _TaskDot extends StatelessWidget {
  final TaskData task;
  const _TaskDot({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = switch (task.status) {
      'done' => AppColors.statusDone,
      'in_progress' => AppColors.statusInProgress,
      'review' => AppColors.statusReview,
      _ => AppColors.statusTodo,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(fontSize: 10, color: context.cTextPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDot extends StatelessWidget {
  final CalendarEventData event;
  const _EventDot({required this.event});

  @override
  Widget build(BuildContext context) {
    final hex = event.color.replaceAll('#', '');
    final color = Color(int.parse('FF$hex', radix: 16));
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Detail (desktop side panel) ─────────────────────────
class _DayDetail extends StatelessWidget {
  final DateTime day;
  final List<TaskData> tasks;
  final List<CalendarEventData> dayEvents;
  const _DayDetail({
    required this.day,
    required this.tasks,
    this.dayEvents = const [],
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      children: [
        // Date header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weekdays[day.weekday - 1],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.cTextMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day} de ${months[day.month - 1]}. ${day.year}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.cTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp20),

        // Real calendar events
        if (dayEvents.isNotEmpty) ...[
          Text('Eventos', style: context.labelMd.copyWith(color: context.cTextMuted)),
          const SizedBox(height: AppSpacing.sp8),
          ...dayEvents.map((e) => _CalendarEventItem(
                event: e,
                currentMonth: DateTime(day.year, day.month),
              ).animate().fadeIn(duration: 200.ms)),
          const SizedBox(height: AppSpacing.sp16),
        ],

        if (tasks.isEmpty && dayEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sp24),
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 32, color: context.cTextMuted),
                const SizedBox(height: 8),
                Text(
                  'Nenhuma tarefa ou evento',
                  style: context.bodySm,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (tasks.isNotEmpty) ...[
          Text(
            '${tasks.length} tarefa${tasks.length > 1 ? 's' : ''}',
            style: context.bodyMd.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sp12),
          ...tasks.map((t) => _DayTaskItem(task: t)
              .animate()
              .fadeIn(duration: 250.ms)
              .slideX(begin: 0.05, duration: 250.ms)),
        ],
      ],
    );
  }
}

class _DayTaskItem extends StatelessWidget {
  final TaskData task;
  const _DayTaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return GestureDetector(
        onTap: () => context.go('/tasks/${task.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
          padding: const EdgeInsets.all(AppSpacing.sp12),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: context.isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: task.isDone
                      ? context.cTextMuted
                      : context.cTextPrimary,
                  decoration:
                      task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                StatusTag(status: task.status),
                const SizedBox(width: 6),
                PriorityTag(priority: task.priority),
              ]),
            ],
          ),
        ),
      );
    });
  }
}

// ── Calendar Event Item ───────────────────────────────────────
class _CalendarEventItem extends ConsumerWidget {
  final CalendarEventData event;
  final DateTime currentMonth;
  const _CalendarEventItem({
    required this.event,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hex = event.color.replaceAll('#', '');
    final color = Color(int.parse('FF$hex', radix: 16));
    return GestureDetector(
      onTap: () => _showEventSheet(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12, vertical: AppSpacing.sp10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.description!,
                        style: TextStyle(
                            fontSize: 12, color: context.cTextMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _showEventSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventEditSheet(
        event: event,
        currentMonth: currentMonth,
        providerRef: ref,
      ),
    );
  }
}

// ── Event Edit/Delete Sheet ───────────────────────────────────
class _EventEditSheet extends ConsumerStatefulWidget {
  final CalendarEventData event;
  final DateTime currentMonth;
  final WidgetRef providerRef;

  const _EventEditSheet({
    required this.event,
    required this.currentMonth,
    required this.providerRef,
  });

  @override
  ConsumerState<_EventEditSheet> createState() => _EventEditSheetState();
}

class _EventEditSheetState extends ConsumerState<_EventEditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _selectedDate;
  late String _selectedColor;
  bool _loading = false;

  static const _colors = [
    '#5B6AF3', '#10B981', '#F59E0B', '#EF4444',
    '#8B5CF6', '#06B6D4', '#EC4899', '#64748B',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.event.title);
    _descCtrl =
        TextEditingController(text: widget.event.description ?? '');
    _selectedDate = widget.event.startsAt;
    _selectedColor = widget.event.color;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final notifier = widget.providerRef
        .read(calendarEventsProvider(widget.currentMonth).notifier);
    await notifier.updateEvent(
      eventId: widget.event.id,
      title: _titleCtrl.text,
      startsAt: _selectedDate,
      color: _selectedColor,
      description: _descCtrl.text,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Evento atualizado!'),
          ]),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento'),
        content:
            Text('Excluir "${widget.event.title}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await widget.providerRef
          .read(calendarEventsProvider(widget.currentMonth).notifier)
          .deleteEvent(widget.event.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color:
              context.isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.sp24),
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
                    color: context.isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    borderRadius:
                        BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sp20),

              // Header
              Row(children: [
                const Icon(Icons.event_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Editar evento',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.error),
                  onPressed: _delete,
                  tooltip: 'Excluir evento',
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: context.cTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: AppSpacing.sp20),

              // Title
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Título do evento *',
                  prefixIcon:
                      Icon(Icons.title_rounded, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.sp16),

              // Description
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  prefixIcon: Icon(Icons.notes_rounded, size: 18),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sp16),

              // Date picker
              Text('Data', style: context.labelMd),
              const SizedBox(height: AppSpacing.sp8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius:
                    BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: context.isDark
                            ? AppColors.borderDark
                            : AppColors.border),
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      style: TextStyle(
                          fontSize: 14,
                          color: context.cTextPrimary),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpacing.sp16),

              // Color picker
              Text('Cor', style: context.labelMd),
              const SizedBox(height: AppSpacing.sp8),
              Wrap(
                spacing: 8,
                children: _colors.map((c) {
                  final color = _parseColor(c);
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: AppAnimations.fast,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: context.isDark
                                    ? Colors.white
                                    : Colors.black87,
                                width: 2.5)
                            : Border.all(
                                color: Colors.transparent,
                                width: 2.5),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: color.withValues(
                                        alpha: 0.4),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sp28),

              // Buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text('Salvar'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Day Detail Sheet (mobile bottom sheet) ───────────────────
class _DayDetailSheet extends StatelessWidget {
  final DateTime day;
  final List<TaskData> tasks;
  final List<CalendarEventData> dayEvents;
  const _DayDetailSheet({
    required this.day,
    required this.tasks,
    this.dayEvents = const [],
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.sp24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp16),
          Text(
            '${day.day} de ${months[day.month - 1]} de ${day.year}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp16),
          if (dayEvents.isNotEmpty) ...[
            Text('Eventos', style: context.labelMd.copyWith(color: context.cTextMuted)),
            const SizedBox(height: 8),
            ...dayEvents.map((e) => _CalendarEventItem(
                event: e,
                currentMonth: DateTime(day.year, day.month),
              )),
            const SizedBox(height: AppSpacing.sp12),
          ],
          if (tasks.isEmpty && dayEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp24),
              child: Center(
                child: Text('Nenhuma tarefa ou evento neste dia.',
                    style: context.bodySm),
              ),
            )
          else if (tasks.isNotEmpty)
            ...tasks.map((t) => _DayTaskItem(task: t)),
          const SizedBox(height: AppSpacing.sp16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Week View
// ─────────────────────────────────────────────────────────────

class _WeekView extends ConsumerWidget {
  final DateTime focusDay;
  final Map<String, List<TaskData>> tasksByDay;

  const _WeekView({required this.focusDay, required this.tasksByDay});

  static const _dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start of week (Sunday)
    final startOfWeek =
        focusDay.subtract(Duration(days: focusDay.weekday % 7));
    final days =
        List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final today = DateTime.now();

    return Column(
      children: [
        // Day headers
        Container(
          decoration: BoxDecoration(
            color: context.isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceVariant,
            border: Border(
              bottom: BorderSide(
                color: context.isDark
                    ? AppColors.borderDark
                    : AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: days.map((day) {
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    ref.read(_calSelectedDayProvider.notifier).state = day;
                    ref.read(_calViewProvider.notifier).state = CalView.day;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          _dayNames[day.weekday % 7],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isToday
                                ? AppColors.primary
                                : context.cTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: isToday
                              ? BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? Colors.white
                                  : context.cTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Task columns
        Expanded(
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: days.asMap().entries.map((entry) {
                  final i = entry.key;
                  final day = entry.value;
                  final key = _dayKey(day);
                  final dayTasks = tasksByDay[key] ?? [];
                  final isToday = day.year == today.year &&
                      day.month == today.month &&
                      day.day == today.day;

                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary.withValues(alpha: 0.02)
                            : null,
                        border: Border(
                          right: i < 6
                              ? BorderSide(
                                  color: context.isDark
                                      ? AppColors.borderDark
                                      : AppColors.border,
                                  width: 0.5,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          if (dayTasks.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                '—',
                                style: TextStyle(
                                    color: context.cTextMuted,
                                    fontSize: 18),
                              ),
                            )
                          else
                            ...dayTasks.map((t) => _WeekTaskChip(task: t)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekTaskChip extends ConsumerWidget {
  final TaskData task;
  const _WeekTaskChip({required this.task});

  Color get _color => switch (task.status) {
        'done' => AppColors.statusDone,
        'in_progress' => AppColors.statusInProgress,
        'review' => AppColors.statusReview,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/tasks/${task.id}'),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(
            left: BorderSide(color: _color, width: 3),
          ),
        ),
        child: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: context.cTextPrimary,
            decoration:
                task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Day View
// ─────────────────────────────────────────────────────────────

class _DayView extends ConsumerWidget {
  final DateTime day;
  final List<TaskData> tasks;
  final List<CalendarEventData> dayEvents;

  const _DayView({
    required this.day,
    required this.tasks,
    this.dayEvents = const [],
  });

  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  // Timeline range: 07h–22h
  static const _startHour = 7;
  static const _endHour = 22;
  static const _slotHeight = 64.0; // pixels per hour

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

    // Only timed events (not all-day) for the timeline
    final timedEvents = dayEvents
        .where((e) => !e.allDay)
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    final allDayEvents = dayEvents.where((e) => e.allDay).toList();

    final totalHours = _endHour - _startHour;
    final timelineHeight = totalHours * _slotHeight;

    // Current time indicator offset
    double? nowOffset;
    if (isToday) {
      final minutesFromMidnight = now.hour * 60 + now.minute;
      final minutesFromStart = minutesFromMidnight - _startHour * 60;
      if (minutesFromStart >= 0 && minutesFromStart <= totalHours * 60) {
        nowOffset = (minutesFromStart / 60) * _slotHeight;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day header ───────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : (context.isDark
                        ? AppColors.surfaceDark
                        : AppColors.surface),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : (context.isDark ? AppColors.borderDark : AppColors.border),
                ),
              ),
              child: Text(
                '${day.day} ${_months[day.month - 1]} ${day.year}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isToday ? AppColors.primary : context.cTextPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${tasks.length} tarefa${tasks.length != 1 ? 's' : ''}'
              '${timedEvents.isNotEmpty ? ' · ${timedEvents.length} evento${timedEvents.length != 1 ? 's' : ''}' : ''}',
              style: context.bodySm,
            ),
          ]),
          const SizedBox(height: AppSpacing.sp20),

          // ── All-day events ────────────────────────────────────
          if (allDayEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Column(
                children: allDayEvents.map((e) {
                  final color = _parseColor(e.color);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      Icon(Icons.event_rounded, size: 12, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.title,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: color),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('Dia todo',
                          style: TextStyle(fontSize: 10, color: color)),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sp12),
          ],

          // ── Tasks at top ─────────────────────────────────────
          if (tasks.isNotEmpty) ...[
            Text('Tarefas do dia',
                style: context.labelMd.copyWith(color: context.cTextMuted)),
            const SizedBox(height: 8),
            ...tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DayTaskItem(task: t),
                )),
            const SizedBox(height: AppSpacing.sp20),
          ],

          // ── Timeline ─────────────────────────────────────────
          Text('Linha do tempo',
              style: context.labelMd.copyWith(color: context.cTextMuted)),
          const SizedBox(height: 8),

          SizedBox(
            height: timelineHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hour labels column
                SizedBox(
                  width: 52,
                  child: Stack(
                    children: List.generate(totalHours, (i) {
                      final hour = _startHour + i;
                      return Positioned(
                        top: i * _slotHeight - 8,
                        left: 0,
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                              fontSize: 11, color: context.cTextMuted),
                        ),
                      );
                    }),
                  ),
                ),

                // Grid + events
                Expanded(
                  child: Stack(
                    children: [
                      // Hour grid lines
                      Column(
                        children: List.generate(totalHours, (i) {
                          return Container(
                            height: _slotHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: (context.isDark
                                          ? AppColors.borderDark
                                          : AppColors.border)
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // Current time red line
                      if (nowOffset != null)
                        Positioned(
                          top: nowOffset,
                          left: 0,
                          right: 0,
                          child: Row(children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: AppColors.error,
                              ),
                            ),
                          ]),
                        ),

                      // Positioned events
                      ..._layoutEvents(timedEvents, timelineHeight, context, ref),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sp40),
        ],
      ),
    );
  }

  /// Lays out timed events as positioned boxes in the Stack.
  /// Events that overlap are rendered side-by-side.
  List<Widget> _layoutEvents(
    List<CalendarEventData> events,
    double totalHeight,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (events.isEmpty) return [];

    // Group overlapping events into columns
    final columns = <List<CalendarEventData>>[];

    for (final event in events) {
      bool placed = false;
      for (final col in columns) {
        final lastInCol = col.last;
        final lastEnd = lastInCol.endsAt ?? lastInCol.startsAt.add(const Duration(hours: 1));
        if (!event.startsAt.isBefore(lastEnd)) {
          col.add(event);
          placed = true;
          break;
        }
      }
      if (!placed) columns.add([event]);
    }

    final widgets = <Widget>[];
    for (int colIdx = 0; colIdx < columns.length; colIdx++) {
      final col = columns[colIdx];
      for (final event in col) {
        final topOffset = _minutesFromStart(event.startsAt) * _slotHeight / 60;
        final endTime = event.endsAt ?? event.startsAt.add(const Duration(hours: 1));
        final durationMinutes = endTime.difference(event.startsAt).inMinutes;
        final eventHeight = (durationMinutes / 60) * _slotHeight;
        final color = _parseColor(event.color);

        // calculate horizontal position for overlapping
        final colWidth = 1.0 / columns.length;
        final left = colIdx * colWidth;

        widgets.add(
          Positioned(
            top: topOffset,
            bottom: totalHeight - topOffset - eventHeight,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final totalW = constraints.maxWidth;
                return Positioned(
                  top: 0,
                  left: left * totalW + 2,
                  width: colWidth * totalW - 4,
                  height: eventHeight.clamp(24.0, double.infinity),
                  child: _TimelineEventTile(
                    event: event,
                    color: color,
                    ref: ref,
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    return widgets;
  }

  double _minutesFromStart(DateTime dt) {
    final minutes = dt.hour * 60 + dt.minute;
    return (minutes - _startHour * 60).clamp(0.0, (_endHour - _startHour) * 60.0).toDouble();
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _TimelineEventTile extends StatelessWidget {
  final CalendarEventData event;
  final Color color;
  final WidgetRef ref;

  const _TimelineEventTile({
    required this.event,
    required this.color,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final endTime = event.endsAt ?? event.startsAt.add(const Duration(hours: 1));
    final startStr = _fmt(event.startsAt);
    final endStr = _fmt(endTime);
    final isShort = endTime.difference(event.startsAt).inMinutes < 45;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _EventEditSheet(
            event: event,
            currentMonth: DateTime(event.startsAt.year, event.startsAt.month),
            providerRef: ref,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: isShort
            // Short events: single line
            ? Text(
                event.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            // Taller events: title + time range
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$startStr – $endStr',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty &&
                      endTime.difference(event.startsAt).inMinutes >= 90) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.description!,
                      style: TextStyle(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

