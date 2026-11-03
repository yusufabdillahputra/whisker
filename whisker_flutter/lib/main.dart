import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'app/app.dart';
import 'client.dart';
import 'data/fake_api.dart';
import 'data/providers.dart';
import 'data/serverpod_api.dart';

/// `--dart-define=WHISKER_DEMO=true`: data contoh di memori, tanpa login.
const demoMode = bool.fromEnvironment('WHISKER_DEMO');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (demoMode) {
    runApp(
      ProviderScope(
        overrides: [
          apiProvider.overrideWithValue(FakeWhiskerApi.sample()),
          demoModeProvider.overrideWithValue(true),
        ],
        child: const WhiskerApp(),
      ),
    );
    return;
  }
  await initializeClient();
  runApp(
    ProviderScope(
      overrides: [
        apiProvider.overrideWithValue(ServerpodWhiskerApi(client)),
        authGateProvider.overrideWithValue(
          AuthGate(
            listenable: client.auth.authInfoListenable,
            isSignedIn: () => client.auth.isAuthenticated,
          ),
        ),
      ],
      child: const WhiskerApp(),
    ),
  );
}
