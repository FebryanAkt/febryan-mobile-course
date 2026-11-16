import '../../../../core/failures.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<({UserSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!email.contains('@') || password.length < 6) {
        return (
          session: null,
          failure: const AuthFailure('Email atau kata sandi tidak valid'),
        );
      }
      final model = UserSessionModel(
        email: email,
        accessToken: 'mock-access-for-$email',
        refreshToken: 'mock-refresh-for-$email',
      );
      return (session: model.toEntity(), failure: null);
    } catch (e) {
      return (
        session: null,
        failure: AuthFailure('Gagal melakukan autentikasi: $e'),
      );
    }
  }

  @override
  Future<({String? renewedToken, Failure? failure})> refreshToken(
    String refreshToken,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      if (refreshToken.isEmpty) {
        return (
          renewedToken: null,
          failure: const AuthFailure('Refresh token tidak ditemukan'),
        );
      }
      final renewed =
          'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
      return (renewedToken: renewed, failure: null);
    } catch (e) {
      return (
        renewedToken: null,
        failure: AuthFailure('Gagal memperbarui token: $e'),
      );
    }
  }
}
