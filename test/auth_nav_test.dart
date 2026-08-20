import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:paikari_shop/main.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';

void main() {
  testWidgets(
    'AuthWrapper shows Signup when a Supabase user has no profile',
    (WidgetTester tester) async {
      final mockUser = sb.User.fromJson({
        'id': 'uid-123',
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'test@example.com',
        'phone': '',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'identities': <dynamic>[],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(mockUser),
            ),
            userProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
          child: const PaikariApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('নিবন্ধন করুন'), findsOneWidget);
    },
  );
}
