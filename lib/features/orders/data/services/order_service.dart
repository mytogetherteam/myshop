import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';

List<OrderModel> _parseOrders(List<dynamic> jsonList) {
  return jsonList.map((json) => OrderModel.fromJson(json)).toList();
}

class OrderService {
  static const String _ordersPath = '/api/shop/orders';

  Future<List<OrderModel>?> getOrders({
    String? status,
    String? tab,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (status != null) queryParams['status'] = status;
      if (tab != null) queryParams['tab'] = tab;
      
      debugPrint('GET REQUEST: $_ordersPath, Params: $queryParams');
      final response = await ApiClient().dio.get(
        _ordersPath,
        queryParameters: queryParams,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('FULL API RESPONSE (getOrders): $data');
        if (data['success'] == true && data['data'] != null) {
          final List content = data['data']['content'] ?? [];
          return await compute(_parseOrders, content);
        } else {
          debugPrint(
            'API Error: success is false OR data is null. Message: ${data['message']}, Details: ${data['details']}',
          );
        }
      } else {
        debugPrint('API Error: Status Code ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.getOrders');
    } catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.getOrders');
    }

    return null;
  }

  Future<OrderModel?> getOrderDetail(String orderId) async {
    try {
      final url = '$_ordersPath/$orderId';
      debugPrint('GET REQUEST: $url');
      final response = await ApiClient().dio.get(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('FULL API RESPONSE (getOrderDetail): $data');
        if (data['success'] == true && data['data'] != null) {
          return OrderModel.fromJson(data['data']);
        } else {
          debugPrint(
            'API Error in getOrderDetail: success is false OR data is null',
          );
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.getOrderDetail');
    } catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.getOrderDetail');
    }
    return null;
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final url = '$_ordersPath/$orderId/status';
      debugPrint(
        'POST REQUEST (updateOrderStatus): $url, Data: {status: $status}',
      );
      final response = await ApiClient().dio.post(
        url,
        data: {'status': status},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('UPDATE STATUS RESPONSE: $data');
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.updateOrderStatus');
    } catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.updateOrderStatus');
    }
    return false;
  }

  Future<Map<String, dynamic>> confirmOrder(
    String orderId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = '$_ordersPath/$orderId/confirm';
      debugPrint('PUT REQUEST (confirmOrder): $url, Data: $payload');
      final response = await ApiClient().dio.put(url, data: payload);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('CONFIRM ORDER RESPONSE: $data');
        return data;
      }
    } on DioException catch (e) {
      debugPrint('API Error in confirmOrder: ${e.response?.data}');
      if (e.response?.data != null && e.response?.data is Map) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      final error = ApiHelper.handleError(
        e,
        context: 'OrderService.confirmOrder',
      );
      return {'success': false, 'details': error.message};
    } catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'OrderService.confirmOrder',
      );
      return {'success': false, 'details': error.message};
    }
    return {'success': false, 'details': 'Failed to connect to server'};
  }

  Future<Map<String, dynamic>> verifyPayment(String orderId) async {
    try {
      final url = '$_ordersPath/$orderId/verify-payment';
      debugPrint('PUT REQUEST (verifyPayment): $url');
      final response = await ApiClient().dio.put(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('VERIFY PAYMENT RESPONSE: $data');
        return data;
      }
    } on DioException catch (e) {
      debugPrint('API Error in verifyPayment: ${e.response?.data}');
      if (e.response?.data != null && e.response?.data is Map) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      final error = ApiHelper.handleError(
        e,
        context: 'OrderService.verifyPayment',
      );
      return {'success': false, 'details': error.message};
    } catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'OrderService.verifyPayment',
      );
      return {'success': false, 'details': error.message};
    }
    return {'success': false, 'details': 'Failed to connect to server'};
  }

  Future<bool> prepareOrder(String orderId) async {
    try {
      final url = '$_ordersPath/$orderId/prepare';
      debugPrint('PUT REQUEST (prepareOrder): $url');
      final response = await ApiClient().dio.put(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('PREPARE ORDER RESPONSE: $data');
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.prepareOrder');
    } catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.prepareOrder');
    }
    return false;
  }

  Future<bool> requestSlip(String orderId, String reason) async {
    try {
      final url = '$_ordersPath/$orderId/request-slip';
      debugPrint('PUT REQUEST (requestSlip): $url, Reason: $reason');
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'reason': reason},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('REQUEST SLIP RESPONSE: $data');
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.requestSlip');
    } catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.requestSlip');
    }
    return false;
  }

  Future<bool> dispatchOrder(String orderId, [Map<String, dynamic>? payload]) async {
    try {
      final url = '$_ordersPath/$orderId/dispatch';
      debugPrint('PUT REQUEST (dispatchOrder): $url, Data: $payload');
      final response = await ApiClient().dio.put(url, data: payload);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('DISPATCH ORDER RESPONSE: $data');
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.dispatchOrder');
    } catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.dispatchOrder');
    }
    return false;
  }

  Future<bool> cancelOrder(String orderId, String? reason) async {
    try {
      final url = '$_ordersPath/$orderId/cancel';
      debugPrint('PUT REQUEST (cancelOrder): $url, Reason: $reason');
      final response = await ApiClient().dio.put(
        url,
        queryParameters: reason != null ? {'reason': reason} : null,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('CANCEL ORDER RESPONSE: $data');
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.cancelOrder');
    } catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.cancelOrder');
    }
    return false;
  }

  Future<bool> completeOrder(String orderId, String proofPhotoUrl) async {
    try {
      final url = '$_ordersPath/$orderId/complete';
      debugPrint(
        'PUT REQUEST (completeOrder): $url, proofPhotoUrl: $proofPhotoUrl',
      );
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'proofPhotoUrl': proofPhotoUrl},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('COMPLETE ORDER RESPONSE: $data');
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.completeOrder');
    } catch (e) {
      ApiHelper.handleError(e, context: 'OrderService.completeOrder');
    }
    return false;
  }
}
