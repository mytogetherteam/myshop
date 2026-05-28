import 'package:my_shop/core/config/env_config.dart';

String? _resolveUrl(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  if (str.isEmpty) return null;
  if (str.startsWith('http://') || str.startsWith('https://')) return str;
  if (str.startsWith('data:')) return str;
  final path = str.startsWith('/') ? str : '/$str';
  return '${EnvConfig.apiBaseUrl}$path';
}

String _normalizeStatus(String? raw) {
  final s = (raw ?? '').toUpperCase();
  switch (s) {
    case 'PREPARING':
      return 'COOKING';
    case 'CANCELLED':
      return 'CANCELED';
    case 'CONFIRMED':
      return 'PENDING';
    case 'PAYMENT_UPLOADED':
      return 'AWAITING_APPROVAL';
    case 'READY_FOR_PICKUP':
      return 'COOKING';
    case 'REJECTED':
      return 'CANCELED';
    default:
      return s;
  }
}

class OrderModel {
  final String id;
  final String lastOrderNo;
  final String status;
  final bool ongoing;
  final String? statusLabel;
  final String orderType;
  final String? orderDeliveryType;
  final bool isScheduled;
  final DateTime? scheduledDeliveryTime;
  final double deliveryFee;
  final String displayDeliveryFee;
  final double itemPrice;
  final double totalAmount;
  final String displayTotalAmount;
  final double previousTotalAmount;
  final String displayPreviousTotalAmount;
  final List<OrderItemModel> items;
  final DeliveryAddressModel? deliveryAddress;
  final String? paymentSlipUrl;
  final String? riderName;
  final String? riderPhone;
  final String? vehicleNo;
  final int? driverId;
  final String? trackingUrl;
  final String? proofPhotoUrl;
  final List<OrderReviseItemModel> reviseItems;
  final List<OrderDriverModel> shopDeliveryDrivers;
  final int queueNo;
  final DateTime createdAt;
  final DateTime updatedAt;

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
  final String? cancelReason;
  final String? reviseReason;
  final String? shopPaymentQrUrl;
  final int waitingTimeMinutes;

  OrderModel({
    required this.id,
    required this.lastOrderNo,
    required this.status,
    this.ongoing = false,
    this.statusLabel,
    this.orderType = 'DELIVERY',
    this.orderDeliveryType,
    this.isScheduled = false,
    this.scheduledDeliveryTime,
    this.deliveryFee = 0.0,
    this.displayDeliveryFee = '',
    this.itemPrice = 0.0,
    this.totalAmount = 0.0,
    this.displayTotalAmount = '',
    this.previousTotalAmount = 0.0,
    this.displayPreviousTotalAmount = '',
    required this.items,
    this.deliveryAddress,
    this.paymentSlipUrl,
    this.riderName,
    this.riderPhone,
    this.vehicleNo,
    this.driverId,
    this.trackingUrl,
    this.proofPhotoUrl,
    this.reviseItems = const [],
    this.shopDeliveryDrivers = const [],
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
    this.cancelReason,
    this.reviseReason,
    this.shopPaymentQrUrl,
    this.waitingTimeMinutes = 0,
  });

  /// Legacy alias for delivery tier UI (FAST = prepaid, FLEXIBLE = flexible).
  String get deliveryType {
    if (orderDeliveryType == 'FLEXIBLE') return 'NORMAL';
    if (orderDeliveryType == 'FAST') return 'PREPAID';
    return orderDeliveryType ?? 'PREPAID';
  }

  String? get deliveryCycleNo => vehicleNo;
  String? get deliveryTrackingUrl => trackingUrl;

  List<OrderModificationModel> get modifications {
    return reviseItems
        .map(
          (r) => OrderModificationModel(
            id: r.id,
            modificationType: 'REVISED',
            modifiedBy: r.revisedByName ?? 'Shop',
            itemName: r.itemName ?? 'Item #${r.orderItemId}',
            reason: r.reason,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final status = _normalizeStatus(json['status']?.toString());
    final driver = json['driver'] is Map
        ? Map<String, dynamic>.from(json['driver'] as Map)
        : null;

    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;

    final deliveryFee = (json['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final itemPrice = (json['itemPrice'] as num?)?.toDouble() ??
        (json['items'] is List
            ? (json['items'] as List).fold<double>(
                0,
                (sum, item) =>
                    sum +
                    ((item['price'] as num?)?.toDouble() ?? 0) *
                        ((item['quantity'] as num?)?.toInt() ?? 0),
              )
            : 0.0);
    final totalAmount = (json['totalAmount'] as num?)?.toDouble() ?? 0.0;

    List<OrderReviseItemModel> reviseItemsList = [];
    if (json['reviseItems'] is List) {
      reviseItemsList = (json['reviseItems'] as List)
          .map((e) => OrderReviseItemModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }

    List<OrderDriverModel> driversList = [];
    if (json['shopDeliveryDrivers'] is List) {
      driversList = (json['shopDeliveryDrivers'] as List)
          .map((e) => OrderDriverModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }

    DeliveryAddressModel? address;
    if (json['deliveryAddress'] is Map) {
      address = DeliveryAddressModel.fromJson(
        Map<String, dynamic>.from(json['deliveryAddress'] as Map),
      );
    } else if (json['address'] != null) {
      address = DeliveryAddressModel(
        latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['lon'] as num?)?.toDouble() ?? 0.0,
        address: json['address']?.toString() ?? '',
        addressMm: json['addressMm']?.toString(),
        buildingName: json['buildingName']?.toString(),
        floor: json['floor']?.toString(),
        note: json['note']?.toString(),
      );
    }

    final waitingMins = json['waitingTimeMinutes'] as int? ?? 0;

    return OrderModel(
      id: (json['id'] ?? '').toString(),
      lastOrderNo: json['lastOrderNo']?.toString() ?? json['id']?.toString() ?? '',
      status: status,
      ongoing: json['ongoing'] == true,
      statusLabel: json['statusLabel']?.toString() ?? _statusLabelFor(status),
      orderType: json['orderType']?.toString() ?? 'DELIVERY',
      orderDeliveryType: json['orderDeliveryType']?.toString(),
      isScheduled: json['isScheduled'] == true,
      scheduledDeliveryTime: json['scheduledDeliveryTime'] != null
          ? DateTime.tryParse(json['scheduledDeliveryTime'].toString())
          : null,
      deliveryFee: deliveryFee,
      displayDeliveryFee: json['displayDeliveryFee']?.toString() ??
          (deliveryFee > 0 ? '฿${deliveryFee.toInt()}' : '฿ 0'),
      itemPrice: itemPrice,
      totalAmount: totalAmount,
      displayTotalAmount: json['displayTotalAmount']?.toString() ??
          '฿${totalAmount.toInt()}',
      previousTotalAmount: (json['previousTotalAmount'] as num?)?.toDouble() ?? 0.0,
      displayPreviousTotalAmount:
          json['displayPreviousTotalAmount']?.toString() ?? '',
      items: (json['items'] as List?)
              ?.map((item) => OrderItemModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList() ??
          [],
      deliveryAddress: address,
      paymentSlipUrl: _resolveUrl(json['paymentSlipUrl']),
      riderName: driver?['name']?.toString() ?? json['deliveryRiderName']?.toString(),
      riderPhone: driver?['phone']?.toString() ?? json['deliveryPhoneNo']?.toString(),
      vehicleNo: driver?['vehicleNo']?.toString() ?? json['deliveryCycleNo']?.toString(),
      driverId: json['driverId'] as int? ?? driver?['id'] as int?,
      trackingUrl: json['trackingUrl']?.toString() ?? json['deliveryTrackingUrl']?.toString(),
      proofPhotoUrl: _resolveUrl(json['proofPhotoUrl']),
      reviseItems: reviseItemsList,
      shopDeliveryDrivers: driversList,
      queueNo: json['queueNo'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      shopOwnerId: json['shopOwnerId'] as int? ?? 0,
      shopName: json['shopName']?.toString() ?? json['shop']?['nameEn']?.toString() ?? '',
      shopLogo: _resolveUrl(json['shopLogo'] ?? json['shop']?['logoUrl']),
      shopAddress: json['shopAddress']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      shopPhone: json['shopPhone']?.toString(),
      customerName: json['customerName']?.toString() ?? user?['name']?.toString() ?? 'Customer',
      customerPhone: json['customerPhone']?.toString() ?? user?['phone']?.toString() ?? '-',
      customerEmail: json['customerEmail']?.toString() ?? user?['email']?.toString(),
      customerAvatar: _resolveUrl(json['customerAvatar'] ?? user?['profileUrl']),
      customerUsername: json['customerUsername']?.toString(),
      shopOwnerEmail: json['shopOwnerEmail']?.toString(),
      shopOwnerUsername: json['shopOwnerUsername']?.toString(),
      estimatedDeliveryTime: json['estimatedDeliveryTime']?.toString() ??
          (waitingMins > 0 ? '$waitingMins mins' : null),
      cancelReason: json['cancelReason']?.toString(),
      reviseReason: json['reviseReason']?.toString(),
      shopPaymentQrUrl: json['shopPaymentQrUrl']?.toString(),
      waitingTimeMinutes: waitingMins,
    );
  }

  static String _statusLabelFor(String status) {
    const labels = {
      'PENDING': 'Pending',
      'CANCELED': 'Canceled',
      'PAYMENT_SLIP_REQUESTED': 'Waiting for Payment',
      'AWAITING_APPROVAL': 'Awaiting Approval',
      'PAYMENT_VERIFIED': 'Payment Verified',
      'COOKING': 'Cooking',
      'ON_THE_WAY': 'On the Way',
      'DELIVERED': 'Delivered',
      'REVISED': 'Revised',
    };
    return labels[status] ?? status;
  }

  double get foodPrice =>
      itemPrice > 0
          ? itemPrice
          : items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  String get deliveryAddressDetail => deliveryAddress?.address ?? '-';
  String get deliveryAddressTitle => 'Delivery Address';
  String get statusName => statusLabel ?? status;
}

class OrderDriverModel {
  final int id;
  final String name;
  final String? phone;
  final String? vehicleNo;
  final String? profileUrl;
  final bool isActive;

  OrderDriverModel({
    required this.id,
    required this.name,
    this.phone,
    this.vehicleNo,
    this.profileUrl,
    this.isActive = true,
  });

  factory OrderDriverModel.fromJson(Map<String, dynamic> json) {
    return OrderDriverModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      vehicleNo: json['vehicleNo']?.toString(),
      profileUrl: _resolveUrl(json['profileUrl']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
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
    final menuItem = json['menuItem'] is Map
        ? Map<String, dynamic>.from(json['menuItem'] as Map)
        : null;

    List<OrderItemOptionModel> optionsList = [];
    if (json['selectedOptions'] is List) {
      optionsList = (json['selectedOptions'] as List).map((opt) {
        final o = Map<String, dynamic>.from(opt as Map);
        final menuOpt = o['menuItemOption'] is Map
            ? Map<String, dynamic>.from(o['menuItemOption'] as Map)
            : null;
        return OrderItemOptionModel(
          name: menuOpt?['nameEn']?.toString() ?? '',
          displayPrice: '฿${(o['price'] as num?)?.toString() ?? '0'}',
        );
      }).toList();
    }

    final price = (json['price'] as num?)?.toDouble() ?? 0.0;

    return OrderItemModel(
      id: json['id'] as int? ?? 0,
      menuItemId: json['menuItemId'] as int? ?? menuItem?['id'] as int? ?? 0,
      menuItemName: json['menuItemName']?.toString() ?? menuItem?['nameEn']?.toString() ?? '',
      menuItemNameMm: json['menuItemNameMm']?.toString() ?? menuItem?['nameMm']?.toString(),
      menuItemImageUrl: _resolveUrl(json['imageUrl'] ?? json['menuItemImageUrl'] ?? menuItem?['imageUrl']),
      quantity: json['quantity'] as int? ?? 0,
      price: price,
      displayPrice: json['displayPrice']?.toString() ?? '฿${price.toInt()}',
      specialInstructions: json['specialInstructions']?.toString(),
      optionsString: json['options']?.toString(),
      options: optionsList,
    );
  }

  String get displayName =>
      menuItemName.isNotEmpty ? menuItemName : (menuItemNameMm ?? '-');

  String? get secondaryName =>
      (menuItemName.isNotEmpty && menuItemNameMm != null && menuItemNameMm != menuItemName)
          ? menuItemNameMm
          : null;
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
      address: json['address']?.toString() ?? '',
      addressMm: json['addressMm']?.toString(),
      buildingName: json['buildingName']?.toString(),
      floor: json['floor']?.toString(),
      note: json['note']?.toString(),
    );
  }
}

class OrderReviseItemModel {
  final int id;
  final int orderItemId;
  final int revisedById;
  final String? reason;
  final String? itemName;
  final String? revisedByName;
  final DateTime createdAt;

  OrderReviseItemModel({
    required this.id,
    required this.orderItemId,
    required this.revisedById,
    this.reason,
    this.itemName,
    this.revisedByName,
    required this.createdAt,
  });

  factory OrderReviseItemModel.fromJson(Map<String, dynamic> json) {
    final orderItem = json['orderItem'] is Map
        ? Map<String, dynamic>.from(json['orderItem'] as Map)
        : null;
    final menuItem = orderItem?['menuItem'] is Map
        ? Map<String, dynamic>.from(orderItem!['menuItem'] as Map)
        : null;
    final revisedBy = json['revisedBy'] is Map
        ? Map<String, dynamic>.from(json['revisedBy'] as Map)
        : null;

    return OrderReviseItemModel(
      id: json['id'] as int? ?? 0,
      orderItemId: json['orderItemId'] as int? ?? 0,
      revisedById: json['revisedById'] as int? ?? 0,
      reason: json['reason']?.toString(),
      itemName: menuItem?['nameEn']?.toString(),
      revisedByName: revisedBy?['name']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
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

class OrderListResult {
  final List<OrderModel> orders;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  OrderListResult({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasMore => currentPage < lastPage;
}
