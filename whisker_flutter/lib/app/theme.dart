import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'tokens.g.dart';

/// [FColors] calico dari token semantik.
FColors whiskerColors(Brightness brightness) {
  final s = brightness == Brightness.light
      ? WhiskerSemantic.light
      : WhiskerSemantic.dark;
  return FColors(
    brightness: brightness,
    systemOverlayStyle: brightness == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light,
    barrier: s.foreground.withValues(alpha: 0.3),
    background: s.background,
    foreground: s.foreground,
    primary: s.primary,
    primaryForeground: s.primaryForeground,
    secondary: s.secondary,
    secondaryForeground: s.secondaryForeground,
    muted: s.muted,
    mutedForeground: s.mutedForeground,
    destructive: s.destructive,
    destructiveForeground: s.destructiveForeground,
    error: s.error,
    errorForeground: s.errorForeground,
    card: s.card,
    border: s.border,
  );
}

/// Tema Forui Whisker; [touch] untuk Android/iOS (target sentuh ≥ 44 dp).
FThemeData whiskerTheme(Brightness brightness, {required bool touch}) =>
    FThemeData(colors: whiskerColors(brightness), touch: touch);

/// Token semantik tambahan (success, brand, …) untuk brightness aktif.
WhiskerSemantic semanticOf(Brightness brightness) =>
    brightness == Brightness.light
    ? WhiskerSemantic.light
    : WhiskerSemantic.dark;

/// Tema Material (Flutter) dari warna Forui, untuk widget Material seperti
/// `appflowy_editor`. `toApproximateMaterialTheme` milik Forui memakai paket
/// `material_ui`, bukan `package:flutter/material.dart`.
ThemeData materialThemeOf(FThemeData theme) {
  final c = theme.colors;
  return ThemeData(
    brightness: c.brightness,
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      secondary: c.secondary,
      onSecondary: c.secondaryForeground,
      error: c.error,
      onError: c.errorForeground,
      surface: c.background,
      onSurface: c.foreground,
      outline: c.border,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.primary,
      selectionColor: c.primary.withValues(alpha: 0.25),
    ),
  );
}
