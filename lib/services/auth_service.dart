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
  }) async {
    try {
      print('🔵 SignUp: Enviando requisição para $email');
      
      final response = await _apiService.post(
        AppConstants.signUpEndpoint,
        {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      print('🔵 SignUp: Resposta recebida');
      print('📥 Response keys: ${response.keys.toList()}');

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
      print('🔓 Token decodificado: ${decodedToken.keys.toList()}');

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

      print('✅ SignUp: Usuário criado: ${user.email}');
      if (message != null) {
        print('📧 Mensagem do backend: $message');
      }

      print('💾 Salvando tokens...');
      print('💾 ID Token (primeiros 50 chars): ${idToken.substring(0, 50)}...');

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
      print('✅ Flag email_verified salva (do backend): $emailVerifiedBackend');
      
      print('✅ Tokens salvos com sucesso!');

      return AuthResult(
        success: true,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        message: message,
      );
    } catch (e) {
      print('❌ SignUp Error: $e');
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
      print('🔵 SignIn: Enviando requisição para $email');
      
      final response = await _apiService.post(
        AppConstants.signInEndpoint,
        {
          'email': email,
          'password': password,
        },
      );

      print('🔵 SignIn: Resposta recebida');
      print('📥 Response keys: ${response.keys.toList()}');

      // Backend pode retornar em PascalCase OU snake_case
      final accessToken = response['access_token'] ?? response['AccessToken'] as String?;
      final refreshToken = response['refresh_token'] ?? response['RefreshToken'] as String?;
      final idToken = response['id_token'] ?? response['IDToken'] ?? response['id_token'] as String?;

      if (accessToken == null || refreshToken == null || idToken == null) {
        throw Exception('Missing tokens in response');
      }

      // Decodificar IDToken (JWT) para pegar informações do usuário
      final decodedToken = JwtDecoder.decode(idToken);
      print('🔓 Token decodificado: ${decodedToken.keys.toList()}');

      // Extrair informações do usuário do token
      final userId = decodedToken['sub'] as String;
      final userEmail = decodedToken['email'] as String;
      final userName = decodedToken['name'] as String? ?? email.split('@')[0];

      final user = User(
        id: userId,
        email: userEmail,
        name: userName,
      );

      print('✅ SignIn: Login realizado: ${user.email}');

      print('💾 Salvando tokens...');
      print('💾 ID Token (primeiros 50 chars): ${idToken.substring(0, 50)}...');

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
      print('✅ Flag email_verified salva (do backend): $emailVerifiedBackend');
      
      print('✅ Tokens salvos com sucesso!');

      return AuthResult(
        success: true,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      print('❌ SignIn Error: $e');
      return AuthResult(
        success: false,
        error: _formatError(e),
      );
    }
  }

  Future<String?> refreshToken() async {
    try {
      print('🔵 RefreshToken: Iniciando...');
      
      final currentRefreshToken = await _storageService.getRefreshToken();
      if (currentRefreshToken == null) {
        print('⚠️  RefreshToken: Nenhum refresh token encontrado');
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
        print('✅ RefreshToken: Tokens atualizados');
        return newAccessToken;
      }

      return null;
    } catch (e) {
      print('❌ RefreshToken Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    print('🔵 SignOut: Limpando dados...');
    await _storageService.clearAll();
    print('✅ SignOut: Logout realizado');
  }

  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    try {
      print('🔵 ConfirmSignUp: Verificando código para $email');
      
      final response = await _apiService.post(
        AppConstants.confirmSignUpEndpoint,
        {
          'email': email,
          'code': code,
        },
      );

      print('✅ ConfirmSignUp: Email verificado com sucesso!');

      return AuthResult(success: true);
    } catch (e) {
      print('❌ ConfirmSignUp Error: $e');
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
      print('🔵 ResendCode: Reenviando código para $email');
      
      final response = await _apiService.post(
        AppConstants.resendCodeEndpoint,
        {
          'email': email,
        },
      );

      print('✅ ResendCode: Código reenviado!');

      return AuthResult(success: true);
    } catch (e) {
      print('❌ ResendCode Error: $e');
      return AuthResult(
        success: false,
        error: _formatError(e),
      );
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
    print('✅ Marcando email como verificado localmente');
    await _storageService.saveEmailVerified(true);
  }

  Future<bool> isEmailVerified() async {
    // Primeiro checar flag local
    final localFlag = _storageService.isEmailVerified();
    if (localFlag) {
      print('✅ Email verificado (flag local)');
      return true;
    }

    // Se não tiver flag local, checar JWT
    final idToken = await _storageService.getIdToken();
    if (idToken != null && idToken.isNotEmpty) {
      try {
        final decoded = JwtDecoder.decode(idToken);
        final verified = decoded['email_verified'] as bool? ?? false;
        print('🔍 Email verificado (JWT): $verified');
        return verified;
      } catch (e) {
        print('⚠️  Erro ao decodificar JWT: $e');
        return false;
      }
    }

    return false;
  }

  Future<bool> fetchEmailVerifiedFromBackend() async {
    try {
      print('🔍 Consultando /user/me para status de email...');

      // Pegar access token
      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) {
        print('⚠️  Sem access token, não pode consultar /user/me');
        return await isEmailVerified();
      }

      final response = await _apiService.get(
        AppConstants.userMeEndpoint,
        token: accessToken,
      );

      print('📥 /user/me response keys: ${response.keys.toList()}');

      final emailVerified = response['email_verified'] as bool? ?? false;

      print('✅ Email verificado (backend /user/me): $emailVerified');

      // Salvar flag local
      await _storageService.saveEmailVerified(emailVerified);
      print('💾 Flag local atualizada: $emailVerified');

      return emailVerified;
    } catch (e) {
      print('❌ Erro ao consultar /user/me: $e');

      final lower = e.toString().toLowerCase();

      // Se for erro de autenticação, tentar refresh do token e refazer a requisição
      if (lower.contains('unauthorized') ||
          lower.contains('invalid credentials') ||
          lower.contains('invalid token')) {
        try {
          print('🔵 fetchEmailVerifiedFromBackend: tentando refresh do token...');
          final newAccessToken = await refreshToken();
          if (newAccessToken != null) {
            print('🔵 fetchEmailVerifiedFromBackend: reconsultando /user/me com novo token');
            final retryResponse = await _apiService.get(
              AppConstants.userMeEndpoint,
              token: newAccessToken,
            );

            print('📥 /user/me (retry) response keys: ${retryResponse.keys.toList()}');
            final emailVerified = retryResponse['email_verified'] as bool? ?? false;
            await _storageService.saveEmailVerified(emailVerified);
            print('💾 Flag local atualizada após retry: $emailVerified');
            return emailVerified;
          } else {
            print('⚠️  Refresh não retornou novo access token');
          }
        } catch (e2) {
          print('❌ Erro ao reconsultar /user/me após refresh: $e2');
        }
      }

      // Fallback: usar flag local ou JWT
      return await isEmailVerified();
    }
  }

  String _formatError(dynamic error) {
    final errorString = error.toString();
    
    print('🔍 Formatting error: $errorString');
    
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
        lowerError.contains('not authorized')) {
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
        lowerError.contains('connection')) {
      return 'Connection error. Please check your internet.';
    }
    
    if (lowerError.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Retornar erro limpo se não for reconhecido
    return cleanError;
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
