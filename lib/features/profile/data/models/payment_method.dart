class PaymentMethod {
  final int id;
  final int? shopId;
  final int paymentMethodId;
  final String paymentMethodCode;
  final String paymentMethodName;
  final String qrImageUrl;
  final String accountNumber;
  final String accountName;
  final bool isActive;
  final int displayOrder;
  final String pendingStatus;
  final String? rejectReason;

  PaymentMethod({
    required this.id,
    this.shopId,
    required this.paymentMethodId,
    required this.paymentMethodCode,
    required this.paymentMethodName,
    required this.qrImageUrl,
    required this.accountNumber,
    required this.accountName,
    required this.isActive,
    required this.displayOrder,
    this.pendingStatus = 'APPROVED',
    this.rejectReason,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? 0,
      shopId: json['shopId'],
      paymentMethodId: json['paymentMethodId'] ?? 0,
      paymentMethodCode: json['paymentMethodCode'] ?? '',
      paymentMethodName: json['paymentMethodName'] ?? '',
      qrImageUrl: json['qrImageUrl'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      isActive: json['isActive'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
      pendingStatus: json['pendingStatus'] ?? json['status'] ?? 'APPROVED',
      rejectReason: json['rejectReason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shopId': shopId,
    'paymentMethodId': paymentMethodId,
    'paymentMethodCode': paymentMethodCode,
    'paymentMethodName': paymentMethodName,
    'qrImageUrl': qrImageUrl,
    'accountNumber': accountNumber,
    'accountName': accountName,
    'isActive': isActive,
    'displayOrder': displayOrder,
    'pendingStatus': pendingStatus,
    'rejectReason': rejectReason,
  };
}
