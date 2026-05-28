import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';

List<OrderModel> _parseOrders(List<dynamic> jsonList) {
  return jsonList
      .map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json as Map)))
      .toList();
}

/// Maps UI tab keys to backend `tab` query values (lowercase).
String _tabQueryParam(String tab) {
  switch (tab.toUpperCase()) {
    case 'NEW':
      return 'new';
    case 'PAYMENT':
      return 'payment';
    case 'PREPARING':
      return 'preparing';
    case 'DELIVERING':
      return 'delivering';
    case 'DELIVERED':
      return 'delivered';
    case 'CANCELLED':
    case 'CANCELED':
      return 'canceled';
    default:
      return tab.toLowerCase();
  }
}

class OrderService {
  static const String _ordersPath = '/api/shop/orders';

  Future<OrderListResult?> getOrders({
    String? tab,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (tab != null) queryParams['tab'] = _tabQueryParam(tab);

      final response = await ApiClient().dio.get(
        _ordersPath,
        queryParameters: queryParams,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(
          response.data as Map,
        );
        if (body['success'] == true && body['data'] != null) {
          final List items = body['data'] is List ? body['data'] as List : [];
          final meta = body['meta'] is Map
              ? Map<String, dynamic>.from(body['meta'] as Map)
              : <String, dynamic>{};
          return OrderListResult(
            orders: _parseOrders(items),
            currentPage: meta['current_page'] as int? ?? page,
            lastPage: meta['last_page'] as int? ?? 1,
            total: meta['total'] as int? ?? items.length,
            perPage: meta['per_page'] as int? ?? size,
          );
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
      final response = await ApiClient().dio.post(
        '$_ordersPath/$orderId',
        data: {
          'withMenuItem': true,
          'withPayment': true,
          'withDelivery': true,
        },
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(
          response.data as Map,
        );
        if (body['success'] == true && body['data'] != null) {
          return OrderModel.fromJson(
            Map<String, dynamic>.from(body['data'] as Map),
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

  Future<Map<String, dynamic>> updateStatus(
    String orderId, {
    required String status,
    String? cancelReason,
    String? reviseReason,
    List<int>? unavailableItems,
    String? trackingUrl,
    String? orderDeliveryType,
    double? deliveryFee,
    int? waitingTimeMinutes,
    int? driverId,
    File? proofImage,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('status', status));

      if (cancelReason != null) {
        formData.fields.add(MapEntry('cancelReason', cancelReason));
      }
      if (reviseReason != null) {
        formData.fields.add(MapEntry('reviseReason', reviseReason));
      }
      if (unavailableItems != null && unavailableItems.isNotEmpty) {
        formData.fields.add(
          MapEntry('unavailableItems', unavailableItems.join(',')),
        );
      }
      if (trackingUrl != null) {
        formData.fields.add(MapEntry('trackingUrl', trackingUrl));
      }
      if (orderDeliveryType != null) {
        formData.fields.add(MapEntry('orderDeliveryType', orderDeliveryType));
      }
      if (deliveryFee != null) {
        formData.fields.add(MapEntry('deliveryFee', deliveryFee.toString()));
      }
      if (waitingTimeMinutes != null) {
        formData.fields.add(
          MapEntry('waitingTimeMinutes', waitingTimeMinutes.toString()),
        );
      }
      if (driverId != null) {
        formData.fields.add(MapEntry('driverId', driverId.toString()));
      }
      if (proofImage != null) {
        formData.files.add(MapEntry(
          'proofImage',
          await MultipartFile.fromFile(
            proofImage.path,
            filename: proofImage.path.split('/').last,
          ),
        ));
      }

      final response = await ApiClient().dio.patch(
        '$_ordersPath/$orderId/status',
        data: formData,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        return Map<String, dynamic>.from(e.response!.data as Map);
      }
      final error = ApiHelper.handleError(
        e,
        context: 'OrderService.updateStatus',
      );
      return {'success': false, 'details': error.message};
    } catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'OrderService.updateStatus',
      );
      return {'success': false, 'details': error.message};
    }
    return {'success': false, 'details': 'Failed to connect to server'};
  }

  Future<Map<String, dynamic>> confirmOrder(
    String orderId, {
    required String orderDeliveryType,
    required double deliveryFee,
    required int waitingTimeMinutes,
    int? driverId,
  }) {
    return updateStatus(
      orderId,
      status: 'PAYMENT_SLIP_REQUESTED',
      orderDeliveryType: orderDeliveryType,
      deliveryFee: deliveryFee,
      waitingTimeMinutes: waitingTimeMinutes,
      driverId: driverId,
    );
  }

  Future<Map<String, dynamic>> verifyPayment(String orderId) {
    return updateStatus(orderId, status: 'PAYMENT_VERIFIED');
  }

  Future<Map<String, dynamic>> prepareOrder(String orderId) {
    return updateStatus(orderId, status: 'COOKING');
  }

  Future<Map<String, dynamic>> requestSlip(String orderId, String reason) {
    return updateStatus(
      orderId,
      status: 'PAYMENT_SLIP_REQUESTED',
      reviseReason: reason,
    );
  }

  Future<Map<String, dynamic>> dispatchOrder(
    String orderId, {
    required int driverId,
    String? trackingUrl,
    File? proofImage,
  }) {
    return updateStatus(
      orderId,
      status: 'ON_THE_WAY',
      driverId: driverId,
      trackingUrl: trackingUrl,
      proofImage: proofImage,
    );
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, String? reason) {
    return updateStatus(
      orderId,
      status: 'CANCELED',
      cancelReason: reason,
    );
  }

  Future<Map<String, dynamic>> completeOrder(String orderId) {
    return updateStatus(orderId, status: 'DELIVERED');
  }

  Future<Map<String, dynamic>> reviseOrder(
    String orderId, {
    required String reviseReason,
    required List<int> unavailableItems,
  }) {
    return updateStatus(
      orderId,
      status: 'REVISED',
      reviseReason: reviseReason,
      unavailableItems: unavailableItems,
    );
  }

  /// @deprecated Use [updateStatus] with status CANCELED.
  Future<bool> updateOrderStatus(String orderId, String status) async {
    final result = await updateStatus(orderId, status: status);
    return result['success'] == true;
  }
}
