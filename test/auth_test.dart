import 'package:flutter_test/flutter_test.dart';
import 'package:smokeguard/data/models/user_model.dart';
import 'package:smokeguard/data/repositories/auth_repository.dart';
import 'package:smokeguard/features/auth/auth_controller.dart';

void main() {
  group('Phase 2 Auth & Session Unit Tests', () {
    test('UserModel.demo creates a valid demo user', () {
      final demo = UserModel.demo();
      expect(demo.isDemoUser, isTrue);
      expect(demo.email, equals('demo@smokeguard.app'));
      expect(demo.displayName, equals('Demo User'));
    });

    test('MockAuthRepository handles email login', () async {
      final repo = MockAuthRepository();
      final user = await repo.signInWithEmailPassword('test@example.com', 'password123');

      expect(user.email, equals('test@example.com'));
      expect(repo.currentUser?.email, equals('test@example.com'));
    });

    test('AuthController signInAsDemoUser updates state to authenticated', () async {
      final repo = MockAuthRepository();
      final controller = AuthController(repo);

      expect(controller.state.status, equals(AuthStatus.unauthenticated));

      await controller.signInAsDemoUser();

      expect(controller.state.status, equals(AuthStatus.authenticated));
      expect(controller.state.user?.isDemoUser, isTrue);
      expect(controller.state.user?.email, equals('demo@smokeguard.app'));
    });

    test('AuthController signOut resets state to unauthenticated', () async {
      final repo = MockAuthRepository();
      final controller = AuthController(repo);

      await controller.signInAsDemoUser();
      expect(controller.state.status, equals(AuthStatus.authenticated));

      await controller.signOut();
      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.state.user, isNull);
    });
  });
}
