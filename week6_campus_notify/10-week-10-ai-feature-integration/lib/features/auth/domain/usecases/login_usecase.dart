import '../../../../core/failures.dart';
import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<({UserSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) {
    if (!email.contains('@')) {
      return Future.value((
        session: null,
        failure: const ValidationFailure(
          'Format email tidak valid (harus mengandung @)',
        ),
      ));
    }
    if (password.length < 6) {
      return Future.value((
        session: null,
        failure: const ValidationFailure('Kata sandi minimal 6 karakter'),
      ));
    }
    return _repository.login(email: email, password: password);
  }
}
