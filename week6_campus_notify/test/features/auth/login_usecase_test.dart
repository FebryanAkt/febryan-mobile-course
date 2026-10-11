import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/core/failures.dart';
import 'package:week6_campus_notify/features/auth/domain/entities/user_session.dart';
import 'package:week6_campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:week6_campus_notify/features/auth/domain/usecases/login_usecase.dart';

class FakeAuthDomainRepository implements AuthRepository {
  FakeAuthDomainRepository({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<({UserSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      return (
        session: null,
        failure: const AuthFailure('Kredensial salah (simulasi)'),
      );
    }
    return (
      session: UserSession(
        email: email,
        accessToken: 'valid-access-token',
        refreshToken: 'valid-refresh-token',
      ),
      failure: null,
    );
  }

  @override
  Future<({String? renewedToken, Failure? failure})> refreshToken(
    String refreshToken,
  ) async {
    if (shouldFail) {
      return (
        renewedToken: null,
        failure: const AuthFailure('Refresh token revoked'),
      );
    }
    return (renewedToken: 'new-access-token', failure: null);
  }
}

void main() {
  group('LoginUseCase', () {
    test('returns ValidationFailure when email does not contain @', () async {
      final repo = FakeAuthDomainRepository();
      final useCase = LoginUseCase(repo);

      final result = await useCase(
        email: 'invalid-email',
        password: 'password123',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, contains('@'));
    });

    test('returns ValidationFailure when password is shorter than 6 chars', () async {
      final repo = FakeAuthDomainRepository();
      final useCase = LoginUseCase(repo);

      final result = await useCase(
        email: 'user@kampus.ac.id',
        password: '123',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, contains('minimal 6 karakter'));
    });

    test('returns UserSession on valid credentials', () async {
      final repo = FakeAuthDomainRepository();
      final useCase = LoginUseCase(repo);

      final result = await useCase(
        email: 'mahasiswa@kampus.ac.id',
        password: 'password123',
      );

      expect(result.failure, isNull);
      expect(result.session, isNotNull);
      expect(result.session?.email, 'mahasiswa@kampus.ac.id');
      expect(result.session?.accessToken, 'valid-access-token');
    });

    test('returns AuthFailure when repository fails', () async {
      final repo = FakeAuthDomainRepository(shouldFail: true);
      final useCase = LoginUseCase(repo);

      final result = await useCase(
        email: 'mahasiswa@kampus.ac.id',
        password: 'password123',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure?.message, contains('Kredensial salah'));
    });
  });
}
