import 'package:my_shop/core/utils/localized_display_name.dart';

class PlanListResult {
  final List<PlanModel> items;
  final int total;
  final int page;
  final bool hasMore;

  const PlanListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class PlanModel {
  final int id;
  final String code;
  final String nameEn;
  final String? nameMm;
  final String? nameTh;
  final String? descriptionEn;
  final String? descriptionMm;
  final String? descriptionTh;
  final double? price;
  final double? annualPrice;
  final double? annualMonthlyPrice;
  final int? annualDiscountPercent;
  final bool hasAnnualPricing;
  final String billingPeriod;
  final bool isCustomPricing;
  final bool isPopular;
  final String? ctaLabel;
  final int displayOrder;
  final List<PlanFeatureValueModel> featureValues;
  final List<PlanHighlightModel> highlights;

  const PlanModel({
    required this.id,
    required this.code,
    required this.nameEn,
    this.nameMm,
    this.nameTh,
    this.descriptionEn,
    this.descriptionMm,
    this.descriptionTh,
    this.price,
    this.annualPrice,
    this.annualMonthlyPrice,
    this.annualDiscountPercent,
    this.hasAnnualPricing = false,
    this.billingPeriod = 'MONTHLY',
    this.isCustomPricing = false,
    this.isPopular = false,
    this.ctaLabel,
    this.displayOrder = 0,
    this.featureValues = const [],
    this.highlights = const [],
  });

  String get displayName => localizedDisplayName(
        nameEn: nameEn,
        nameMm: nameMm,
        nameTh: nameTh,
      );

  String get displayDescription => localizedDisplayName(
        nameEn: descriptionEn,
        nameMm: descriptionMm,
        nameTh: descriptionTh,
      );

  /// Amount shown next to "/ mo" for the selected billing toggle.
  double? displayMonthlyAmount({required bool annual}) {
    if (isCustomPricing) return null;
    if (annual && hasAnnualPricing && annualMonthlyPrice != null) {
      return annualMonthlyPrice;
    }
    return price;
  }

  /// Total amount the shop should transfer for this billing choice.
  double? chargeAmount({required bool annual}) {
    if (isCustomPricing) return null;
    if (annual && hasAnnualPricing && annualPrice != null) {
      return annualPrice;
    }
    return price;
  }

  /// Features that require the shop to pick exactly [chooseCount] options.
  List<PlanFeatureValueModel> get selectableFeatures => featureValues
      .where(
        (f) =>
            !f.isChooseAll &&
            f.chooseCount != null &&
            f.chooseCount! > 0 &&
            f.offeredOptions.isNotEmpty,
      )
      .toList();

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: _asInt(json['id']) ?? 0,
      code: json['code']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      nameMm: json['nameMm']?.toString(),
      nameTh: json['nameTh']?.toString(),
      descriptionEn: json['descriptionEn']?.toString(),
      descriptionMm: json['descriptionMm']?.toString(),
      descriptionTh: json['descriptionTh']?.toString(),
      price: _asDouble(json['price']),
      annualPrice: _asDouble(json['annualPrice']),
      annualMonthlyPrice: _asDouble(json['annualMonthlyPrice']),
      annualDiscountPercent: _asInt(json['annualDiscountPercent']),
      hasAnnualPricing: json['hasAnnualPricing'] == true,
      billingPeriod: json['billingPeriod']?.toString() ?? 'MONTHLY',
      isCustomPricing: json['isCustomPricing'] == true,
      isPopular: json['isPopular'] == true,
      ctaLabel: json['ctaLabel']?.toString(),
      displayOrder: _asInt(json['displayOrder']) ?? 0,
      featureValues: (json['featureValues'] is List)
          ? (json['featureValues'] as List)
              .whereType<Map>()
              .map(
                (e) => PlanFeatureValueModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      highlights: (json['highlights'] is List)
          ? (json['highlights'] as List)
              .whereType<Map>()
              .map(
                (e) =>
                    PlanHighlightModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
    );
  }
}

class PlanFeatureRef {
  final int id;
  final String code;
  final String? featureKey;
  final String nameEn;
  final String? nameMm;
  final String? nameTh;
  final String? descriptionEn;
  final String? descriptionMm;
  final String? descriptionTh;
  final int displayOrder;

  const PlanFeatureRef({
    required this.id,
    required this.code,
    this.featureKey,
    required this.nameEn,
    this.nameMm,
    this.nameTh,
    this.descriptionEn,
    this.descriptionMm,
    this.descriptionTh,
    this.displayOrder = 0,
  });

  String get displayName => localizedDisplayName(
        nameEn: nameEn,
        nameMm: nameMm,
        nameTh: nameTh,
      );

  String get displayDescription => localizedDisplayName(
        nameEn: descriptionEn,
        nameMm: descriptionMm,
        nameTh: descriptionTh,
      );

  factory PlanFeatureRef.fromJson(Map<String, dynamic> json) {
    return PlanFeatureRef(
      id: _asInt(json['id']) ?? 0,
      code: json['code']?.toString() ?? '',
      featureKey: json['featureKey']?.toString(),
      nameEn: json['nameEn']?.toString() ?? '',
      nameMm: json['nameMm']?.toString(),
      nameTh: json['nameTh']?.toString(),
      descriptionEn: json['descriptionEn']?.toString(),
      descriptionMm: json['descriptionMm']?.toString(),
      descriptionTh: json['descriptionTh']?.toString(),
      displayOrder: _asInt(json['displayOrder']) ?? 0,
    );
  }
}

class PlanFeatureOptionModel {
  final int id;
  final String code;
  final String textEn;
  final String? textMm;
  final String? textTh;
  final int? quantity;
  final int displayOrder;

  const PlanFeatureOptionModel({
    required this.id,
    required this.code,
    required this.textEn,
    this.textMm,
    this.textTh,
    this.quantity,
    this.displayOrder = 0,
  });

  String get displayText {
    final label = localizedDisplayName(
      nameEn: textEn,
      nameMm: textMm,
      nameTh: textTh,
    );
    if (quantity == null) return label;
    return '$label x $quantity';
  }

  factory PlanFeatureOptionModel.fromJson(Map<String, dynamic> json) {
    return PlanFeatureOptionModel(
      id: _asInt(json['id']) ?? 0,
      code: json['code']?.toString() ?? '',
      textEn: json['textEn']?.toString() ?? '',
      textMm: json['textMm']?.toString(),
      textTh: json['textTh']?.toString(),
      quantity: _asInt(json['quantity']),
      displayOrder: _asInt(json['displayOrder']) ?? 0,
    );
  }
}

class PlanFeatureValueModel {
  final int id;
  final int featureId;
  final int? quantity;
  final bool isUnlimited;
  final String? period;
  final String? valueLabel;
  final String? note;
  final int? chooseCount;
  final bool isChooseAll;
  final int displayOrder;
  final PlanFeatureRef? feature;
  final List<PlanFeatureOptionModel> offeredOptions;
  final String? chooseLabel;

  const PlanFeatureValueModel({
    required this.id,
    required this.featureId,
    this.quantity,
    this.isUnlimited = false,
    this.period,
    this.valueLabel,
    this.note,
    this.chooseCount,
    this.isChooseAll = false,
    this.displayOrder = 0,
    this.feature,
    this.offeredOptions = const [],
    this.chooseLabel,
  });

  /// Pricing-card line, e.g. "Flash Drop x3" or "Analytic Report - Mid".
  String get displayLine {
    final name = feature?.displayName ?? '';
    final buffer = StringBuffer(name);

    if (isUnlimited) {
      buffer.write(' Unlimited');
    } else if (quantity != null) {
      buffer.write(' x$quantity');
      if (period != null && period!.trim().isNotEmpty) {
        buffer.write('/${period!.trim()}');
      }
    }

    if (valueLabel != null && valueLabel!.trim().isNotEmpty) {
      buffer.write(' - ${valueLabel!.trim()}');
    }

    if (note != null && note!.trim().isNotEmpty) {
      buffer.write(' ${note!.trim()}');
    }

    if (chooseLabel != null && chooseLabel!.trim().isNotEmpty) {
      buffer.write(' ${chooseLabel!.trim()}');
    }

    return buffer.toString().trim();
  }

  factory PlanFeatureValueModel.fromJson(Map<String, dynamic> json) {
    return PlanFeatureValueModel(
      id: _asInt(json['id']) ?? 0,
      featureId: _asInt(json['featureId']) ?? 0,
      quantity: _asInt(json['quantity']),
      isUnlimited: json['isUnlimited'] == true,
      period: json['period']?.toString(),
      valueLabel: json['valueLabel']?.toString(),
      note: json['note']?.toString(),
      chooseCount: _asInt(json['chooseCount']),
      isChooseAll: json['isChooseAll'] == true,
      displayOrder: _asInt(json['displayOrder']) ?? 0,
      feature: json['feature'] is Map
          ? PlanFeatureRef.fromJson(
              Map<String, dynamic>.from(json['feature'] as Map),
            )
          : null,
      offeredOptions: (json['offeredOptions'] is List)
          ? (json['offeredOptions'] as List)
              .whereType<Map>()
              .map(
                (e) => PlanFeatureOptionModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      chooseLabel: json['chooseLabel']?.toString(),
    );
  }
}

class PlanHighlightModel {
  final int id;
  final String textEn;
  final String? textMm;
  final String? textTh;
  final int displayOrder;

  const PlanHighlightModel({
    required this.id,
    required this.textEn,
    this.textMm,
    this.textTh,
    this.displayOrder = 0,
  });

  String get displayText => localizedDisplayName(
        nameEn: textEn,
        nameMm: textMm,
        nameTh: textTh,
      );

  factory PlanHighlightModel.fromJson(Map<String, dynamic> json) {
    return PlanHighlightModel(
      id: _asInt(json['id']) ?? 0,
      textEn: json['textEn']?.toString() ?? '',
      textMm: json['textMm']?.toString(),
      textTh: json['textTh']?.toString(),
      displayOrder: _asInt(json['displayOrder']) ?? 0,
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
