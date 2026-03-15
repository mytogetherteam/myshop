import 'package:flutter/foundation.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/core/network/api_client.dart';

class OrderService {
  static const String _ordersPath = '/api/shop/orders';

  Future<List<OrderModel>?> getOrders({String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : null;
      debugPrint('GET REQUEST: $_ordersPath, Params: $queryParams');
      final response = await ApiClient().dio.get(
        _ordersPath,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        debugPrint('FULL API RESPONSE (getOrders): $data');
        if (data['success'] == true && data['data'] != null) {
          final List content = data['data']['content'] ?? [];
          return content.map((json) => OrderModel.fromJson(json)).toList();
        } else {
          debugPrint('API Error: success is false OR data is null. Message: ${data['message']}, Details: ${data['details']}');
        }
      } else {
        debugPrint('API Error: Status Code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error in getOrders: $e');
    }

    return null; // Return null on error
  }

  Future<OrderModel?> getOrderDetail(String orderId) async {
    try {
      final url = '$_ordersPath/$orderId';
      debugPrint('GET REQUEST: $url');
      final response = await ApiClient().dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        debugPrint('FULL API RESPONSE (getOrderDetail): $data');
        if (data['success'] == true && data['data'] != null) {
          return OrderModel.fromJson(data['data']);
        } else {
          debugPrint('API Error in getOrderDetail: success is false OR data is null');
        }
      }
    } catch (e) {
      debugPrint('API Error in getOrderDetail: $e');
    }
    return null;
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final url = '$_ordersPath/$orderId/status';
      debugPrint('POST REQUEST (updateOrderStatus): $url, Data: {status: $status}');
      final response = await ApiClient().dio.post(
            url,
            data: {'status': status},
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        debugPrint('UPDATE STATUS RESPONSE: $data');
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in updateOrderStatus: $e');
    }
    return false;
  }

  Future<bool> confirmOrder(String orderId, Map<String, dynamic> payload) async {
    try {
      final url = '$_ordersPath/$orderId/confirm';
      debugPrint('PUT REQUEST (confirmOrder): $url, Data: $payload');
      final response = await ApiClient().dio.put(
            url,
            data: payload,
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        debugPrint('CONFIRM ORDER RESPONSE: $data');
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in confirmOrder: $e');
    }
    return false;
  }

  Future<bool> verifyPayment(String orderId) async {
    try {
      final url = '$_ordersPath/$orderId/verify-payment';
      debugPrint('PUT REQUEST (verifyPayment): $url');
      final response = await ApiClient().dio.put(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        debugPrint('VERIFY PAYMENT RESPONSE: $data');
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in verifyPayment: $e');
    }
    return false;
  }
}

