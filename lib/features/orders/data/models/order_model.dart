import 'package:my_shop/core/config/env_config.dart';

String? _resolveUrl(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  if (str.isEmpty) return null;
  // Already an absolute URL — return as-is
  if (str.startsWith('http://') || str.startsWith('https://')) return str;
  // Base64 data URI (e.g. customer-uploaded receipt) — return as-is
  if (str.startsWith('data:')) return str;
  // Relative path — prepend the API base URL
  final path = str.startsWith('/') ? str : '/$str';
  return '${EnvConfig.apiBaseUrl}$path';
}

class OrderModel {
  final String id;
  final String lastOrderNo;
  final String status;
  final bool ongoing;
  final String? statusLabel;
  final String? statusLabelMm;
  final String? statusLabelTh;
  final String deliveryType;
  final String deliveryTier;
  final String? deliveryTierLabel;
  final String? deliveryTierLabelMm;
  final String? deliveryTierLabelTh;
  final bool isScheduled;
  final DateTime? scheduledDeliveryTime;
  final double deliveryFee;
  final String displayDeliveryFee;
  final double totalAmount;
  final String displayTotalAmount;
  final double previousTotalAmount;
  final String displayPreviousTotalAmount;
  final List<OrderItemModel> items;
  final DeliveryAddressModel? deliveryAddress;
  final String? paymentSlipUrl;
  final String? riderName;
  final String? riderPhone;
  final List<OrderModificationModel> modifications;
  final int queueNo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New fields from latest API
  final int shopOwnerId;
  final String shopName;
  final String? shopLogo;
  final String? shopAddress;
  final double? lat;
  final double? lon;
  final String? shopPhone;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? customerAvatar;
  final String? customerUsername;
  final String? shopOwnerEmail;
  final String? shopOwnerUsername;
  final String? estimatedDeliveryTime;
  final String? deliveryCycleNo;
  final String? deliveryTrackingUrl;
  final String? proofPhotoUrl;
  final String? cancelReason;
  final String? shopPaymentQrUrl;
  final int waitingTimeMinutes;

  OrderModel({
    required this.id,
    required this.lastOrderNo,
    required this.status,
    this.ongoing = false,
    this.statusLabel,
    this.statusLabelMm,
    this.statusLabelTh,
    required this.deliveryType,
    this.deliveryTier = 'NORMAL',
    this.deliveryTierLabel,
    this.deliveryTierLabelMm,
    this.deliveryTierLabelTh,
    this.isScheduled = false,
    this.scheduledDeliveryTime,
    this.deliveryFee = 0.0,
    this.displayDeliveryFee = '',
    this.totalAmount = 0.0,
    this.displayTotalAmount = '',
    this.previousTotalAmount = 0.0,
    this.displayPreviousTotalAmount = '',
    required this.items,
    this.deliveryAddress,
    this.paymentSlipUrl,
    this.riderName,
    this.riderPhone,
    this.modifications = const [],
    this.queueNo = 0,
    required this.createdAt,
    required this.updatedAt,
    this.shopOwnerId = 0,
    this.shopName = '',
    this.shopLogo,
    this.shopAddress,
    this.lat,
    this.lon,
    this.shopPhone,
    this.customerName = 'Customer',
    this.customerPhone = '-',
    this.customerEmail,
    this.customerAvatar,
    this.customerUsername,
    this.shopOwnerEmail,
    this.shopOwnerUsername,
    this.estimatedDeliveryTime,
    this.deliveryCycleNo,
    this.deliveryTrackingUrl,
    this.proofPhotoUrl,
    this.cancelReason,
    this.shopPaymentQrUrl,
    this.waitingTimeMinutes = 0,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['id'] ?? '').toString(),
      lastOrderNo: json['lastOrderNo']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      ongoing: json['ongoing'] ?? false,
      statusLabel: json['statusLabel']?.toString(),
      statusLabelMm: json['statusLabelMm']?.toString(),
      statusLabelTh: json['statusLabelTh']?.toString(),
      deliveryType: json['deliveryType']?.toString() ?? 'DELIVERY',
      deliveryTier: json['deliveryTier']?.toString() ?? 'NORMAL',
      deliveryTierLabel: json['deliveryTierLabel']?.toString(),
      deliveryTierLabelMm: json['deliveryTierLabelMm']?.toString(),
      deliveryTierLabelTh: json['deliveryTierLabelTh']?.toString(),
      isScheduled: json['isScheduled'] ?? false,
      scheduledDeliveryTime: json['scheduledDeliveryTime'] != null
          ? DateTime.parse(json['scheduledDeliveryTime'])
          : null,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      displayDeliveryFee: json['displayDeliveryFee']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      displayTotalAmount: json['displayTotalAmount']?.toString() ?? '',
      previousTotalAmount: (json['previousTotalAmount'] as num?)?.toDouble() ?? 0.0,
      displayPreviousTotalAmount: json['displayPreviousTotalAmount']?.toString() ?? '',
      items: (json['items'] as List?)
              ?.map((item) => OrderItemModel.fromJson(item))
              .toList() ??
          [],
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddressModel.fromJson(json['deliveryAddress'])
          : null,
      paymentSlipUrl: _resolveUrl(json['paymentSlipUrl']),
      riderName: json['deliveryRiderName']?.toString(),
      riderPhone: json['deliveryPhoneNo']?.toString(),
      modifications: (json['modifications'] as List?)
              ?.map((m) => OrderModificationModel.fromJson(m))
              .toList() ??
          [],
      queueNo: json['queueNo'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      shopOwnerId: json['shopOwnerId'] ?? 0,
      shopName: json['shopName'] ?? '',
      shopLogo: _resolveUrl(json['shopLogo']),
      shopAddress: json['shopAddress'],
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      shopPhone: json['shopPhone'],
      customerName: json['customerName'] ?? 'Customer',
      customerPhone: json['customerPhone'] ?? '-',
      customerEmail: json['customerEmail'],
      customerAvatar: _resolveUrl(json['customerAvatar']),
      customerUsername: json['customerUsername'],
      shopOwnerEmail: json['shopOwnerEmail'],
      shopOwnerUsername: json['shopOwnerUsername'],
      estimatedDeliveryTime: json['estimatedDeliveryTime']?.toString() ?? json['estimatedTime']?.toString() ?? ((json['waitingTimeMinutes'] != null && json['waitingTimeMinutes'] > 0) ? '${json['waitingTimeMinutes']} mins' : null),
      deliveryCycleNo: json['deliveryCycleNo'],
      deliveryTrackingUrl: json['deliveryTrackingUrl'],
      proofPhotoUrl: _resolveUrl(json['proofPhotoUrl']),
      cancelReason: json['cancelReason'],
      shopPaymentQrUrl: json['shopPaymentQrUrl'],
      waitingTimeMinutes: json['waitingTimeMinutes'] ?? 0,
    );
  }

  // Helper for UI
  double get foodPrice => items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  String get deliveryAddressDetail => deliveryAddress?.address ?? '-';
  String get deliveryAddressTitle => 'Delivery Address';
  String get statusName => statusLabel ?? statusLabelMm ?? status;
}

class OrderItemModel {
  final int id;
  final int menuItemId;
  final String menuItemName;
  final String? menuItemNameMm;
  final String? menuItemImageUrl;
  final int quantity;
  final double price;
  final String displayPrice;
  final String? specialInstructions;
  final String? optionsString;
  final List<OrderItemOptionModel> options;

  OrderItemModel({
    required this.id,
    this.menuItemId = 0,
    required this.menuItemName,
    this.menuItemNameMm,
    this.menuItemImageUrl,
    required this.quantity,
    required this.price,
    required this.displayPrice,
    this.specialInstructions,
    this.optionsString,
    this.options = const [],
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      menuItemId: json['menuItemId'] ?? 0,
      menuItemName: json['menuItemName'] ?? '',
      menuItemNameMm: json['menuItemNameMm'],
      menuItemImageUrl: _resolveUrl(json['imageUrl'] ?? json['menuItemImageUrl']),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      displayPrice: json['displayPrice'] ?? '',
      specialInstructions: json['specialInstructions'],
      optionsString: json['options']?.toString(),
      options: [], // Legacy or structured options
    );
  }

  String get displayName => menuItemName.isNotEmpty ? menuItemName : (menuItemNameMm ?? '-');
  String? get secondaryName => (menuItemName.isNotEmpty && menuItemNameMm != null && menuItemNameMm != menuItemName) ? menuItemNameMm : null;
}

class OrderItemOptionModel {
  final String name;
  final String displayPrice;

  OrderItemOptionModel({required this.name, required this.displayPrice});

  factory OrderItemOptionModel.fromJson(Map<String, dynamic> json) {
    return OrderItemOptionModel(
      name: json['name'] ?? json['optionName'] ?? '',
      displayPrice: json['displayPrice'] ?? '',
    );
  }
}

class DeliveryAddressModel {
  final double latitude;
  final double longitude;
  final String address;
  final String? addressMm;
  final String? buildingName;
  final String? floor;
  final String? note;

  DeliveryAddressModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.addressMm,
    this.buildingName,
    this.floor,
    this.note,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      addressMm: json['addressMm'],
      buildingName: json['buildingName'],
      floor: json['floor'],
      note: json['note'],
    );
  }
}

class OrderModificationModel {
  final int id;
  final String modificationType;
  final String modifiedBy;
  final String itemName;
  final String? previousValue;
  final String? newValue;
  final String? reason;
  final DateTime createdAt;

  OrderModificationModel({
    required this.id,
    required this.modificationType,
    required this.modifiedBy,
    required this.itemName,
    this.previousValue,
    this.newValue,
    this.reason,
    required this.createdAt,
  });

  factory OrderModificationModel.fromJson(Map<String, dynamic> json) {
    return OrderModificationModel(
      id: json['id'] ?? 0,
      modificationType: json['modificationType'] ?? '',
      modifiedBy: json['modifiedBy'] ?? '',
      itemName: json['itemName'] ?? '',
      previousValue: json['previousValue']?.toString(),
      newValue: json['newValue']?.toString(),
      reason: json['reason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
