import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/data_providers.dart';
import '../../features/auth/domain/auth_provider.dart';

class OnlineUser {
  final String id;
  final String name;
  OnlineUser(this.id, this.name);
}

final onlineUsersProvider = StateProvider<List<OnlineUser>>((ref) => []);

/// Gerencia inscrições Supabase Realtime para refresh automático dos providers.
/// Escuta mudanças em: tasks, projects, notifications, pages.
class RealtimeService {
  final Ref _ref;
  final List<RealtimeChannel> _channels = [];

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
          final name = (user.userMetadata?['name'] as String?)?.split(' ').first ?? 'Usuário';
          await presenceChannel.track({
            'user_id': user.id,
            'name': name,
          });
        }
      });
      _channels.add(presenceChannel);
    }
  }

  void unsubscribe() {
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

