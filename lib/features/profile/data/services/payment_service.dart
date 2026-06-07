import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/payment_method.dart';

class PaymentService {
  static const String _paymentsPath = '/api/shop/shop-payment-methods';

  /// GET /api/shop/profile/payment-types
  /// Get Shop Payment Types
  Future<List<PaymentMethod>> getShopPaymentMethods({bool forceRefresh = false}) async {
    try {
      debugPrint('GET REQUEST: $_paymentsPath, forceRefresh: $forceRefresh');
      final response = await ApiClient().dio.get(
        _paymentsPath,
        options: forceRefresh
            ? CacheOptions(store: MemCacheStore(), policy: CachePolicy.refresh).toOptions()
            : null,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((e) => PaymentMethod.fromJson(e)).toList();
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'PaymentService.getShopPaymentMethods');
    } catch (e) {
      ApiHelper.handleError(e, context: 'PaymentService.getShopPaymentMethods');
    }
    return [];
  }

  /// GET /api/shop/profile/payment-types/{id}
  /// Get Payment Type Detail
  Future<PaymentMethod?> getPaymentMethodDetail(int paymentTypeId) async {
    try {
      final String path = '$_paymentsPath/$paymentTypeId';
      debugPrint('GET REQUEST: $path');
      final response = await ApiClient().dio.get(path);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return PaymentMethod.fromJson(data['data']);
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(
        e,
        context: 'PaymentService.getPaymentMethodDetail',
      );
    } catch (e) {
      ApiHelper.handleError(
        e,
        context: 'PaymentService.getPaymentMethodDetail',
      );
    }
    return null;
  }

  /// PUT /api/shop/profile/payment-types/{id}
  /// Update Payment Type
  /// Body: multipart/form-data with `request` (JSON object) and `qrPhoto` (file)
  Future<Map<String, dynamic>> updatePaymentMethod({
    required int paymentTypeId,
    required Map<String, dynamic> requestData,
    XFile? qrPhoto,
  }) async {
    try {
      final String path = '$_paymentsPath/$paymentTypeId';
      debugPrint(
        'PUT REQUEST: $path, Data: $requestData, Has File: ${qrPhoto != null}',
      );

      final Map<String, dynamic> formDataMap = Map<String, dynamic>.from(
        requestData,
      );

      if (qrPhoto != null) {
        formDataMap['paymentQrImage'] = MultipartFile.fromBytes(
          await qrPhoto.readAsBytes(),
          filename: qrPhoto.name,
        );
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await ApiClient().dio.put(
        path,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(response.data);
      }
      return {
        'success': false,
        'message': 'Failed to update payment method: ${response.statusCode}',
      };
    } on DioException catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'PaymentService.updatePaymentMethod',
      );
      if (e.response?.data is Map) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'success': false, 'message': error.message};
    } catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'PaymentService.updatePaymentMethod',
      );
      return {'success': false, 'message': error.message};
    }
  }

  /// DELETE /api/shop/profile/payment-types/{id}
  /// Delete Payment Type
  Future<Map<String, dynamic>> deletePaymentMethod(int paymentTypeId) async {
    try {
      final String path = '$_paymentsPath/$paymentTypeId';
      debugPrint('DELETE REQUEST: $path');
      final response = await ApiClient().dio.delete(path);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(response.data);
      }
      return {
        'success': false,
        'message': 'Failed to delete payment method: ${response.statusCode}',
      };
    } on DioException catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'PaymentService.deletePaymentMethod',
      );
      if (e.response?.data is Map) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'success': false, 'message': error.message};
    } catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'PaymentService.deletePaymentMethod',
      );
      return {'success': false, 'message': error.message};
    }
  }
}
