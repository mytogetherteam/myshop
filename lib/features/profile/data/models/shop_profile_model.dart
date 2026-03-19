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
  final double ratingAvg;
  final int ratingCount;
  
  // Amenities & Tags
  final bool hasParking;
  final bool hasWifi;
  final bool hasDelivery;
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

  // Operating Hours
  final List<OperatingHoursModel> operatingHours;

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
    required this.ratingAvg,
    required this.ratingCount,
    required this.hasParking,
    required this.hasWifi,
    required this.hasDelivery,
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
      ratingAvg: (json['ratingAvg'] ?? 0.0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      
      hasParking: json['hasParking'] ?? false,
      hasWifi: json['hasWifi'] ?? false,
      hasDelivery: json['hasDelivery'] ?? false,
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
    );
  }
}
