import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Optional token refresher callback. Should return a new access token or null.
  Future<String?> Function()? _tokenRefresher;

  void registerTokenRefresher(Future<String?> Function() refresher) {
    _tokenRefresher = refresher;
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
      return result;
    } catch (e) {
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
      print('📡 POST: $url');
      print('📤 Body: ${jsonEncode(body)}');
      
      http.Response response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      // Retry on 401 using registered refresher (single-flight)
      if (response.statusCode == 401 && _tokenRefresher != null) {
        print('🔴 POST received 401, attempting token refresh...');
        final newToken = await _performRefresh();
        if (newToken != null) {
          print('🔵 POST retrying with new token');
          response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
            body: jsonEncode(body),
          );
          print('📥 (retry) Status: ${response.statusCode}');
          print('📥 (retry) Body: ${response.body}');
        }
      }

      return _handleResponse(response);
    } catch (e) {
      print('❌ Network error: $e');
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
        print('🔴 GET received 401, attempting token refresh...');
        final newToken = await _performRefresh();
        if (newToken != null) {
          print('🔵 GET retrying with new token');
          response = await http.get(
            Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
          );
          print('📥 (retry) Status: ${response.statusCode}');
          print('📥 (retry) Body: ${response.body}');
        }
      }

      return _handleResponse(response);
    } catch (e) {
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
        print('🔴 PUT received 401, attempting token refresh...');
        final newToken = await _performRefresh();
        if (newToken != null) {
          print('🔵 PUT retrying with new token');
          response = await http.put(
            Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
            body: jsonEncode(body),
          );
          print('📥 (retry) Status: ${response.statusCode}');
          print('📥 (retry) Body: ${response.body}');
        }
      }

      return _handleResponse(response);
    } catch (e) {
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
        print('🔴 DELETE received 401, attempting token refresh...');
        final newToken = await _performRefresh();
        if (newToken != null) {
          print('🔵 DELETE retrying with new token');
          response = await http.delete(
            Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
          );
          print('📥 (retry) Status: ${response.statusCode}');
          print('📥 (retry) Body: ${response.body}');
        }
      }

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    print('🔍 handleResponse - Status: ${response.statusCode}');
    print('🔍 handleResponse - Body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print('⚠️  Warning: Response body is empty, returning {}');
        return {};
      }
      
      try {
        final decoded = jsonDecode(response.body);
        
        // Se a resposta é uma lista (ex: lista de currículos vazia)
        if (decoded is List) {
          print('📋 Response is a List with ${decoded.length} items');
          return {'data': decoded}; // Empacotar lista em um Map
        }
        
        // Se é um Map, retornar normalmente
        if (decoded is Map<String, dynamic>) {
          print('✅ Response decoded successfully');
          return decoded;
        }
        
        // Caso contrário, tentar converter
        return {'data': decoded};
      } catch (e) {
        print('❌ Error decoding response: $e');
        throw Exception('Failed to decode response: $e');
      }
    } else {
      // Tentar decodificar corpo do erro
      String errorMessage = 'Request failed with status ${response.statusCode}';
      
      if (response.body.isNotEmpty) {
        try {
          final errorBody = jsonDecode(response.body);
          print('❌ Error body: $errorBody');
          
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
      
      print('❌ API Error: $errorMessage');
      
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
