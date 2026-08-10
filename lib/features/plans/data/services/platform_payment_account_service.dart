import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';

import '../models/platform_payment_account_model.dart';

class PlatformPaymentAccountService {
  static const String _basePath = '/api/shop/platform-payment-accounts';

  final Dio _dio = ApiClient().dio;

  /// Returns accounts on success. Returns `null` when the request failed.
  Future<List<PlatformPaymentAccountModel>?> getAccounts() async {
    try {
      final response = await _dio.get(_basePath);
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .whereType<Map>()
            .map(
              (e) => PlatformPaymentAccountModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
      return null;
    } on DioException catch (e) {
      ApiHelper.handleError(
        e,
        context: 'PlatformPaymentAccountService.getAccounts',
      );
    } catch (e) {
      ApiHelper.handleError(
        e,
        context: 'PlatformPaymentAccountService.getAccounts',
      );
    }
    return null;
  }
}
