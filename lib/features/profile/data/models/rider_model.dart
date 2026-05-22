class Rider {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? licensePlate;
  final String? image;
  final int shopId;
  final int userId;

  Rider({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.licensePlate,
    this.image,
    required this.shopId,
    required this.userId,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      licensePlate: json['licensePlate'],
      image: json['image'],
      shopId: json['shopId'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'licensePlate': licensePlate,
      'image': image,
      'shopId': shopId,
      'userId': userId,
    };
  }
}
