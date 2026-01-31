import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final RevenueCatService _revenueCatService = RevenueCatService();

  AuthProvider() {
    // Register global token refresher so ApiService can retry on 401
    ApiService().registerTokenRefresher(_authService.refreshToken);
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
      
      // Initialize RevenueCat if authenticated
      if (_user != null) {
        try {
          await _revenueCatService.initialize(_user!.id);
        } catch (e) {
          debugPrint('Failed to initialize RevenueCat: $e');
        }
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
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signUp(
      email: email,
      password: password,
      name: name,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      _isAuthenticated = true;
      
      // Initialize RevenueCat after signup
      try {
        await _revenueCatService.initialize(_user!.id);
      } catch (e) {
        debugPrint('Failed to initialize RevenueCat: $e');
      }
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
      
      // Initialize RevenueCat after signin
      try {
        await _revenueCatService.initialize(_user!.id);
      } catch (e) {
        debugPrint('Failed to initialize RevenueCat: $e');
      }
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
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
}
