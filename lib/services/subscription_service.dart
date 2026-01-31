import '../config/constants.dart';
import '../models/subscription.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SubscriptionService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<Subscription?> getSubscription() async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) return null;

      final response = await _apiService.get(
        AppConstants.subscriptionEndpoint,
        token: token,
      );

      return Subscription.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<String?> createCheckoutSession(String priceId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) return null;

      final response = await _apiService.post(
        AppConstants.checkoutEndpoint,
        {'price_id': priceId},
        token: token,
      );

      return response['checkout_url'];
    } catch (e) {
      return null;
    }
  }
}
