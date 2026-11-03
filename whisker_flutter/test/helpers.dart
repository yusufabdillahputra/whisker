import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:whisker/app/theme.dart';
import 'package:whisker/data/fake_api.dart';
import 'package:whisker/data/providers.dart';

/// Membungkus [child] dengan tema Whisker, ProviderScope, dan ukuran layar.
Future<FakeWhiskerApi> pumpWhisker(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1280, 800),
  FakeWhiskerApi? api,
  List overrides = const [],
}) async {
  final fake = api ?? FakeWhiskerApi.sample();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = whiskerTheme(Brightness.light, touch: false);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiProvider.overrideWithValue(fake),
        demoModeProvider.overrideWithValue(true),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: materialThemeOf(theme),
        localizationsDelegates: FLocalizations.localizationsDelegates,
        supportedLocales: FLocalizations.supportedLocales,
        builder: (context, c) => FTheme(
          data: theme,
          child: FToaster(child: FTooltipGroup(child: c!)),
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}
