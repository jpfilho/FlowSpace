import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
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
            pageBuilder: (_, state) => _fadePage(const DashboardPage(), state),
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
