import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';

class ShopPlanOption {
  final int id;
  final String text;

  const ShopPlanOption({required this.id, required this.text});
}

class ShopPlanChoice {
  final String featureName;
  final int chooseCount;
  final List<ShopPlanOption> options;

  const ShopPlanChoice({
    required this.featureName,
    required this.chooseCount,
    required this.options,
  });
}

class ShopPlan {
  final int id;
  final String name;
  final String? description;
  final double? monthlyPrice;
  final double? annualPrice;
  final bool hasAnnualPricing;
  final String billingPeriod;
  final bool isCustomPricing;
  final bool isPopular;
  final List<String> highlights;
  final List<ShopPlanChoice> choices;

  const ShopPlan({
    required this.id,
    required this.name,
    this.description,
    this.monthlyPrice,
    this.annualPrice,
    required this.hasAnnualPricing,
    required this.billingPeriod,
    required this.isCustomPricing,
    required this.isPopular,
    required this.highlights,
    required this.choices,
  });

  factory ShopPlan.fromJson(Map<String, dynamic> json) {
    final highlights = <String>[];
    final rawHighlights = json['highlights'];
    if (rawHighlights is List) {
      for (final item in rawHighlights) {
        if (item is Map && item['textEn'] is String && (item['textEn'] as String).trim().isNotEmpty) {
          highlights.add((item['textEn'] as String).trim());
        }
      }
    }

    final choices = <ShopPlanChoice>[];
    final rawFeatures = json['featureValues'];
    if (rawFeatures is List) {
      for (final item in rawFeatures) {
        if (item is! Map) continue;
        final feature = item['feature'];
        final featureKey = feature is Map ? feature['featureKey'] : null;
        final chooseCount = item['chooseCount'];
        final isChooseAll = item['isChooseAll'] == true;
        final offered = item['offeredOptions'];
        if (featureKey == null || chooseCount is! num || isChooseAll || offered is! List) {
          continue;
        }
        final options = <ShopPlanOption>[];
        for (final option in offered) {
          if (option is! Map || option['id'] is! num) continue;
          final text = (option['textEn'] as String?)?.trim();
          if (text == null || text.isEmpty) continue;
          options.add(ShopPlanOption(id: (option['id'] as num).toInt(), text: text));
        }
        if (options.isEmpty) continue;
        final name = feature is Map ? (feature['nameEn'] as String?)?.trim() : null;
        choices.add(
          ShopPlanChoice(
            featureName: (name == null || name.isEmpty) ? 'Options' : name,
            chooseCount: chooseCount.toInt(),
            options: options,
          ),
        );
      }
    }

    return ShopPlan(
      id: (json['id'] as num).toInt(),
      name: (json['nameEn'] as String?)?.trim().isNotEmpty == true
          ? (json['nameEn'] as String).trim()
          : 'Plan',
      description: (json['descriptionEn'] as String?)?.trim(),
      monthlyPrice: (json['price'] as num?)?.toDouble(),
      annualPrice: (json['annualPrice'] as num?)?.toDouble(),
      hasAnnualPricing: json['hasAnnualPricing'] == true,
      billingPeriod: (json['billingPeriod'] as String?) ?? 'MONTHLY',
      isCustomPricing: json['isCustomPricing'] == true,
      isPopular: json['isPopular'] == true,
      highlights: highlights,
      choices: choices,
    );
  }
}

class ShopSubscriptionSummary {
  final int id;
  final String planName;
  final String status;
  final String? billingPeriod;
  final double? amount;
  final int? daysRemaining;
  final String? rejectReason;

  const ShopSubscriptionSummary({
    required this.id,
    required this.planName,
    required this.status,
    this.billingPeriod,
    this.amount,
    this.daysRemaining,
    this.rejectReason,
  });

  factory ShopSubscriptionSummary.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    final planName = plan is Map ? (plan['nameEn'] as String?) : null;
    return ShopSubscriptionSummary(
      id: (json['id'] as num).toInt(),
      planName: (planName == null || planName.trim().isEmpty) ? 'Plan' : planName.trim(),
      status: (json['status'] as String?) ?? '',
      billingPeriod: json['billingPeriod'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
      rejectReason: (json['rejectReason'] as String?)?.trim(),
    );
  }
}

class PlatformPaymentAccount {
  final int id;
  final String methodName;
  final String accountName;
  final String accountNumber;
  final String? qrUrl;
  final String? note;

  const PlatformPaymentAccount({
    required this.id,
    required this.methodName,
    required this.accountName,
    required this.accountNumber,
    this.qrUrl,
    this.note,
  });

  factory PlatformPaymentAccount.fromJson(Map<String, dynamic> json) {
    final method = json['paymentMethod'];
    return PlatformPaymentAccount(
      id: (json['id'] as num).toInt(),
      methodName: method is Map ? ((method['name'] as String?) ?? 'Transfer') : 'Transfer',
      accountName: (json['accountName'] as String?) ?? '',
      accountNumber: (json['accountNumber'] as String?) ?? '',
      qrUrl: json['qrUrl'] as String?,
      note: (json['note'] as String?)?.trim(),
    );
  }
}

class SubscriptionService {
  Future<List<ShopPlan>> getPlans() async {
    final response = await ApiClient().dio.get(
      '/api/shop/plans',
      queryParameters: {'page': 1, 'size': 50},
    );
    final data = response.data;
    if (data is Map && data['success'] == true && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((item) => ShopPlan.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<ShopSubscriptionSummary?> getCurrent() async {
    final response = await ApiClient().dio.get('/api/shop/subscriptions/current');
    final data = response.data;
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return ShopSubscriptionSummary.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }
    return null;
  }

  Future<List<ShopSubscriptionSummary>> getHistory() async {
    final response = await ApiClient().dio.get(
      '/api/shop/subscriptions',
      queryParameters: {'page': 1, 'size': 20},
    );
    final data = response.data;
    if (data is Map && data['success'] == true && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((item) => ShopSubscriptionSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<List<PlatformPaymentAccount>> getPaymentAccounts() async {
    final response = await ApiClient().dio.get('/api/shop/platform-payment-accounts');
    final data = response.data;
    if (data is Map && data['success'] == true && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((item) => PlatformPaymentAccount.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  /// Confirms a plan. Payment is not collected yet.
  Future<String> confirm({
    required int planId,
    required String billingPeriod,
    List<int> selectedOptionIds = const [],
  }) async {
    final form = FormData.fromMap({
      'planId': planId,
      'billingPeriod': billingPeriod,
      if (selectedOptionIds.isNotEmpty) 'selectedOptionIds': selectedOptionIds.join(','),
    });

    try {
      final response = await ApiClient().dio.post('/api/shop/subscriptions', data: form);
      final data = response.data;
      if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
      return 'Plan confirmed. A SuperAdmin will turn it on.';
    } on DioException catch (error) {
      throw ApiHelper.handleError(error, context: 'SubscriptionService.confirm');
    }
  }
}
