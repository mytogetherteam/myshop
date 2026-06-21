import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/core/utils/app_logger.dart';
import '../models/support_info_model.dart';

class SupportService {
  static const String _path = '/api/shop/settings/support';

  Future<SupportInfoModel?> getSupportInfo() async {
    try {
      AppLogger.network('GET $_path');
      final response = await ApiClient().dio.get(_path);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return SupportInfoModel.fromJson(
            Map<String, dynamic>.from(data['data']),
          );
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'SupportService.getSupportInfo');
    } catch (e) {
      ApiHelper.handleError(e, context: 'SupportService.getSupportInfo');
    }
    return const SupportInfoModel(email: 'support@mytogether.org');
  }
}
