import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/data_providers.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/ai_copilot/data/repositories/ai_repository.dart';

class OnlineUser {
  final String id;
  final String name;
  OnlineUser(this.id, this.name);
}

class SlaAlert {
  final TaskData task;
  final String message;
  final DateTime timestamp;

  SlaAlert({
    required this.task,
    required this.message,
    required this.timestamp,
  });
}

final onlineUsersProvider = StateProvider<List<OnlineUser>>((ref) => []);
final slaAlertProvider = StateProvider<SlaAlert?>((ref) => null);

/// Gerencia inscrições Supabase Realtime para refresh automático dos providers.
/// Escuta mudanças em: tasks, projects, notifications, pages.
class RealtimeService {
  final Ref _ref;
  final List<RealtimeChannel> _channels = [];
  Timer? _deadlineCheckTimer;
  final Set<String> _alertedTaskIds = {};

  RealtimeService(this._ref);

  void subscribe() async {
    final client = Supabase.instance.client;
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    // ── Tasks channel ─────────────────────────────────────────
    final tasksChannel = client.channel('tasks-realtime').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      callback: (payload) {
        _ref.invalidate(tasksProvider);
        _ref.invalidate(dashboardStatsProvider);

        // Check for SLA critical alert on insert or update
        final eventType = payload.eventType;
        if (eventType == PostgresChangeEvent.insert || eventType == PostgresChangeEvent.update) {
          final record = payload.newRecord;
          final isSlaCritical = record['is_sla_critical'] as bool? ?? false;
          final status = record['status'] as String? ?? 'todo';
          final deadlineAtStr = record['deadline_at'] as String?;
          
          if (isSlaCritical && status != 'done' && status != 'cancelled' && deadlineAtStr != null) {
            final deadlineAt = DateTime.parse(deadlineAtStr).toLocal();
            final now = DateTime.now();
            final difference = deadlineAt.difference(now);
            
            if (difference.inMinutes <= 60 && difference.inMinutes >= -5) {
              try {
                final task = TaskData.fromJson(record);
                final isOverdue = difference.isNegative;
                final key = isOverdue ? '${task.id}-overdue' : task.id;
                
                if (!_alertedTaskIds.contains(key)) {
                  _alertedTaskIds.add(key);
                  final msg = isOverdue 
                      ? 'A tarefa "${task.title}" está atrasada!'
                      : 'A tarefa "${task.title}" vence em ${difference.inMinutes} minutos!';
                  _ref.read(slaAlertProvider.notifier).state = SlaAlert(
                    task: task,
                    message: msg,
                    timestamp: DateTime.now(),
                  );
                }
              } catch (_) {
                // Ignore parsing errors
              }
            }
          }
        }
      },
    ).subscribe();
    _channels.add(tasksChannel);

    // ── Projects channel ──────────────────────────────────────
    final projectsChannel = client.channel('projects-realtime').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'projects',
      callback: (payload) {
        _ref.invalidate(projectsProvider);
      },
    ).subscribe();
    _channels.add(projectsChannel);

    // ── Pages channel ─────────────────────────────────────────
    final pagesChannel = client.channel('pages-realtime').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pages',
      callback: (payload) {
        _ref.invalidate(pagesProvider);
      },
    ).subscribe();
    _channels.add(pagesChannel);

    // ── Notifications channel ─────────────────────────────────
    final notifChannel = client.channel('notifications-realtime').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: user.id,
      ),
      callback: (payload) {
        _ref.invalidate(notificationsProvider);
      },
    ).subscribe();
    _channels.add(notifChannel);
 
    // ── AI Recommendations channel ────────────────────────────
    final aiRecsChannel = client.channel('ai-recs-realtime').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'ai_recommendations',
      callback: (payload) {
        _ref.invalidate(workspaceRecommendationsProvider);
      },
    ).subscribe();
    _channels.add(aiRecsChannel);
 
    // ── AI Task Analysis channel ──────────────────────────────
    final aiAnalysisChannel = client.channel('ai-analysis-realtime').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'ai_task_analysis',
      callback: (payload) {
        final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
        final taskId = record['task_id'] as String?;
        if (taskId != null) {
          _ref.invalidate(taskAnalysisProvider(taskId));
        }
      },
    ).subscribe();
    _channels.add(aiAnalysisChannel);

    // ── Workspace Presence channel ────────────────────────────
    final workspace = await _ref.read(currentWorkspaceProvider.future);
    if (workspace != null) {
      final presenceChannel = client.channel('workspace-${workspace.id}');
      presenceChannel.onPresenceSync((payload) {
        final states = presenceChannel.presenceState();
        final online = <OnlineUser>[];
        for (final state in states) {
          for (final p in state.presences) {
            final id = p.payload['user_id'] as String?;
            final name = p.payload['name'] as String?;
            if (id != null && name != null) {
              if (!online.any((u) => u.id == id)) {
                online.add(OnlineUser(id, name));
              }
            }
          }
        }
        _ref.read(onlineUsersProvider.notifier).state = online;
      }).subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          final name = ((user.userMetadata?['name'] as String?)
              ?? (user.userMetadata?['full_name'] as String?)
              ?? user.email?.split('@').first
              ?? 'Usuário').split(' ').first;
          await presenceChannel.track({
            'user_id': user.id,
            'name': name,
          });
        }
      });
      _channels.add(presenceChannel);
    }

    // ── Background SLA check timer ────────────────────────────
    _deadlineCheckTimer?.cancel();
    _deadlineCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDeadlines();
    });
    // Run an initial check after a brief delay to populate status
    Timer(const Duration(seconds: 3), _checkDeadlines);
  }

  void _checkDeadlines() {
    final tasksState = _ref.read(tasksProvider);
    final tasks = tasksState.valueOrNull;
    if (tasks == null) return;

    final now = DateTime.now();
    for (final task in tasks) {
      if (task.isSlaCritical && !task.isDone && task.deadlineAt != null) {
        final diff = task.deadlineAt!.difference(now);
        
        // Alert if deadline is within 1 hour and not yet alerted
        if (diff.inMinutes <= 60 && diff.inMinutes > 0) {
          if (!_alertedTaskIds.contains(task.id)) {
            _alertedTaskIds.add(task.id);
            final msg = 'A tarefa "${task.title}" vence em ${diff.inMinutes} minutos!';
            _ref.read(slaAlertProvider.notifier).state = SlaAlert(
              task: task,
              message: msg,
              timestamp: DateTime.now(),
            );
          }
        } else if (diff.inMinutes <= 0 && diff.inMinutes >= -5) {
          final overdueKey = '${task.id}-overdue';
          if (!_alertedTaskIds.contains(overdueKey)) {
            _alertedTaskIds.add(overdueKey);
            final msg = 'A tarefa "${task.title}" está atrasada!';
            _ref.read(slaAlertProvider.notifier).state = SlaAlert(
              task: task,
              message: msg,
              timestamp: DateTime.now(),
            );
          }
        }
      }
    }
  }

  void unsubscribe() {
    _deadlineCheckTimer?.cancel();
    _deadlineCheckTimer = null;
    _alertedTaskIds.clear();
    for (final channel in _channels) {
      Supabase.instance.client.removeChannel(channel);
    }
    _channels.clear();
  }
}

/// Provider que gerencia o serviço de realtime.
/// Inicia automaticamente quando o usuário loga e para no logout.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref);

  // Subscribe when user is available
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    service.subscribe();
  }

  // Cleanup on dispose
  ref.onDispose(() {
    service.unsubscribe();
  });

  return service;
});

/// Provider para inicializar o realtime (deve ser lido no app startup)
final realtimeInitProvider = Provider<void>((ref) {
  ref.watch(realtimeServiceProvider);
});

