import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<Map<String, dynamic>> _notifications = [];
  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['read'] == false).length;
  bool get hasUnread => unreadCount > 0;
  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _notificationService.initialize();
      
      // Configurar listener para updates
      _notificationService.onNotificationsUpdated = (notifications) {
        _notifications = notifications;
        notifyListeners();
      };
      
      _notifications = _notificationService.getNotifications();
      _notificationsEnabled = await _notificationService.getNotificationsEnabled();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = true; // Marcar como inicializado mesmo com erro
      notifyListeners();
    }
  }

  /// Register a handler that is called whenever a push notification signals
  /// that a resume/LinkedIn optimization has completed.
  void setOptimizationCompleteHandler(Function(Map<String, dynamic>) handler) {
    _notificationService.onOptimizationComplete = handler;
  }

  void markAsRead(String id) {
    _notificationService.markAsRead(id);
    notifyListeners();
  }

  void markAllAsRead() {
    _notificationService.markAllAsRead();
    notifyListeners();
  }

  void clearNotification(String id) {
    _notificationService.clearNotification(id);
    notifyListeners();
  }

  void clearAll() {
    _notificationService.clearAll();
    notifyListeners();
  }

  void reset() {
    _notifications = [];
    _notificationsEnabled = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _notificationService.setNotificationsEnabled(value);
    _notificationsEnabled = value;
    notifyListeners();
  }

  Future<AuthorizationStatus> getPermissionStatus() async {
    return await _notificationService.getPermissionStatus();
  }
}
