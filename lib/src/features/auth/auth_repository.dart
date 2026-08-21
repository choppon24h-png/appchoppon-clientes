import '../../core/network/api_client.dart';
import '../../core/storage/token_store.dart';
import '../../shared/models.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  Future<AuthSession> login({required String email, required String password}) async {
    final response = await _api.post(
      'auth/login.php',
      body: {'email': email.trim(), 'password': password},
    );
    final data = Map<String, dynamic>.from(response['data'] as Map? ?? const {});
    final tokens = Map<String, dynamic>.from(data['tokens'] as Map? ?? data);
    final session = AuthSession(
      accessToken: tokens['access_token']?.toString() ?? '',
      refreshToken: tokens['refresh_token']?.toString() ?? '',
      expiresIn: (tokens['expires_in'] as num?)?.toInt() ?? 3600,
    );
    if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
      throw const ApiException('A API nao retornou uma sessao valida');
    }
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  Future<bool> hasSession() async {
    final token = await _tokens.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      await _api.post('auth/logout.php', requiresAuth: true);
    } finally {
      await _tokens.clear();
    }
  }
}
