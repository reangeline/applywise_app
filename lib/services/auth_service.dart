import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/constants.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String termsAcceptedAt,
    required String termsVersion,
    Map<String, dynamic>? parsedResume,
  }) async {
    try {
      
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'name': name,
        'terms_accepted_at': termsAcceptedAt,
        'terms_version': termsVersion,
      };
      if (parsedResume != null) body['parsed_resume'] = parsedResume;

      final response = await _apiService.post(
        AppConstants.signUpEndpoint,
        body,
      );


      // Backend pode retornar em PascalCase OU snake_case
      final accessToken = response['access_token'] ?? response['AccessToken'] as String?;
      final refreshToken = response['refresh_token'] ?? response['RefreshToken'] as String?;
      final idToken = response['id_token'] ?? response['IDToken'] ?? response['id_token'] as String?;
      final message = response['message'] as String?;

      if (accessToken == null || refreshToken == null || idToken == null) {
        throw Exception('Missing tokens in response');
      }

      // Decodificar IDToken (JWT) para pegar informações do usuário
      final decodedToken = JwtDecoder.decode(idToken);

      // Extrair informações do usuário do token
      final userId = decodedToken['sub'] as String;
      final userEmail = decodedToken['email'] as String;
      final userName = decodedToken['name'] as String? ?? name;
      final emailVerified = decodedToken['email_verified'] as bool? ?? false;

      final user = User(
        id: userId,
        email: userEmail,
        name: userName,
      );

      if (message != null) {
      }


      // Salvar tokens e dados do usuário
      await _storageService.saveAccessToken(accessToken);
      await _storageService.saveRefreshToken(refreshToken);
      await _storageService.saveIdToken(idToken);
      await _storageService.saveUserId(user.id);
      await _storageService.saveUserEmail(user.email);
      await _storageService.saveUserName(user.name);
      
      // Ler email_verified do response do backend (do DynamoDB!)
      final emailVerifiedBackend = response['email_verified'] as bool? ?? emailVerified;
      await _storageService.saveEmailVerified(emailVerifiedBackend);
      

      return AuthResult(
        success: true,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        message: message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: _formatError(e),
      );
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      
      final response = await _apiService.post(
        AppConstants.signInEndpoint,
        {
          'email': email,
          'password': password,
        },
      );


      // Backend pode retornar em PascalCase OU snake_case
      final accessToken = response['access_token'] ?? response['AccessToken'] as String?;
      final refreshToken = response['refresh_token'] ?? response['RefreshToken'] as String?;
      final idToken = response['id_token'] ?? response['IDToken'] ?? response['id_token'] as String?;

      if (accessToken == null || refreshToken == null || idToken == null) {
        throw Exception('Missing tokens in response');
      }

      // Decodificar IDToken (JWT) para pegar informações do usuário
      final decodedToken = JwtDecoder.decode(idToken);

      // Extrair informações do usuário do token
      final userId = decodedToken['sub'] as String;
      final userEmail = decodedToken['email'] as String;
      final userName = decodedToken['name'] as String? ?? email.split('@')[0];

      final user = User(
        id: userId,
        email: userEmail,
        name: userName,
      );



      // Salvar tokens e dados do usuário
      await _storageService.saveAccessToken(accessToken);
      await _storageService.saveRefreshToken(refreshToken);
      await _storageService.saveIdToken(idToken);
      await _storageService.saveUserId(user.id);
      await _storageService.saveUserEmail(user.email);
      await _storageService.saveUserName(user.name);
      
      // Ler email_verified do response do backend (do DynamoDB!)
      final emailVerifiedBackend = response['email_verified'] as bool? ?? false;
      await _storageService.saveEmailVerified(emailVerifiedBackend);
      

      return AuthResult(
        success: true,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: _formatError(e),
      );
    }
  }

  Future<String?> refreshToken() async {
    try {
      
      final currentRefreshToken = await _storageService.getRefreshToken();
      if (currentRefreshToken == null) {
        return null;
      }

      final response = await _apiService.post(
        AppConstants.refreshTokenEndpoint,
        {
          'refresh_token': currentRefreshToken,
        },
      );

      final newAccessToken = (response['access_token'] ?? response['accessToken'] ?? response['AccessToken']) as String?;
      final newRefreshToken = (response['refresh_token'] ?? response['refreshToken'] ?? response['RefreshToken']) as String?;

      if (newAccessToken != null) {
        await _storageService.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _storageService.saveRefreshToken(newRefreshToken);
        }
        return newAccessToken;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Returns a valid (non-expired) access token, refreshing it first if needed.
  /// Returns null if there is no token or if the refresh fails.
  Future<String?> ensureFreshAccessToken() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return null;

    try {
      if (JwtDecoder.isExpired(token)) {
        return await refreshToken();
      }
    } catch (_) {
      // If expiry check fails, attempt a refresh defensively.
      return await refreshToken();
    }

    return token;
  }

  Future<void> signOut() async {
    await _storageService.clearAll();
  }

  Future<AuthResult> updateProfile({required String name}) async {
    try {
      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) throw Exception('Not authenticated');

      final response = await _apiService.patch(
        AppConstants.userMeEndpoint,
        {'name': name},
        token: accessToken,
      );

      final updatedName = response['name'] as String? ?? name;
      await _storageService.saveUserName(updatedName);

      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: _formatError(e));
    }
  }

  Future<AuthResult> deleteAccount() async {
    try {

      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      await _apiService.delete(
        AppConstants.deleteAccountEndpoint,
        token: accessToken,
      );

      await _storageService.clearAll();

      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(
        success: false,
        error: _formatError(e),
      );
    }
  }

  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    try {
      
      await _apiService.post(
        AppConstants.confirmSignUpEndpoint,
        {
          'email': email,
          'code': code,
        },
      );


      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(
        success: false,
        error: _formatError(e),
      );
    }
  }

  Future<AuthResult> resendConfirmationCode({
    required String email,
  }) async {
    try {
      
      await _apiService.post(
        AppConstants.resendCodeEndpoint,
        {
          'email': email,
        },
      );


      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(
        success: false,
        error: _formatError(e),
      );
    }
  }

  Future<AuthResult> forgotPassword({
    required String email,
  }) async {
    try {

      await _apiService.post(
        AppConstants.forgotPasswordEndpoint,
        {'email': email},
      );

      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: _formatError(e));
    }
  }

  Future<AuthResult> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {

      await _apiService.post(
        AppConstants.confirmForgotPasswordEndpoint,
        {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );

      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, error: _formatError(e));
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getAccessToken();
    return token != null;
  }

  Future<User?> getCurrentUser() async {
    final userId = _storageService.getUserId();
    final email = _storageService.getUserEmail();
    final name = _storageService.getUserName();

    if (userId != null && email != null && name != null) {
      return User(id: userId, email: email, name: name);
    }
    return null;
  }

  Future<String?> getIdToken() async {
    return await _storageService.getIdToken();
  }

  Future<void> markEmailAsVerified() async {
    await _storageService.saveEmailVerified(true);
  }

  Future<bool> isEmailVerified() async {
    // Primeiro checar flag local
    final localFlag = _storageService.isEmailVerified();
    if (localFlag) {
      return true;
    }

    // Se não tiver flag local, checar JWT
    final idToken = await _storageService.getIdToken();
    if (idToken != null && idToken.isNotEmpty) {
      try {
        final decoded = JwtDecoder.decode(idToken);
        final verified = decoded['email_verified'] as bool? ?? false;
        return verified;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  Future<bool> fetchEmailVerifiedFromBackend() async {
    try {

      // Pegar access token
      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) {
        return await isEmailVerified();
      }

      final response = await _apiService.get(
        AppConstants.userMeEndpoint,
        token: accessToken,
      );


      final emailVerified = response['email_verified'] as bool? ?? false;


      // Salvar flag local
      await _storageService.saveEmailVerified(emailVerified);

      return emailVerified;
    } catch (e) {

      final lower = e.toString().toLowerCase();

      // Se for erro de autenticação, tentar refresh do token e refazer a requisição
      if (lower.contains('unauthorized') ||
          lower.contains('invalid credentials') ||
          lower.contains('invalid token')) {
        try {
          final newAccessToken = await refreshToken();
          if (newAccessToken != null) {
            final retryResponse = await _apiService.get(
              AppConstants.userMeEndpoint,
              token: newAccessToken,
            );

            final emailVerified = retryResponse['email_verified'] as bool? ?? false;
            await _storageService.saveEmailVerified(emailVerified);
            return emailVerified;
          } else {
          }
        } catch (e2) {
        }
      }

      // Fallback: usar flag local ou JWT
      return await isEmailVerified();
    }
  }

  String _formatError(dynamic error) {
    final errorString = error.toString();
    
    
    // Remover "Exception: " do início
    String cleanError = errorString;
    if (cleanError.startsWith('Exception: ')) {
      cleanError = cleanError.substring(11);
    }
    
    // Erros comuns do Cognito (case-insensitive)
    final lowerError = cleanError.toLowerCase();
    
    if (lowerError.contains('usernameexistsexception') || 
        lowerError.contains('user already exists') ||
        lowerError.contains('username exists')) {
      return 'This email is already registered. Please login instead.';
    }
    
    if (lowerError.contains('notauthorizedexception') ||
        lowerError.contains('not authorized') ||
        lowerError.contains('unauthorized') ||
        lowerError.contains('invalid credentials')) {
      return 'Invalid email or password';
    }
    
    if (lowerError.contains('usernotfoundexception') ||
        lowerError.contains('user not found')) {
      return 'User not found. Please sign up first.';
    }
    
    if (lowerError.contains('invalidpasswordexception') ||
        lowerError.contains('password') && lowerError.contains('requirement')) {
      return 'Password must be at least 6 characters';
    }
    
    if (lowerError.contains('network error') ||
        lowerError.contains('socketexception') ||
        lowerError.contains('failed host lookup') ||
        lowerError.contains('connection refused') ||
        (lowerError.contains('connection') && !lowerError.contains('invalid credentials'))) {
      return 'Connection error. Please check your internet.';
    }
    
    if (lowerError.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Retornar erro limpo se não for reconhecido
    return cleanError;
  }

  // ─── Social Authentication ────────────────────────────────────────────────

  /// Authenticates with a social provider token.
  ///
  /// The backend endpoint [AppConstants.socialAuthEndpoint] must accept:
  ///   { "provider": "apple"|"google", "id_token": "...", "name": "..." }
  /// and return the same token structure as signUp/signIn.
  Future<AuthResult> signInWithSocial({
    required String provider,
    required String idToken,
    String? name,
  }) async {
    try {
      final body = <String, dynamic>{
        'provider': provider,
        'id_token': idToken,
      };
      if (name != null && name.isNotEmpty) body['name'] = name;

      final response = await _apiService.post(
        AppConstants.socialAuthEndpoint,
        body,
      );

      final accessToken =
          (response['access_token'] ?? response['AccessToken']) as String?;
      final refreshToken =
          (response['refresh_token'] ?? response['RefreshToken']) as String?;
      final idTokenResp =
          (response['id_token'] ?? response['IDToken']) as String?;

      if (accessToken == null || refreshToken == null || idTokenResp == null) {
        throw Exception('Missing tokens in response');
      }

      final decoded = JwtDecoder.decode(idTokenResp);
      final userId = decoded['sub'] as String;
      final userEmail = decoded['email'] as String? ?? '';
      final userName =
          decoded['name'] as String? ?? name ?? userEmail.split('@').first;
      final emailVerified = decoded['email_verified'] as bool? ?? true;

      final user = User(id: userId, email: userEmail, name: userName);

      await _storageService.saveAccessToken(accessToken);
      await _storageService.saveRefreshToken(refreshToken);
      await _storageService.saveIdToken(idTokenResp);
      await _storageService.saveUserId(user.id);
      await _storageService.saveUserEmail(user.email);
      await _storageService.saveUserName(user.name);
      await _storageService.saveEmailVerified(
          response['email_verified'] as bool? ?? emailVerified);

      return AuthResult(
        success: true,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      return AuthResult(success: false, error: _formatError(e));
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? error;
  final String? message;

  AuthResult({
    required this.success,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.error,
    this.message,
  });
}
