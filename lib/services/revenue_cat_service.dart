import 'package:applywise_app/config/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  static const String _apiKey = AppConstants.revenueCatApiKey;
  
  bool _isInitialized = false;

  /// Inicializar RevenueCat com user ID
  Future<void> initialize(String userId) async {
    if (_isInitialized) {
      return;
    }

    try {
      
      // Configurar logs (debug em development, error em production)
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );
      
      // Configurar SDK
      final configuration = PurchasesConfiguration(_apiKey)
        ..appUserID = userId;
      
      await Purchases.configure(configuration);
      
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Buscar status da assinatura do usuário
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      
      final customerInfo = await Purchases.getCustomerInfo();
      
      // Checar entitlement pro
      final proEntitlement = customerInfo.entitlements.all[AppConstants.proEntitlement];
      final hasPro = proEntitlement?.isActive ?? false;
      
      if (hasPro) {
      } else {
      }
      
      return {
        'plan': hasPro ? 'premium' : 'free',
        'status': hasPro ? 'active' : 'inactive',
        'features': {
          'basic_access': true,
          'pro_access': hasPro,
        },
      };
    } catch (e) {
      
      // Fallback: free tier
      return {
        'plan': 'free',
        'status': 'active',
        'features': {
          'basic_access': true,
          'pro_access': false,
        },
      };
    }
  }

  /// Buscar pacotes de assinatura disponíveis
  Future<List<Package>> getAvailablePackages() async {
    try {
      
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current == null) {
        return [];
      }
      
      final packages = offerings.current!.availablePackages;
      
      for (var package in packages) {
      }
      
      return packages;
    } catch (e) {
      return [];
    }
  }

  /// Comprar um pacote
  Future<bool> purchasePackage(Package package) async {
    try {
      
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      
      final hasPro = purchaseResult.customerInfo.entitlements.all[AppConstants.proEntitlement]?.isActive ?? false;
      
      if (hasPro) {
      } else {
      }
      
      return hasPro;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
      } else if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
      } else {
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Restaurar compras anteriores
  Future<bool> restorePurchases() async {
    try {
      
      final customerInfo = await Purchases.restorePurchases();
      
      final hasPro = customerInfo.entitlements.all[AppConstants.proEntitlement]?.isActive ?? false;
      
      if (hasPro) {
      } else {
      }
      
      return hasPro;
    } catch (e) {
      return false;
    }
  }

  /// Verificar se tem entitlement específico
  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Logout (limpar user ID)
  Future<void> logout() async {
    try {
      await Purchases.logOut();
      _isInitialized = false;
    } catch (e) {
    }
  }

  /// Buscar produtos de créditos (compras consumíveis)
  Future<List<StoreProduct>> getCreditProducts() async {
    try {
      
      final products = await Purchases.getProducts(
        ['credits_5', 'credits_10', 'credits_20'],
        type: PurchaseType.inapp,
      );
      
      for (var product in products) {
      }
      
      return products;
    } catch (e) {
      return [];
    }
  }

  /// Comprar produto de créditos (compra consumível)
  Future<bool> purchaseCreditProduct(StoreProduct product) async {
    try {
      
      final purchaseResult = await Purchases.purchaseStoreProduct(product);
      
      // Para compras consumíveis, verificar se a transação foi registrada
      final hasTransaction = purchaseResult.customerInfo.nonSubscriptionTransactions.isNotEmpty;
      
      if (hasTransaction) {
      } else {
      }
      
      return hasTransaction;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
      } else {
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}
