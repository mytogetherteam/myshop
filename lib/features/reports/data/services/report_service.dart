import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/report_model.dart';
import 'package:intl/intl.dart';

class ReportService {
  static const String _summaryPath = '/api/reports/shop/summary';
  static const String _bestSellersPath = '/api/reports/shop/top-selling-items';
  static const String _ordersPath = '/api/reports/shop/orders';

  Future<SalesSummaryModel?> getSummary({required DateTime start, required DateTime end}) async {
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(start);
      final endDate = DateFormat('yyyy-MM-dd').format(end);
      
      final response = await ApiClient().dio.get(
        _summaryPath,
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );

      if (response.data['success'] == true) {
        return SalesSummaryModel.fromJson(response.data['data']);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReportService.getSummary');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReportService.getSummary');
    }
    return null;
  }

  Future<List<BestSellerModel>> getBestSellers({
    required DateTime start, 
    required DateTime end,
    int limit = 5,
  }) async {
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(start);
      final endDate = DateFormat('yyyy-MM-dd').format(end);

      final response = await ApiClient().dio.get(
        _bestSellersPath,
        queryParameters: {
          'startDate': startDate, 
          'endDate': endDate,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => BestSellerModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReportService.getBestSellers');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReportService.getBestSellers');
    }
    return [];
  }

  Future<List<OrderHistoryModel>> getOrders({
    required DateTime start, 
    required DateTime end,
    int limit = 10,
  }) async {
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(start);
      final endDate = DateFormat('yyyy-MM-dd').format(end);

      final response = await ApiClient().dio.get(
        _ordersPath,
        queryParameters: {
          'startDate': startDate, 
          'endDate': endDate,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => OrderHistoryModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReportService.getOrders');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReportService.getOrders');
    }
    return [];
  }
}
