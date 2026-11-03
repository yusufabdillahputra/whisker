import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker/app/theme.dart';
import 'package:whisker/app/tokens.g.dart';

void main() {
  test('tema light memakai token semantik light', () {
    final t = whiskerTheme(Brightness.light, touch: false);
    expect(t.colors.primary, WhiskerSemantic.light.primary);
    expect(t.colors.primary, const Color(0xFFA75001));
    expect(t.colors.background, WhiskerSemantic.light.background);
  });

  test('tema dark memakai token semantik dark', () {
    final t = whiskerTheme(Brightness.dark, touch: true);
    expect(t.colors.primary, WhiskerSemantic.dark.primary);
    expect(t.colors.brightness, Brightness.dark);
  });
}
