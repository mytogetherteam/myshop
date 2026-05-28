class Rider {
  final int id;
  final String name;
  final String? phone;
  final String? vehicleNo;
  final String? profileUrl;
  final int shopId;
  final bool isActive;
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
    this.createdAt,
    this.updatedAt,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      vehicleNo: json['vehicleNo']?.toString(),
      profileUrl: json['profileUrl']?.toString(),
      shopId: json['shopId'] as int,
      isActive: json['isActive'] as bool? ?? true,
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
