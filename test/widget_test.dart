import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paikari_shop/main.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';

void main() {
  testWidgets('App smoke test shows the unauthenticated login screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
        child: const PaikariApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('লগইন'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
