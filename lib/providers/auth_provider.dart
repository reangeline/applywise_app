import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final RevenueCatService _revenueCatService = RevenueCatService();
  final NotificationService _notificationService = NotificationService();

  AuthProvider() {
    // Register global token refresher so ApiService can retry on 401
    ApiService().registerTokenRefresher(_authService.refreshToken);
    // Register logout callback so ApiService can force logout when refresh fails
    ApiService().registerLogoutCallback(_handleSessionExpired);
  }

  Future<void> _handleSessionExpired() async {
    await _authService.signOut();
    await _revenueCatService.logout();
    _notificationService.resetPushRegistrationState();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> _finalizeAuthenticatedSession() async {
    if (_user == null) return;

    try {
      await _revenueCatService.initialize(_user!.id);
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
    }

    final registered = await _notificationService
        .ensurePushRegistrationForCurrentSession(force: true);
    if (!registered) {
      debugPrint('FCM token registration not confirmed for current session');
    }
  }

  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await _authService.isAuthenticated();
    if (_isAuthenticated) {
      _user = await _authService.getCurrentUser();
      if (_user != null) {
        await _finalizeAuthenticatedSession();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> fetchEmailVerifiedFromBackend() async {
    return await _authService.fetchEmailVerifiedFromBackend();
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String termsAcceptedAt,
    required String termsVersion,
    Map<String, dynamic>? parsedResume,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signUp(
      email: email,
      password: password,
      name: name,
      termsAcceptedAt: termsAcceptedAt,
      termsVersion: termsVersion,
      parsedResume: parsedResume,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      _isAuthenticated = true;
      await _finalizeAuthenticatedSession();
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signIn(
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      _isAuthenticated = true;
      await _finalizeAuthenticatedSession();
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _revenueCatService.logout();
    _notificationService.resetPushRegistrationState();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<AuthResult> updateProfile({required String name}) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.updateProfile(name: name);

    if (result.success && _user != null) {
      _user = _user!.copyWith(name: name);
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<AuthResult> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.deleteAccount();

    if (result.success) {
      await _revenueCatService.logout();
      _notificationService.resetPushRegistrationState();
      _user = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.confirmSignUp(
      email: email,
      code: code,
    );

    if (result.success) {
      // Marcar email como verificado localmente
      await _authService.markEmailAsVerified();
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<AuthResult> resendConfirmationCode({
    required String email,
  }) async {
    return await _authService.resendConfirmationCode(email: email);
  }

  Future<bool> refreshToken() async {
    final newToken = await _authService.refreshToken();
    return newToken != null;
  }

  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  Future<bool> isEmailVerified() async {
    return await _authService.isEmailVerified();
  }

  Future<AuthResult> forgotPassword({required String email}) async {
    return await _authService.forgotPassword(email: email);
  }

  Future<AuthResult> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return await _authService.confirmForgotPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  // ─── Social Authentication ────────────────────────────────────────────────

  /// Signs in with Apple ID.  The backend must implement POST /api/v1/auth/social.
  Future<AuthResult> signInWithApple() async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        return AuthResult(
            success: false, error: 'Could not retrieve Apple token.');
      }

      final name = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      final result = await _authService.signInWithSocial(
        provider: 'apple',
        idToken: idToken,
        name: name.isEmpty ? null : name,
      );

      if (result.success && result.user != null) {
        _user = result.user;
        _isAuthenticated = true;
        await _finalizeAuthenticatedSession();
      }
      return result;
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return AuthResult(success: false, error: 'Sign-in cancelled.');
      }
      return AuthResult(
          success: false, error: 'Error signing in with Apple. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in with Google.  The backend must implement POST /api/v1/auth/social.
  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        return AuthResult(success: false, error: 'Sign-in cancelled.');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return AuthResult(
            success: false, error: 'Could not retrieve Google token.');
      }

      final result = await _authService.signInWithSocial(
        provider: 'google',
        idToken: idToken,
        name: account.displayName,
      );

      if (result.success && result.user != null) {
        _user = result.user;
        _isAuthenticated = true;
        await _finalizeAuthenticatedSession();
      }
      return result;
    } catch (e) {
      return AuthResult(
          success: false,
          error: 'Error signing in with Google. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
