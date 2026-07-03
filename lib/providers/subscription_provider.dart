import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/storage_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final RevenueCatService _revenueCatService = RevenueCatService();

  Subscription? _subscription;
  bool _isLoading = false;
  bool _isPro = false;
  List<Package> _packages = [];
  int _credits = 0;
  DateTime? _lastFetched;

  static const _cacheTtl = Duration(minutes: 5);

  Subscription? get subscription => _subscription;
  bool get isLoading => _isLoading;
  bool get isPro => _isPro;
  List<Package> get packages => _packages;
  int get credits => _credits;

  bool get _isCacheFresh =>
      _lastFetched != null &&
      DateTime.now().difference(_lastFetched!) < _cacheTtl;

  Future<void> loadSubscription({bool force = false}) async {
    // Cache fresh and not forced — instant return
    if (!force && _isCacheFresh) return;

    // Already have data and not forced — refresh silently in background
    if (!force && _subscription != null) {
      _fetchSubscription().catchError((_) {});
      return;
    }

    // First load or forced — show loading indicator
    _isLoading = true;
    notifyListeners();
    await _fetchSubscription();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchSubscription() async {
    final storage = StorageService();
    final currentUserId = storage.getUserId();
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      _subscription = await _subscriptionService.getSubscription();
      final status = await _revenueCatService.getSubscriptionStatus();
      _isPro = status['plan'] == 'premium';
      _packages = await _revenueCatService.getAvailablePackages();
      _credits = await _subscriptionService.getCredits();
      _lastFetched = DateTime.now();
    } catch (e) {
      _isPro = false;
      _packages = [];
      _credits = 0;
    }
    notifyListeners();
  }

  Future<bool> purchasePackage(Package package) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _revenueCatService.purchasePackage(package);

      if (success) {
        _isPro = true;
        await loadSubscription(force: true);
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _revenueCatService.restorePurchases();

      if (success) {
        _isPro = true;
        await loadSubscription(force: true);
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> createWebCheckout(String priceId) async {
    return await _subscriptionService.createCheckoutSession(priceId);
  }

  bool canAccessProFeature() {
    return _isPro;
  }

  /// Recarregar créditos (útil após compra)
  Future<void> refreshCredits() async {
    try {
      _credits = await _subscriptionService.getCredits();
      notifyListeners();
    } catch (e) {
    }
  }

  void reset() {
    _subscription = null;
    _isLoading = false;
    _isPro = false;
    _packages = [];
    _credits = 0;
    _lastFetched = null;
    notifyListeners();
  }
}
