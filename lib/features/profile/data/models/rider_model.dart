class Rider {
  final int id;
  final String name;
  final String? phone;
  final String? vehicleNo;
  final String? profileUrl;
  final int shopId;
  final bool isActive;

  Rider({
    required this.id,
    required this.name,
    this.phone,
    this.vehicleNo,
    this.profileUrl,
    required this.shopId,
    this.isActive = true,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      vehicleNo: json['vehicleNo'],
      profileUrl: json['profileUrl'],
      shopId: json['shopId'],
      isActive: json['isActive'] ?? true,
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
