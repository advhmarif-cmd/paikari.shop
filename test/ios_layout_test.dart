import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/auth/screens/signup_screen.dart';

Future<void> _pumpSignup(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: PaikariTheme.lightTheme,
        home: const SignupScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('signup consumer layout fits an iPhone viewport', (tester) async {
    await _pumpSignup(tester);

    expect(find.text('আপনার ভূমিকা নির্বাচন করুন'), findsOneWidget);
    expect(find.text('ক্রেতা (Consumer)'), findsOneWidget);
    expect(find.text('বিক্রেতা (Vendor)'), findsOneWidget);
    expect(find.text('অ্যাকাউন্ট তৈরি করুন'), findsOneWidget);
  });

  testWidgets('signup vendor selection remains usable on an iPhone viewport', (
    tester,
  ) async {
    await _pumpSignup(tester);

    await tester.tap(find.text('বিক্রেতা (Vendor)'));
    await tester.pump();
    expect(find.text('ব্যবসার নাম (Business Name)'), findsOneWidget);
    expect(find.textContaining('ট্রেড লাইসেন্স আপলোড করুন'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
