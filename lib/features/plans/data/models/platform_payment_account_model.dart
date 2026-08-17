class PlatformPaymentAccountModel {
  final int id;
  final String accountName;
  final String accountNumber;
  final String? qrUrl;
  final String? note;
  final int displayOrder;
  final PlatformPaymentMethodRef? paymentMethod;

  const PlatformPaymentAccountModel({
    required this.id,
    required this.accountName,
    required this.accountNumber,
    this.qrUrl,
    this.note,
    this.displayOrder = 0,
    this.paymentMethod,
  });

  String get methodName => paymentMethod?.name ?? '';

  factory PlatformPaymentAccountModel.fromJson(Map<String, dynamic> json) {
    return PlatformPaymentAccountModel(
      id: _asInt(json['id']) ?? 0,
      accountName: json['accountName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      qrUrl: json['qrUrl']?.toString(),
      note: json['note']?.toString(),
      displayOrder: _asInt(json['displayOrder']) ?? 0,
      paymentMethod: json['paymentMethod'] is Map
          ? PlatformPaymentMethodRef.fromJson(
              Map<String, dynamic>.from(json['paymentMethod'] as Map),
            )
          : null,
    );
  }
}

class PlatformPaymentMethodRef {
  final int id;
  final String name;
  final String? iconUrl;

  const PlatformPaymentMethodRef({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory PlatformPaymentMethodRef.fromJson(Map<String, dynamic> json) {
    return PlatformPaymentMethodRef(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
