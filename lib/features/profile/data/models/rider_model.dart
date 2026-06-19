class Rider {
  final int id;
  final String name;
  final String? phone;
  final String? vehicleNo;
  final String? profileUrl;
  final int shopId;
  final bool isActive;
  final bool isBusy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rider({
    required this.id,
    required this.name,
    this.phone,
    this.vehicleNo,
    this.profileUrl,
    required this.shopId,
    this.isActive = true,
    this.isBusy = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Active drivers who are not on another delivery can be assigned to an order.
  bool get isSelectableForOrder => isActive && !isBusy;

  static bool isEligibleForAssignment({
    required bool isActive,
    required bool isBusy,
  }) =>
      isActive && !isBusy;

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      vehicleNo: json['vehicleNo']?.toString(),
      profileUrl: json['profileUrl']?.toString(),
      shopId: json['shopId'] as int,
      isActive: json['isActive'] as bool? ?? true,
      isBusy: json['isBusy'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'vehicleNo': vehicleNo,
      'profileUrl': profileUrl,
      'shopId': shopId,
      'isActive': isActive,
      'isBusy': isBusy,
    };
  }
}

class RiderListResult {
  final List<Rider> riders;
  final int totalElements;
  final int totalPages;
  final int page;
  final int size;

  RiderListResult({
    required this.riders,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
  });
}
