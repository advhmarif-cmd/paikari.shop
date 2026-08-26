import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paikari_shop/core/theme/paikari_theme.dart';

void main() {
  test('Paikari brand theme uses DeepBlue, Golden, white and Tiro Bangla', () {
    final theme = PaikariTheme.lightTheme;

    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.colorScheme.primary, PaikariTheme.primaryColor);
    expect(theme.colorScheme.secondary, PaikariTheme.secondaryColor);
    expect(theme.textTheme.bodyLarge?.fontFamily, PaikariTheme.fontFamily);
    expect(
      theme.floatingActionButtonTheme.backgroundColor,
      PaikariTheme.secondaryColor,
    );
    expect(
      theme.floatingActionButtonTheme.foregroundColor,
      PaikariTheme.primaryColor,
    );
  });
}
