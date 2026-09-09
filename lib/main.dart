import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/router.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://fit-api.iscx.site'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: ''),
    // PKCE: flujo OAuth que devuelve la sesion por el deep link
    // com.rivalfit.rivalfit://login-callback. El plugin de supabase_flutter
    // escucha el deep link (app_links) y restaura la sesion persistida antes
    // de que la UI arranque; los cambios se propagan via onAuthStateChange.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(
    ProviderScope(
      child: const RivalFitApp(),
    ),
  );
}

class RivalFitApp extends ConsumerWidget {
  const RivalFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RivalFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
