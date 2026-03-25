class PaymentMethod {
  final String id;
  final String name;
  final String logoUrl;
  final String qrUrl;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.qrUrl,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String,
      qrUrl: json['qr_url'] as String,
    );
  }
}
