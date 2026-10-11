import '../../../../core/failures.dart';
import '../entities/user_session.dart';

abstract class AuthRepository {
  Future<({UserSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? renewedToken, Failure? failure})> refreshToken(
    String refreshToken,
  );
}
