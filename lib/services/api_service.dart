import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Optional token refresher callback. Should return a new access token or null.
  Future<String?> Function()? _tokenRefresher;

  // Optional logout callback. Called when refresh fails (invalid session).
  Future<void> Function()? _logoutCallback;

  void registerTokenRefresher(Future<String?> Function() refresher) {
    _tokenRefresher = refresher;
  }

  void registerLogoutCallback(Future<void> Function() callback) {
    _logoutCallback = callback;
  }

  // Single-flight guard: if a refresh is in progress, other callers await the same future.
  Future<String?>? _refreshFuture;

  Future<String?> _performRefresh() async {
    if (_tokenRefresher == null) return null;

    // If a refresh is already in progress, await it
    if (_refreshFuture != null) {
      try {
        return await _refreshFuture;
      } catch (_) {
        return null;
      }
    }

    // Start a new refresh and store the future
    _refreshFuture = _tokenRefresher!();
    try {
      final result = await _refreshFuture;
      if (result == null) {
        // Refresh failed — session is invalid, force logout
        await _logoutCallback?.call();
      }
      return result;
    } catch (e) {
      await _logoutCallback?.call();
      return null;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final url = '${AppConstants.apiBaseUrl}$endpoint';
      
      http.Response response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );


      // Retry on 401 using registered refresher (single-flight)
      // Skip retry for the refresh endpoint itself to prevent deadlock
      if (response.statusCode == 401 &&
          _tokenRefresher != null &&
          endpoint != AppConstants.refreshTokenEndpoint) {
        final newToken = await _performRefresh();
        if (newToken != null) {
          response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
            body: jsonEncode(body),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    try {
      http.Response response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Retry on 401 using registered refresher (single-flight)
      if (response.statusCode == 401 && _tokenRefresher != null) {
        final newToken = await _performRefresh();
        if (newToken != null) {
          response = await http.get(
            Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // Método específico para retornar listas diretamente
  Future<dynamic> getRaw(
    String endpoint, {
    required String token,
  }) async {
    try {
      http.Response response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Retry on 401
      if (response.statusCode == 401 && _tokenRefresher != null) {
        final newToken = await _performRefresh();
        if (newToken != null) {
          response = await http.get(
            Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
          );
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    required String token,
  }) async {
    try {
      http.Response response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      // Retry on 401 using registered refresher (single-flight)
      if (response.statusCode == 401 && _tokenRefresher != null) {
        final newToken = await _performRefresh();
        if (newToken != null) {
          response = await http.put(
            Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
            body: jsonEncode(body),
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
  }) async {
    try {
      http.Response response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Retry on 401 using registered refresher (single-flight)
      if (response.statusCode == 401 && _tokenRefresher != null) {
        final newToken = await _performRefresh();
        if (newToken != null) {
          response = await http.delete(
            Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      
      try {
        final decoded = jsonDecode(response.body);
        
        // Se a resposta é uma lista (ex: lista de currículos)
        if (decoded is List) {
          return {'data': decoded}; // Não empacotar, retornar como está
        }
        
        // Se é um Map, retornar normalmente
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        
        // Caso contrário, tentar converter
        return {'data': decoded};
      } catch (e) {
        throw Exception('Failed to decode response: $e');
      }
    } else {
      // Tentar decodificar corpo do erro
      String errorMessage = 'Request failed with status ${response.statusCode}';
      
      if (response.body.isNotEmpty) {
        try {
          final errorBody = jsonDecode(response.body);
          
          // Extrair mensagem de erro do formato AWS
          if (errorBody is Map) {
            errorMessage = errorBody['message'] ?? 
                          errorBody['error'] ?? 
                          errorBody['Message'] ?? 
                          errorBody['__type'] ?? 
                          errorMessage;
          }
        } catch (e) {
          // Se não conseguir decodificar, usar o body raw
          errorMessage = response.body;
        }
      }
      
      
      // Lançar exceção com mensagem clara
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid credentials');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: Access denied');
      } else if (response.statusCode == 404) {
        throw Exception('Not found: Endpoint does not exist');
      } else if (response.statusCode == 500) {
        throw Exception('Server error: Please try again later');
      } else {
        throw Exception(errorMessage);
      }
    }
  }
}
