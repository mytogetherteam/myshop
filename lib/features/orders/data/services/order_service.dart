import 'package:dio/dio.dart';
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
    int? shopId,
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
      if (shopId != null) queryParams['shopId'] = shopId;
      
      final response = await ApiClient().dio.get(
        _ordersPath,
        queryParameters: queryParams,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List content = data['data']['content'] ?? [];
          return _parseOrders(content);
        }
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
      final response = await ApiClient().dio.get(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return OrderModel.fromJson(data['data']);
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
      final response = await ApiClient().dio.post(
        url,
        data: {'status': status},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
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
      final response = await ApiClient().dio.put(url, data: payload);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data;
      }
    } on DioException catch (e) {
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
      final response = await ApiClient().dio.put(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data;
      }
    } on DioException catch (e) {
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
      final response = await ApiClient().dio.put(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
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
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'reason': reason},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
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
      final response = await ApiClient().dio.put(url, data: payload);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
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
      final response = await ApiClient().dio.put(
        url,
        queryParameters: reason != null ? {'reason': reason} : null,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
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
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'proofPhotoUrl': proofPhotoUrl},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
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
