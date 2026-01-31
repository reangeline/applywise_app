import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../services/revenue_cat_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final RevenueCatService _revenueCatService = RevenueCatService();

  Subscription? _subscription;
  bool _isLoading = false;
  bool _isPro = false;
  List<Package> _packages = [];

  Subscription? get subscription => _subscription;
  bool get isLoading => _isLoading;
  bool get isPro => _isPro;
  List<Package> get packages => _packages;

  Future<void> loadSubscription() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from backend
      _subscription = await _subscriptionService.getSubscription();
      
      // Check RevenueCat status
      final status = await _revenueCatService.getSubscriptionStatus();
      _isPro = status['plan'] == 'premium';
      
      // Load packages
      _packages = await _revenueCatService.getAvailablePackages();

      print('✅ Subscription loaded: isPro=$_isPro, packages=${_packages.length}');
    } catch (e) {
      print('❌ Erro ao carregar subscription: $e');
      _isPro = false;
      _packages = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> purchasePackage(Package package) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _revenueCatService.purchasePackage(package);

      if (success) {
        _isPro = true;
        await loadSubscription();
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      print('❌ Erro na compra: $e');
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
        await loadSubscription();
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      print('❌ Erro ao restaurar: $e');
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
}
