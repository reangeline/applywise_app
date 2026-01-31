class Subscription {
  final String id;
  final String userId;
  final String plan; // 'free' or 'premium'
  final String status; // 'active' or 'canceled'
  final String platform; // 'web', 'ios', 'android'
  final String store; // 'stripe', 'APP_STORE', 'PLAY_STORE'
  final String? productId;
  final String? productName;
  final DateTime? currentPeriodEnd;
  final bool isActive;
  final SubscriptionFeatures features;

  Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.platform,
    required this.store,
    this.productId,
    this.productName,
    this.currentPeriodEnd,
    required this.isActive,
    required this.features,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'active',
      platform: json['platform'] ?? 'mobile',
      store: json['store'] ?? '',
      productId: json['product_id'],
      productName: json['product_name'],
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : null,
      isActive: json['is_active'] ?? false,
      features: SubscriptionFeatures.fromJson(json['features'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan': plan,
      'status': status,
      'platform': platform,
      'store': store,
      'product_id': productId,
      'product_name': productName,
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'is_active': isActive,
      'features': features.toJson(),
    };
  }

  bool get isPremium => plan == 'premium' && isActive;
  bool get isFree => !isPremium;

  Subscription copyWith({
    String? id,
    String? userId,
    String? plan,
    String? status,
    String? platform,
    String? store,
    String? productId,
    String? productName,
    DateTime? currentPeriodEnd,
    bool? isActive,
    SubscriptionFeatures? features,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      platform: platform ?? this.platform,
      store: store ?? this.store,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      isActive: isActive ?? this.isActive,
      features: features ?? this.features,
    );
  }
}

class SubscriptionFeatures {
  final bool basicAccess;
  final bool proAccess;

  SubscriptionFeatures({
    required this.basicAccess,
    required this.proAccess,
  });

  factory SubscriptionFeatures.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeatures(
      basicAccess: json['basic_access'] ?? true,
      proAccess: json['pro_access'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basic_access': basicAccess,
      'pro_access': proAccess,
    };
  }
}
