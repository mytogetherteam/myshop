class SubscriptionListResult {
  final List<SubscriptionModel> items;
  final int total;
  final int page;
  final bool hasMore;

  const SubscriptionListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class SubscriptionModel {
  final int id;
  final int shopId;
  final int planId;
  final SubscriptionPlanRef? plan;
  final String billingPeriod;
  final double? amount;
  final String status;
  final String source;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final int? daysRemaining;
  final String? rejectReason;
  final String? adminNote;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SubscriptionPaymentModel? latestPayment;
  final List<SubscriptionPaymentModel> payments;
  final List<SubscriptionQuotaModel> quotas;
  final List<SubscriptionOptionModel> options;

  const SubscriptionModel({
    required this.id,
    required this.shopId,
    required this.planId,
    this.plan,
    this.billingPeriod = 'MONTHLY',
    this.amount,
    required this.status,
    this.source = 'SHOP_REQUEST',
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.daysRemaining,
    this.rejectReason,
    this.adminNote,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
    this.latestPayment,
    this.payments = const [],
    this.quotas = const [],
    this.options = const [],
  });

  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
  bool get isActive => status == 'ACTIVE';
  bool get canResubmitSlip {
    if (isActive || status == 'CANCELED' || status == 'EXPIRED') return false;
    final latest = latestPayment;
    if (latest == null) return true;
    return latest.status != 'PENDING';
  }

  String get planName => plan?.nameEn ?? 'Plan';

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: _asInt(json['id']) ?? 0,
      shopId: _asInt(json['shopId']) ?? 0,
      planId: _asInt(json['planId']) ?? 0,
      plan: json['plan'] is Map
          ? SubscriptionPlanRef.fromJson(
              Map<String, dynamic>.from(json['plan'] as Map),
            )
          : null,
      billingPeriod: json['billingPeriod']?.toString() ?? 'MONTHLY',
      amount: _asDouble(json['amount']),
      status: json['status']?.toString() ?? '',
      source: json['source']?.toString() ?? 'SHOP_REQUEST',
      startDate: _asDate(json['startDate']),
      endDate: _asDate(json['endDate']),
      isCurrent: json['isCurrent'] == true,
      daysRemaining: _asInt(json['daysRemaining']),
      rejectReason: json['rejectReason']?.toString(),
      adminNote: json['adminNote']?.toString(),
      reviewedAt: _asDate(json['reviewedAt']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
      latestPayment: json['latestPayment'] is Map
          ? SubscriptionPaymentModel.fromJson(
              Map<String, dynamic>.from(json['latestPayment'] as Map),
            )
          : null,
      payments: (json['payments'] is List)
          ? (json['payments'] as List)
              .whereType<Map>()
              .map(
                (e) => SubscriptionPaymentModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      quotas: (json['quotas'] is List)
          ? (json['quotas'] as List)
              .whereType<Map>()
              .map(
                (e) => SubscriptionQuotaModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      options: (json['options'] is List)
          ? (json['options'] as List)
              .whereType<Map>()
              .map(
                (e) => SubscriptionOptionModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class SubscriptionPlanRef {
  final int id;
  final String code;
  final String nameEn;
  final double? price;
  final double? annualPrice;
  final bool isCustomPricing;

  const SubscriptionPlanRef({
    required this.id,
    required this.code,
    required this.nameEn,
    this.price,
    this.annualPrice,
    this.isCustomPricing = false,
  });

  factory SubscriptionPlanRef.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanRef(
      id: _asInt(json['id']) ?? 0,
      code: json['code']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      price: _asDouble(json['price']),
      annualPrice: _asDouble(json['annualPrice']),
      isCustomPricing: json['isCustomPricing'] == true,
    );
  }
}

class SubscriptionPaymentModel {
  final int id;
  final double? amount;
  final String? screenshotUrl;
  final String status;
  final DateTime? paidAt;
  final String? transferRef;
  final String? rejectReason;
  final DateTime? createdAt;
  final Map<String, dynamic>? platformAccount;

  const SubscriptionPaymentModel({
    required this.id,
    this.amount,
    this.screenshotUrl,
    required this.status,
    this.paidAt,
    this.transferRef,
    this.rejectReason,
    this.createdAt,
    this.platformAccount,
  });

  factory SubscriptionPaymentModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentModel(
      id: _asInt(json['id']) ?? 0,
      amount: _asDouble(json['amount']),
      screenshotUrl: json['screenshotUrl']?.toString(),
      status: json['status']?.toString() ?? '',
      paidAt: _asDate(json['paidAt']),
      transferRef: json['transferRef']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      createdAt: _asDate(json['createdAt']),
      platformAccount: json['platformAccount'] is Map
          ? Map<String, dynamic>.from(json['platformAccount'] as Map)
          : null,
    );
  }
}

class SubscriptionQuotaModel {
  final String? featureKey;
  final String? featureName;
  final int? limit;
  final bool isUnlimited;
  final String? period;
  final String? valueLabel;
  final int? chooseCount;
  final bool isChooseAll;

  const SubscriptionQuotaModel({
    this.featureKey,
    this.featureName,
    this.limit,
    this.isUnlimited = false,
    this.period,
    this.valueLabel,
    this.chooseCount,
    this.isChooseAll = false,
  });

  factory SubscriptionQuotaModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionQuotaModel(
      featureKey: json['featureKey']?.toString(),
      featureName: json['featureName']?.toString(),
      limit: _asInt(json['limit']),
      isUnlimited: json['isUnlimited'] == true,
      period: json['period']?.toString(),
      valueLabel: json['valueLabel']?.toString(),
      chooseCount: _asInt(json['chooseCount']),
      isChooseAll: json['isChooseAll'] == true,
    );
  }
}

class SubscriptionOptionModel {
  final int id;
  final String? featureKey;
  final int optionId;
  final String? optionText;
  final int? quantity;
  final int deliveredCount;
  final int? remainingCount;
  final bool isFullyDelivered;

  const SubscriptionOptionModel({
    required this.id,
    this.featureKey,
    required this.optionId,
    this.optionText,
    this.quantity,
    this.deliveredCount = 0,
    this.remainingCount,
    this.isFullyDelivered = false,
  });

  factory SubscriptionOptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionOptionModel(
      id: _asInt(json['id']) ?? 0,
      featureKey: json['featureKey']?.toString(),
      optionId: _asInt(json['optionId']) ?? 0,
      optionText: json['optionText']?.toString(),
      quantity: _asInt(json['quantity']),
      deliveredCount: _asInt(json['deliveredCount']) ?? 0,
      remainingCount: _asInt(json['remainingCount']),
      isFullyDelivered: json['isFullyDelivered'] == true,
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
