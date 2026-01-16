import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:paikari_shop/main.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';

void main() {
  testWidgets(
    'AuthWrapper shows Signup when user logged in but userModel is null',
    (WidgetTester tester) async {
      // Mock Firebase User
      final mockUser = MockUser(
        uid: 'uid-123',
        email: 'test@example.com',
      );

      // Pump the widget with Riverpod overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // authStateProvider should return a Stream<User?>
            authStateProvider.overrideWith(
              (ref) => Stream.value(mockUser),
            ),

            // userProvider should return a Stream<UserModel?>
            userProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
          child: const PaikariApp(),
        ),
      );

      // Let the widget tree settle
      await tester.pumpAndSettle();

      // Expect Signup text to be visible
      expect(find.textContaining('নিবন্ধন করুন'), findsOneWidget);
    },
  );
}
