import 'operating_hours_model.dart';

class ShopProfileModel {
  final int id;
  final String? coverUrl;
  final String? logoUrl;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final String? descriptionEn;
  final String? descriptionMm;
  final String? descriptionTh;
  final String? categoryEn;
  final String? categoryMm;
  final String? categoryTh;
  final int? categoryId;
  final String? subCategoryEn;
  final String? subCategoryMm;
  final String? subCategoryTh;
  final int? subCategoryId;
  final double ratingAvg;
  final int ratingCount;
  
  // Amenities & Tags
  final bool hasParking;
  final bool hasWifi;
  final bool isHalal;
  final bool isVegetarian;
  
  // Logistics
  final String? displayBaseDeliveryFee;
  final String? estimatedTime;
  final String? displayMinOrderAmount;
  final String? phone;
  final String? email;
  final bool isOpen;

  // Address
  final String? addressEn;
  final String? addressMm;
  final String? addressTh;
  final String? districtEn;
  final String? districtMm;
  final String? districtTh;
  final String? cityEn;
  final String? cityMm;
  final String? cityTh;
  final double? latitude;
  final double? longitude;

  // Price Preference
  final String? pricePreference;
  final String currency;

  // Operating Hours
  final List<OperatingHoursModel> operatingHours;

  // ----------------------------------------------------
  // New Fields from API
  // ----------------------------------------------------
  final int maxItemQuantityPerOrder;
  final double minOrderAmount;
  final double baseDeliveryFee;
  final String? googleMapsLink;
  final bool isActive;
  final bool isVerified;
  final bool adminDisabled;
  final String? paymentQrUrl;
  final int viewCount;
  final bool deliveryEnabled;
  final String? slug;
  final List<int> cuisineTypeIds;

  ShopProfileModel({
    required this.id,
    this.coverUrl,
    this.logoUrl,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.descriptionEn,
    this.descriptionMm,
    this.descriptionTh,
    this.categoryEn,
    this.categoryMm,
    this.categoryTh,
    this.categoryId,
    this.subCategoryEn,
    this.subCategoryMm,
    this.subCategoryTh,
    this.subCategoryId,
    required this.ratingAvg,
    required this.ratingCount,
    required this.hasParking,
    required this.hasWifi,
    required this.isHalal,
    required this.isVegetarian,
    this.displayBaseDeliveryFee,
    this.estimatedTime,
    this.displayMinOrderAmount,
    this.phone,
    this.email,
    required this.isOpen,
    this.addressEn,
    this.addressMm,
    this.addressTh,
    this.districtEn,
    this.districtMm,
    this.districtTh,
    this.cityEn,
    this.cityMm,
    this.cityTh,
    this.latitude,
    this.longitude,
    this.pricePreference,
    this.maxItemQuantityPerOrder = 10,
    this.minOrderAmount = 0.0,
    this.baseDeliveryFee = 0.0,
    this.googleMapsLink,
    this.isActive = false,
    this.isVerified = false,
    this.adminDisabled = false,
    this.paymentQrUrl,
    this.viewCount = 0,
    this.deliveryEnabled = false,
    this.slug,
    this.currency = '฿',
    this.cuisineTypeIds = const [],
    required this.operatingHours,
  });

  factory ShopProfileModel.fromJson(Map<String, dynamic> json) {
    return ShopProfileModel(
      id: json['id'] ?? 0,
      coverUrl: json['coverUrl'],
      logoUrl: json['logoUrl'],
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      descriptionEn: json['descriptionEn'],
      descriptionMm: json['descriptionMm'],
      descriptionTh: json['descriptionTh'],
      categoryEn: json['categoryEn'],
      categoryMm: json['categoryMm'],
      categoryTh: json['categoryTh'],
      categoryId: json['categoryId'],
      subCategoryEn: json['subCategoryEn'],
      subCategoryMm: json['subCategoryMm'],
      subCategoryTh: json['subCategoryTh'],
      subCategoryId: json['subCategoryId'],
      ratingAvg: (json['rating'] ?? json['ratingAvg'] ?? 0.0).toDouble(),
      ratingCount: json['reviewCount'] ?? json['ratingCount'] ?? 0,
      
      hasParking: json['hasParking'] ?? false,
      hasWifi: json['hasWifi'] ?? false,
      isHalal: json['isHalal'] ?? false,
      isVegetarian: json['isVegetarian'] ?? false,
      
      displayBaseDeliveryFee: json['displayBaseDeliveryFee'],
      estimatedTime: json['estimatedTime'],
      displayMinOrderAmount: json['displayMinOrderAmount'],
      phone: json['phone'],
      email: json['email'],
      isOpen: json['isOpen'] ?? false,

      addressEn: json['addressEn'],
      addressMm: json['addressMm'],
      addressTh: json['addressTh'],
      districtEn: json['districtEn'],
      districtMm: json['districtMm'],
      districtTh: json['districtTh'],
      cityEn: json['cityEn'],
      cityMm: json['cityMm'],
      cityTh: json['cityTh'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,

      pricePreference: json['pricePreference'],

      operatingHours: (json['operatingHours'] as List<dynamic>?)
          ?.map((e) => OperatingHoursModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      maxItemQuantityPerOrder: json['maxItemQuantityPerOrder'] ?? 10,
      minOrderAmount: (json['minOrderAmount'] ?? 0.0).toDouble(),
      baseDeliveryFee: (json['baseDeliveryFee'] ?? 0.0).toDouble(),
      googleMapsLink: json['googleMapsLink'],
      isActive: json['isActive'] ?? false,
      isVerified: json['isVerified'] ?? false,
      adminDisabled: json['adminDisabled'] ?? false,
      paymentQrUrl: json['paymentQrUrl'],
      viewCount: json['viewCount'] ?? 0,
      deliveryEnabled: json['deliveryEnabled'] ?? false,
      slug: json['slug'],
      currency: json['currency'] ?? '฿',
      cuisineTypeIds: json['cuisineTypeIds'] != null
          ? List<int>.from(json['cuisineTypeIds'])
          : json['shopCuisines'] != null
              ? (json['shopCuisines'] as List)
                  .map((e) => e['cuisineTypeId'] as int)
                  .toList()
              : [],
    );
  }
}
