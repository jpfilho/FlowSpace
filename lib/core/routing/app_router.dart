import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/domain/data_providers.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/tasks/presentation/tasks_page.dart';
import '../../features/tasks/presentation/task_detail_page.dart';
import '../../features/projects/presentation/projects_page.dart';
import '../../features/projects/presentation/project_detail_page.dart';
import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/gtd/presentation/gtd_page.dart';
import '../../features/pages/presentation/pages_list_page.dart';
import '../../features/pages/presentation/page_editor_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/members/presentation/members_page.dart';
import '../../features/databases/presentation/databases_page.dart';
import '../../features/databases/presentation/database_view_page.dart';
import '../../features/invite/presentation/invite_page.dart';
import '../../features/focus/presentation/focus_start_page.dart';
import '../../features/focus/presentation/focus_flow_page.dart';
import '../../features/focus/presentation/focus_completion_page.dart';
import '../../shared/widgets/sidebar/app_shell.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull?.session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isInviteRoute = state.matchedLocation.startsWith('/invite');

      // Rotas de convite são sempre acessíveis (a página trata o login)
      if (isInviteRoute) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      // ── Auth Routes ────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => LoginPage(
          inviteToken: state.uri.queryParameters['invite'],
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const SignupPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // ── Invite Route (sem sidebar, sem auth obrigatório) ──
      GoRoute(
        path: '${AppRoutes.invite}/:token',
        builder: (_, state) =>
            InvitePage(token: state.pathParameters['token']!),
      ),

      // ── App Shell (authenticated) ──────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, state) =>
                _fadePage(const _FocusGatewayPage(), state),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            pageBuilder: (_, state) => _fadePage(const TasksPage(), state),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    TaskDetailPage(taskId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.projects,
            pageBuilder: (_, state) => _fadePage(const ProjectsPage(), state),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ProjectDetailPage(projectId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.pages,
            pageBuilder: (_, state) => _fadePage(const PagesListPage(), state),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    PageEditorPage(pageId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (_, state) =>
                _fadePage(const CalendarPage(), state),
          ),
          GoRoute(
            path: AppRoutes.gtd,
            pageBuilder: (_, state) => _fadePage(const GtdPage(), state),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (_, state) =>
                _fadePage(const NotificationsPage(), state),
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (_, state) =>
                _fadePage(const ReportsPage(), state),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (_, state) =>
                _fadePage(const SettingsPage(), state),
          ),
          GoRoute(
            path: AppRoutes.search,
            pageBuilder: (_, state) =>
                _fadePage(const SearchPage(), state),
          ),
          GoRoute(
            path: AppRoutes.members,
            pageBuilder: (_, state) =>
                _fadePage(const MembersPage(), state),
          ),
          GoRoute(
            path: AppRoutes.databases,
            pageBuilder: (_, state) =>
                _fadePage(const DatabasesPage(), state),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => DatabaseViewPage(databaseId: state.pathParameters['id']!),
              ),
            ],
          ),
          // ── Focus Start ───────────────────────────────────
          GoRoute(
            path: AppRoutes.focus,
            pageBuilder: (_, state) =>
                _fadePage(const FocusStartPage(), state),
          ),
          GoRoute(
            path: AppRoutes.focusFlow,
            pageBuilder: (_, state) =>
                _fadePage(const FocusFlowPage(), state),
          ),
          GoRoute(
            path: AppRoutes.focusComplete,
            pageBuilder: (_, state) =>
                _fadePage(const FocusCompletionPage(), state),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────
// FOCUS GATEWAY
// Wrapper do dashboard que verifica se o Focus Start deve ser
// exibido antes de liberar o acesso ao dashboard principal.
// ─────────────────────────────────────────────────────────────

class _FocusGatewayPage extends ConsumerStatefulWidget {
  const _FocusGatewayPage();

  @override
  ConsumerState<_FocusGatewayPage> createState() =>
      _FocusGatewayPageState();
}

class _FocusGatewayPageState extends ConsumerState<_FocusGatewayPage> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFocus());
  }

  Future<void> _checkFocus() async {
    if (_checked || !mounted) return;
    _checked = true;

    // 1. Verifica se o focus já foi feito hoje
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = 'focus_done_${now.year}_${now.month}_${now.day}';
    if (prefs.getBool(key) == true) return; // já fez hoje → dashboard normal

    // 2. Aguarda as tarefas carregarem (com timeout)
    final tasks = await ref.read(tasksProvider.future).timeout(
          const Duration(seconds: 8),
          onTimeout: () => [],
        );

    if (!mounted) return;

    // 3. Verifica se há tarefas críticas
    final today = DateTime(now.year, now.month, now.day);
    final hasFocusTasks = tasks.any((t) {
      final status = t.effectiveStatus;
      if (status == 'done' || status == 'cancelled') return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isBefore(today) || t.dueDate! == today;
    });

    if (hasFocusTasks && mounted) {
      context.go(AppRoutes.focus);
    }
    // Se não há tarefas críticas → permanece no dashboard
  }

  @override
  Widget build(BuildContext context) => const DashboardPage();
}

