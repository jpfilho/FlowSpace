import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/config/supabase_config.dart';
import 'core/theme/index.dart';
import 'core/routing/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/services/realtime_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Register timeago locale
  timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    const ProviderScope(
      child: FlowSpaceApp(),
    ),
  );
}

class FlowSpaceApp extends ConsumerWidget {
  const FlowSpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialize realtime subscriptions
    ref.watch(realtimeInitProvider);

    return MaterialApp.router(
      title: 'FlowSpace',
      debugShowCheckedModeBanner: false,

      // Themes
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // Routing
      routerConfig: router,
    );
  }
}
