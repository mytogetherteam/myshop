import '../../../../core/config/env_config.dart';

class PaymentMethod {
  final int id;
  final int? shopId;
  final int paymentMethodId;
  final String paymentMethodCode;
  final String paymentMethodName;
  final String paymentMethodIconUrl;
  final String qrImageUrl;
  final String accountNumber;
  final String accountName;
  final bool isActive;
  final int displayOrder;
  final String pendingStatus;
  final String? rejectReason;

  String get fullQrImageUrl {
    if (qrImageUrl.isEmpty) return '';
    if (qrImageUrl.startsWith('http')) return qrImageUrl;
    return '${EnvConfig.apiBaseUrl}/$qrImageUrl';
  }

  String get fullPaymentMethodIconUrl {
    if (paymentMethodIconUrl.isEmpty) return '';
    if (paymentMethodIconUrl.startsWith('http')) return paymentMethodIconUrl;
    return '${EnvConfig.apiBaseUrl}/$paymentMethodIconUrl';
  }

  PaymentMethod({
    required this.id,
    this.shopId,
    required this.paymentMethodId,
    required this.paymentMethodCode,
    required this.paymentMethodName,
    this.paymentMethodIconUrl = '',
    required this.qrImageUrl,
    required this.accountNumber,
    required this.accountName,
    required this.isActive,
    required this.displayOrder,
    this.pendingStatus = 'APPROVED',
    this.rejectReason,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final paymentMethod = json['paymentMethod'] as Map<String, dynamic>?;
    return PaymentMethod(
      id: json['id'] ?? 0,
      shopId: json['shopId'],
      paymentMethodId: json['paymentMethodId'] ?? 0,
      paymentMethodCode: paymentMethod?['code'] ?? '',
      paymentMethodName: paymentMethod?['name'] ?? '',
      paymentMethodIconUrl: paymentMethod?['iconUrl'] ?? '',
      qrImageUrl: json['qr'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      isActive: json['isActive'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
      pendingStatus: json['status'] ?? 'APPROVED',
      rejectReason: json['rejectReason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shopId': shopId,
    'paymentMethodId': paymentMethodId,
    'paymentMethodCode': paymentMethodCode,
    'paymentMethodName': paymentMethodName,
    'paymentMethodIconUrl': paymentMethodIconUrl,
    'qrImageUrl': qrImageUrl,
    'accountNumber': accountNumber,
    'accountName': accountName,
    'isActive': isActive,
    'displayOrder': displayOrder,
    'pendingStatus': pendingStatus,
    'rejectReason': rejectReason,
  };
}
