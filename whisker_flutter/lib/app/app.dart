import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/sign_in_page.dart';
import '../features/hubs/hubs_page.dart';
import '../features/shell/workspace_page.dart';
import 'theme.dart';

/// Status login yang dipakai router; `null` = mode demo (tanpa login).
class AuthGate {
  final Listenable listenable;
  final bool Function() isSignedIn;
  const AuthGate({required this.listenable, required this.isSignedIn});
}

final authGateProvider = Provider<AuthGate?>((ref) => null);

/// Router aplikasi: `/` daftar Hub, `/hub/:hubId?doc=<path>` workspace,
/// `/masuk` halaman login.
GoRouter buildRouter(AuthGate? auth) => GoRouter(
  refreshListenable: auth?.listenable,
  redirect: (context, state) {
    if (auth == null) return null;
    final signingIn = state.matchedLocation == '/masuk';
    if (!auth.isSignedIn()) return signingIn ? null : '/masuk';
    return signingIn ? '/' : null;
  },
  routes: [
    GoRoute(path: '/', builder: (c, s) => const HubsPage()),
    GoRoute(path: '/masuk', builder: (c, s) => const SignInPage()),
    GoRoute(
      path: '/hub/:hubId',
      builder: (c, s) => WorkspacePage(
        hubId: int.parse(s.pathParameters['hubId']!),
        docPath: s.uri.queryParameters['doc'],
      ),
    ),
  ],
);

bool get _isTouchPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class WhiskerApp extends ConsumerStatefulWidget {
  const WhiskerApp({super.key});

  @override
  ConsumerState<WhiskerApp> createState() => _WhiskerAppState();
}

class _WhiskerAppState extends ConsumerState<WhiskerApp> {
  late final GoRouter _router = buildRouter(ref.read(authGateProvider));

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final theme = whiskerTheme(brightness, touch: _isTouchPlatform);
    return MaterialApp.router(
      title: 'Whisker',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: materialThemeOf(theme),
      localizationsDelegates: FLocalizations.localizationsDelegates,
      supportedLocales: FLocalizations.supportedLocales,
      builder: (context, child) => FTheme(
        data: theme,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
    );
  }
}
