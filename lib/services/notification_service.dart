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
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  // Stream de notificações in-app
  final List<Map<String, dynamic>> _notifications = [];
  Function(List<Map<String, dynamic>>)? onNotificationsUpdated;
  
  bool _isInitialized = false;

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
    
    final settings = await _messaging!.requestPermission(
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
        await _sendTokenToBackend(token);
      }
      
      // Listener para quando o token é atualizado
      _messaging!.onTokenRefresh.listen(_sendTokenToBackend);
    } catch (e) {
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final authToken = await _storageService.getAccessToken();
      if (authToken == null) return;
      
      await _apiService.post(
        '/api/v1/users/me/fcm-token',
        {'fcm_token': token},
        token: authToken,
      );
      
    } catch (e) {
    }
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
  }

  void _handleNotificationClick(RemoteMessage message) {
    // Marcar como lida
    final id = message.messageId;
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['read'] = true;
      onNotificationsUpdated?.call(_notifications);
    }
    
    // Aqui você pode navegar para tela específica
    // baseado em message.data['type'] ou message.data['screen']
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
