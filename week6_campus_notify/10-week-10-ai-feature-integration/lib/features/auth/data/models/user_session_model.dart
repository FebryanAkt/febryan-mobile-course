import '../../domain/entities/user_session.dart';

class UserSessionModel extends UserSession {
  const UserSessionModel({
    required super.email,
    required super.accessToken,
    required super.refreshToken,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'access_token': accessToken,
    'refresh_token': refreshToken,
  };

  factory UserSessionModel.fromMap(Map<String, dynamic> map) {
    return UserSessionModel(
      email: map['email']?.toString() ?? '',
      accessToken: map['access_token']?.toString() ?? '',
      refreshToken: map['refresh_token']?.toString() ?? '',
    );
  }

  UserSession toEntity() => UserSession(
    email: email,
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}
