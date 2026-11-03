// GENERATED oleh design/tools/gen-dart-tokens.py — jangan diedit manual.
// Sumber: design/tokens/whisker.tokens.json

import 'dart:ui';

/// Skala warna calico mentah.
abstract final class WhiskerTokens {
  static const fur50 = Color(0xFFFEF9F4);
  static const fur100 = Color(0xFFF8F1EA);
  static const fur200 = Color(0xFFECE4DA);
  static const fur300 = Color(0xFFDBD1C6);
  static const fur400 = Color(0xFFC2B9AE);
  static const fur500 = Color(0xFFA79E95);
  static const fur600 = Color(0xFF8C857D);
  static const fur700 = Color(0xFF716B63);
  static const fur800 = Color(0xFF57514B);
  static const fur900 = Color(0xFF3C3731);
  static const fur950 = Color(0xFF221E1A);
  static const ginger50 = Color(0xFFFEF9F6);
  static const ginger100 = Color(0xFFFEEFE7);
  static const ginger200 = Color(0xFFFEDECB);
  static const ginger300 = Color(0xFFFFC4A1);
  static const ginger400 = Color(0xFFFEA065);
  static const ginger500 = Color(0xFFF47806);
  static const ginger600 = Color(0xFFCD6505);
  static const ginger700 = Color(0xFFA75001);
  static const ginger800 = Color(0xFF813C00);
  static const ginger900 = Color(0xFF5A2800);
  static const ginger950 = Color(0xFF351500);
  static const jade50 = Color(0xFFF1FEF3);
  static const jade100 = Color(0xFFE0FBE5);
  static const jade200 = Color(0xFFC5F3CD);
  static const jade300 = Color(0xFFA3E6B0);
  static const jade400 = Color(0xFF79D28D);
  static const jade500 = Color(0xFF56B870);
  static const jade600 = Color(0xFF429C5A);
  static const jade700 = Color(0xFF307E46);
  static const jade800 = Color(0xFF246135);
  static const jade900 = Color(0xFF154222);
  static const jade950 = Color(0xFF072610);
  static const nose50 = Color(0xFFFEF8F9);
  static const nose100 = Color(0xFFFEEEF0);
  static const nose200 = Color(0xFFFEDBDF);
  static const nose300 = Color(0xFFFFBFC7);
  static const nose400 = Color(0xFFFF98A8);
  static const nose500 = Color(0xFFFA6786);
  static const nose600 = Color(0xFFDF466C);
  static const nose700 = Color(0xFFB83255);
  static const nose800 = Color(0xFF8E2641);
  static const nose900 = Color(0xFF64162B);
  static const nose950 = Color(0xFF3C0816);
}

/// Warna semantik untuk satu brightness.
final class WhiskerSemantic {
  final Color background;
  final Color foreground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color error;
  final Color errorForeground;
  final Color card;
  final Color border;
  final Color input;
  final Color ring;
  final Color success;
  final Color successForeground;
  final Color brand;

  const WhiskerSemantic({
    required this.background,
    required this.foreground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.error,
    required this.errorForeground,
    required this.card,
    required this.border,
    required this.input,
    required this.ring,
    required this.success,
    required this.successForeground,
    required this.brand,
  });

  static const light = WhiskerSemantic(
    background: WhiskerTokens.fur50,
    foreground: WhiskerTokens.fur950,
    primary: WhiskerTokens.ginger700,
    primaryForeground: WhiskerTokens.fur50,
    secondary: WhiskerTokens.fur100,
    secondaryForeground: WhiskerTokens.fur900,
    muted: WhiskerTokens.fur100,
    mutedForeground: WhiskerTokens.fur700,
    destructive: WhiskerTokens.nose700,
    destructiveForeground: WhiskerTokens.fur50,
    error: WhiskerTokens.nose700,
    errorForeground: WhiskerTokens.fur50,
    card: Color(0xFFFFFFFF),
    border: WhiskerTokens.fur200,
    input: WhiskerTokens.fur600,
    ring: WhiskerTokens.ginger600,
    success: WhiskerTokens.jade700,
    successForeground: WhiskerTokens.fur50,
    brand: WhiskerTokens.ginger500,
  );

  static const dark = WhiskerSemantic(
    background: WhiskerTokens.fur950,
    foreground: WhiskerTokens.fur50,
    primary: WhiskerTokens.ginger400,
    primaryForeground: WhiskerTokens.fur950,
    secondary: WhiskerTokens.fur900,
    secondaryForeground: WhiskerTokens.fur50,
    muted: WhiskerTokens.fur900,
    mutedForeground: WhiskerTokens.fur400,
    destructive: WhiskerTokens.nose400,
    destructiveForeground: WhiskerTokens.fur950,
    error: WhiskerTokens.nose400,
    errorForeground: WhiskerTokens.fur950,
    card: WhiskerTokens.fur900,
    border: WhiskerTokens.fur800,
    input: WhiskerTokens.fur600,
    ring: WhiskerTokens.ginger400,
    success: WhiskerTokens.jade400,
    successForeground: WhiskerTokens.fur950,
    brand: WhiskerTokens.ginger500,
  );
}
