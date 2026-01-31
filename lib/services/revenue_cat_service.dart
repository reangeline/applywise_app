import 'package:applywise_app/config/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // ⚠️ SUBSTITUIR PELA SUA API KEY DO REVENUECAT!
  // Pegar em: https://app.revenuecat.com/settings/api-keys
  static const String _apiKey = AppConstants.revenueCatApiKey;
  
  bool _isInitialized = false;

  /// Inicializar RevenueCat com user ID
  Future<void> initialize(String userId) async {
    if (_isInitialized) {
      print('✅ RevenueCat já inicializado');
      return;
    }

    try {
      print('🔵 Inicializando RevenueCat (REAL) para: $userId');
      
      // Configurar logs (debug em development, error em production)
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );
      
      // Configurar SDK
      final configuration = PurchasesConfiguration(_apiKey)
        ..appUserID = userId;
      
      await Purchases.configure(configuration);
      
      _isInitialized = true;
      print('✅ RevenueCat (REAL) inicializado para: $userId');
    } catch (e) {
      print('❌ Erro ao inicializar RevenueCat: $e');
      rethrow;
    }
  }

  /// Buscar status da assinatura do usuário
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      print('🔍 Consultando status da assinatura...');
      
      final customerInfo = await Purchases.getCustomerInfo();
      
      // Checar entitlement "ApplyWise Premium"
      final proEntitlement = customerInfo.entitlements.all['ApplyWise Premium'];
      final hasPro = proEntitlement?.isActive ?? false;
      
      if (hasPro) {
        print('✅ Usuário tem assinatura PRO ativa');
        print('📅 Expira em: ${proEntitlement?.expirationDate}');
      } else {
        print('📊 Usuário no plano FREE');
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
      print('❌ Erro ao consultar assinatura: $e');
      
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
      print('🔍 Buscando pacotes disponíveis...');
      
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current == null) {
        print('⚠️  Nenhuma offering encontrada');
        return [];
      }
      
      final packages = offerings.current!.availablePackages;
      print('✅ ${packages.length} pacotes encontrados:');
      
      for (var package in packages) {
        print('📦 ${package.identifier}: ${package.storeProduct.priceString}');
      }
      
      return packages;
    } catch (e) {
      print('❌ Erro ao buscar pacotes: $e');
      return [];
    }
  }

  /// Comprar um pacote
  Future<bool> purchasePackage(Package package) async {
    try {
      print('💳 Iniciando compra: ${package.identifier}');
      
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      
      final hasPro = purchaseResult.customerInfo.entitlements.all['ApplyWise Premium']?.isActive ?? false;
      
      if (hasPro) {
        print('✅ Compra concluída com sucesso! PRO ativado!');
      } else {
        print('⚠️  Compra concluída mas PRO não ativado');
      }
      
      return hasPro;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        print('⚠️  Compra cancelada pelo usuário');
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        print('❌ Compra não permitida (configuração incorreta)');
      } else if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        print('⚠️  Produto já comprado');
      } else {
        print('❌ Erro na compra: ${e.message}');
      }
      
      return false;
    } catch (e) {
      print('❌ Erro inesperado na compra: $e');
      return false;
    }
  }

  /// Restaurar compras anteriores
  Future<bool> restorePurchases() async {
    try {
      print('🔄 Restaurando compras...');
      
      final customerInfo = await Purchases.restorePurchases();
      
      final hasPro = customerInfo.entitlements.all['ApplyWise Premium']?.isActive ?? false;
      
      if (hasPro) {
        print('✅ Compras restauradas! PRO ativado!');
      } else {
        print('⚠️  Nenhuma compra ativa encontrada');
      }
      
      return hasPro;
    } catch (e) {
      print('❌ Erro ao restaurar compras: $e');
      return false;
    }
  }

  /// Verificar se tem entitlement específico
  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      print('❌ Erro ao verificar entitlement: $e');
      return false;
    }
  }

  /// Logout (limpar user ID)
  Future<void> logout() async {
    try {
      print('🔵 Fazendo logout do RevenueCat...');
      await Purchases.logOut();
      _isInitialized = false;
      print('✅ Logout do RevenueCat concluído');
    } catch (e) {
      print('❌ Erro ao fazer logout: $e');
    }
  }
}
