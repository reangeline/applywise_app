import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'api_service.dart';

// Handler para notificações em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by main()
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _fcmTokenEndpoint = '/api/v1/users/me/fcm-token';

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  // Stream de notificações in-app
  final List<Map<String, dynamic>> _notifications = [];
  Function(List<Map<String, dynamic>>)? onNotificationsUpdated;

  /// Fired whenever a push arrives indicating an optimization completed.
  /// Receives the FCM `data` map so the handler can fetch the right resume.
  Function(Map<String, dynamic>)? onOptimizationComplete;
  
  bool _isInitialized = false;
  bool _isPushReadyForCurrentSession = false;
  String? _lastRegisteredUserId;
  String? _lastRegisteredFcmToken;

  bool get isPushReadyForCurrentSession => _isPushReadyForCurrentSession;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Firebase is already initialized in main() — skip re-initialization

      // Inicializar messaging
      _messaging = FirebaseMessaging.instance;
      
      // Configurar handler de background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Solicitar permissões
      await _requestPermissions();
      
      // Configurar notificações locais
      await _configureLocalNotifications();
      
      // Obter token FCM e enviar para backend
      await _getFCMTokenAndSendToBackend();
      
      // Configurar listeners
      _setupMessageHandlers();
      
      _isInitialized = true;
    } catch (e) {
      // Não falhar - apenas logar e continuar sem notificações push
    }
  }

  Future<void> _requestPermissions() async {
    if (_messaging == null) return;
    
    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    

    // Garantir exibição em foreground no iOS
    await _messaging!.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Aqui você pode navegar para tela específica baseado no payload
  }

  Future<void> _getFCMTokenAndSendToBackend() async {
    if (_messaging == null) return;
    
    try {
      final token = await _messaging!.getToken();
      if (token != null) {
        await _sendTokenToBackend(token, force: true);
      }
      
      // Listener para quando o token é atualizado
      _messaging!.onTokenRefresh.listen((token) async {
        _markPushUnready();
        await _sendTokenToBackend(token, force: true);
      });
    } catch (e) {
      _markPushUnready();
    }
  }

  void _markPushUnready() {
    _isPushReadyForCurrentSession = false;
  }

  Future<bool> _sendTokenToBackend(
    String token, {
    bool force = false,
  }) async {
    try {
      final authToken = await _storageService.getAccessToken();
      final userId = _storageService.getUserId();
      if (authToken == null || userId == null || token.isEmpty) {
        _markPushUnready();
        return false;
      }

      if (!force &&
          _isPushReadyForCurrentSession &&
          _lastRegisteredUserId == userId &&
          _lastRegisteredFcmToken == token) {
        return true;
      }
      
      await _apiService.post(
        _fcmTokenEndpoint,
        {'fcm_token': token},
        token: authToken,
      );

      _isPushReadyForCurrentSession = true;
      _lastRegisteredUserId = userId;
      _lastRegisteredFcmToken = token;
      return true;
    } catch (e) {
      _markPushUnready();
      return false;
    }
  }

  Future<bool> ensurePushRegistrationForCurrentSession({bool force = false}) async {
    _messaging ??= FirebaseMessaging.instance;

    final authToken = await _storageService.getAccessToken();
    final userId = _storageService.getUserId();
    if (authToken == null || userId == null) {
      _markPushUnready();
      return false;
    }

    final token = await _messaging!.getToken();
    if (token == null || token.isEmpty) {
      _markPushUnready();
      return false;
    }

    return _sendTokenToBackend(token, force: force);
  }

  void resetPushRegistrationState() {
    _isPushReadyForCurrentSession = false;
    _lastRegisteredUserId = null;
    _lastRegisteredFcmToken = null;
  }

  void _setupMessageHandlers() {
    // Mensagem recebida quando app está em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      
      // Adicionar à lista de notificações in-app
      _addInAppNotification(message);
      
      // Evitar duplicidade: só mostrar local se for data-only
      final isDataOnly = message.notification == null;
      if (isDataOnly) {
        _showLocalNotification(message);
      }
    });

    // Mensagem clicada quando app em background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });
    
    // Verificar se foi aberto por uma notificação
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    if (_messaging == null) return;
    
    final message = await _messaging!.getInitialMessage();
    if (message != null) {
      _handleNotificationClick(message);
    }
  }

  void _addInAppNotification(RemoteMessage message) {
    final notification = {
      'id': message.messageId ?? DateTime.now().toString(),
      'title': message.notification?.title ?? 'Notification',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    };
    
    _notifications.insert(0, notification);
    onNotificationsUpdated?.call(_notifications);

    // Fire optimization-complete callback so the pipeline card updates instantly
    _maybeFireOptimizationComplete(message.data);
  }

  void _handleNotificationClick(RemoteMessage message) {
    // Marcar como lida
    final id = message.messageId;
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['read'] = true;
      onNotificationsUpdated?.call(_notifications);
    }
    
    // Fire optimization-complete callback (handles tap-from-background case)
    _maybeFireOptimizationComplete(message.data);
  }

  static const _kOptimizationTypes = {
    'resume_optimized',
    'resume_ready',
    'linkedin_optimized',
    'linkedin_ready',
    'optimization_complete',
  };

  void _maybeFireOptimizationComplete(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type != null && _kOptimizationTypes.contains(type)) {
      onOptimizationComplete?.call(data);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data.toString(),
    );
  }

  // ── Notification enable / permission ──────────────────────────────────────

  static const String _notificationsEnabledKey = 'notifications_enabled';

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (enabled) {
      await _requestPermissions();
      await _getFCMTokenAndSendToBackend();
    } else {
      try {
        await _messaging?.deleteToken();
      } catch (e) {
        _markPushUnready();
      }
    }
  }

  Future<AuthorizationStatus> getPermissionStatus() async {
    if (_messaging == null) return AuthorizationStatus.notDetermined;
    final settings = await _messaging!.getNotificationSettings();
    return settings.authorizationStatus;
  }

  // ── Métodos públicos ─────────────────────────────────────────────────────

  List<Map<String, dynamic>> getNotifications() => _notifications;
  
  int getUnreadCount() => _notifications.where((n) => n['read'] == false).length;
  
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['read'] = true;
      onNotificationsUpdated?.call(_notifications);
    }
  }
  
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['read'] = true;
    }
    onNotificationsUpdated?.call(_notifications);
  }
  
  void clearNotification(String id) {
    _notifications.removeWhere((n) => n['id'] == id);
    onNotificationsUpdated?.call(_notifications);
  }
  
  void clearAll() {
    _notifications.clear();
    onNotificationsUpdated?.call(_notifications);
  }
}
