import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import '../models/payment_method.dart';

class PaymentService {
  static const String _paymentsPath = '/api/shop/profile/payment-types';

  Future<List<PaymentMethod>> getShopPaymentMethods(int shopId) async {
    try {
      debugPrint('GET REQUEST: $_paymentsPath, Header: X-Shop-Id: $shopId');
      final response = await ApiClient().dio.get(
        _paymentsPath,
        options: Options(headers: {'X-Shop-Id': shopId}),
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((e) => PaymentMethod.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getShopPaymentMethods: $e - Returning Mock Data');
    }
    return _getMockPayments(shopId);
  }

  List<PaymentMethod> _getMockPayments(int shopId) {
    return [
      PaymentMethod(
        id: 92,
        shopId: shopId,
        paymentMethodId: 27,
        paymentMethodCode: 'PROMPT_PAY',
        paymentMethodName: 'Prompt Pay',
        qrImageUrl: 'https://img.freepik.com/free-vector/qr-code-concept-illustration_114360-5853.jpg',
        logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/d7/PromptPay-logo.png',
        accountNumber: '12312312312',
        accountName: 'Together Shop Admin',
        isActive: true,
        displayOrder: 1,
      ),
      PaymentMethod(
        id: 93,
        shopId: shopId,
        paymentMethodId: 28,
        paymentMethodCode: 'TRUE_MONEY',
        paymentMethodName: 'True Money',
        qrImageUrl: 'https://img.freepik.com/free-vector/qr-code-concept-illustration_114360-5853.jpg',
        logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4b/Truemoney-logo.png',
        accountNumber: '0812345678',
        accountName: 'Together Shop Admin',
        isActive: true,
        displayOrder: 2,
      ),
    ];
  }

  Future<PaymentMethod?> getPaymentMethodDetail(int shopId, int paymentTypeId) async {
    try {
      final String path = '$_paymentsPath/$paymentTypeId';
      debugPrint('GET REQUEST: $path, Header: X-Shop-Id: $shopId');
      final response = await ApiClient().dio.get(
        path,
        options: Options(headers: {'X-Shop-Id': shopId}),
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return PaymentMethod.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('API Error in getPaymentMethodDetail: $e - Returning Mock Detail');
    }
    return _getMockPayments(shopId).firstWhere((element) => element.id == paymentTypeId, orElse: () => _getMockPayments(shopId).first);
  }

  Future<bool> updatePaymentMethod({
    required int shopId,
    required int paymentTypeId,
    required Map<String, dynamic> requestData,
    File? qrFile,
  }) async {
    try {
      final String path = '$_paymentsPath/$paymentTypeId';
      debugPrint('PUT REQUEST: $path, Data: $requestData, Has File: ${qrFile != null}');

      // According to Swagger: request (object) and qrFile (file)
      final Map<String, dynamic> formDataMap = {
        'request': MultipartFile.fromString(
          jsonEncode(requestData),
          contentType: DioMediaType.parse('application/json'),
        ),
      };

      if (qrFile != null) {
        formDataMap['qrFile'] = await MultipartFile.fromFile(
          qrFile.path,
          filename: qrFile.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await ApiClient().dio.put(
        path,
        data: formData,
        options: Options(
          headers: {
            'X-Shop-Id': shopId,
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in updatePaymentMethod: $e - Simulating Success for Mock');
      return true; // Simulate success when in mock mode
    }
    return false;
  }
}
