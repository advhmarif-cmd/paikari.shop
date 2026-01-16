// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:paikari_shop/main.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set a large test view size so the login layout doesn't overflow.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame. Override the auth provider so
    // the app shows the unauthenticated login screen in tests.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null))
      ],
      child: const PaikariApp(),
    ));
    await tester.pumpAndSettle();

    // Verify that we are on the login screen.
    // Note: We use find.textContaining as the strings come from localizations.
    expect(find.textContaining('লগইন'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
