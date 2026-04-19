class Shop {
  final int id;
  final String name;
  final String? logoUrl;
  final String? address;

  Shop({
    required this.id,
    required this.name,
    this.logoUrl,
    this.address,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['nameEn'] ?? 'Unknown Shop',
      logoUrl: json['logoUrl'] ?? json['logo_url'],
      address: json['address'] ?? json['addressEn'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'address': address,
  };
}
