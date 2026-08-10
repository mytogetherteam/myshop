import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';

import '../models/plan_model.dart';

class PlanService {
  static const String _basePath = '/api/shop/plans';

  final Dio _dio = ApiClient().dio;

  List<PlanModel> _parseList(dynamic rawData) {
    if (rawData is List) {
      return rawData
          .whereType<Map>()
          .map((e) => PlanModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// Returns null when the request fails so the UI can show an error state.
  Future<PlanListResult?> getPlans({int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get(
        _basePath,
        queryParameters: {'page': page, 'size': size},
      );

      final body = response.data;
      if (body is Map && body['success'] == true) {
        final items = _parseList(body['data']);
        final meta = body['meta'];
        final total = meta is Map
            ? int.tryParse(meta['total']?.toString() ?? '') ?? items.length
            : items.length;
        final lastPage = meta is Map
            ? int.tryParse(meta['last_page']?.toString() ?? '') ?? page
            : page;
        return PlanListResult(
          items: items,
          total: total,
          page: page,
          hasMore: page < lastPage,
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'PlanService.getPlans');
    } catch (e) {
      ApiHelper.handleError(e, context: 'PlanService.getPlans');
    }
    return null;
  }

  Future<PlanModel?> getPlan(int id) async {
    try {
      final response = await _dio.get('$_basePath/$id');
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return PlanModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'PlanService.getPlan');
    } catch (e) {
      ApiHelper.handleError(e, context: 'PlanService.getPlan');
    }
    return null;
  }
}
