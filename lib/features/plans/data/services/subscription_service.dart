import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:path/path.dart' as p;

import '../models/subscription_model.dart';

class SubscriptionService {
  static const String _basePath = '/api/shop/subscriptions';

  final Dio _dio = ApiClient().dio;

  List<SubscriptionModel> _parseList(dynamic rawData) {
    if (rawData is List) {
      return rawData
          .whereType<Map>()
          .map(
            (e) => SubscriptionModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return [];
  }

  Future<SubscriptionListResult?> getSubscriptions({
    int page = 1,
    int size = 20,
  }) async {
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
        return SubscriptionListResult(
          items: items,
          total: total,
          page: page,
          hasMore: page < lastPage,
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'SubscriptionService.getSubscriptions');
    } catch (e) {
      ApiHelper.handleError(e, context: 'SubscriptionService.getSubscriptions');
    }
    return null;
  }

  /// Returns the live ACTIVE subscription, or null when none / request failed.
  /// Distinguishes "no plan" (success with null data) from failure via [failed].
  Future<({SubscriptionModel? subscription, bool failed})> getCurrent() async {
    try {
      final response = await _dio.get('$_basePath/current');
      final body = response.data;
      if (body is Map && body['success'] == true) {
        if (body['data'] == null) {
          return (subscription: null, failed: false);
        }
        if (body['data'] is Map) {
          return (
            subscription: SubscriptionModel.fromJson(
              Map<String, dynamic>.from(body['data'] as Map),
            ),
            failed: false,
          );
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'SubscriptionService.getCurrent');
    } catch (e) {
      ApiHelper.handleError(e, context: 'SubscriptionService.getCurrent');
    }
    return (subscription: null, failed: true);
  }

  Future<SubscriptionModel?> getSubscription(int id) async {
    try {
      final response = await _dio.get('$_basePath/$id');
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return SubscriptionModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'SubscriptionService.getSubscription');
    } catch (e) {
      ApiHelper.handleError(e, context: 'SubscriptionService.getSubscription');
    }
    return null;
  }

  Future<SubscriptionModel> purchase({
    required int planId,
    required XFile screenshot,
    required String billingPeriod,
    int? platformAccountId,
    double? paidAmount,
    String? transferRef,
    List<int>? selectedOptionIds,
  }) async {
    final formData = await _buildSlipForm(
      screenshot: screenshot,
      fields: {
        'planId': planId,
        'billingPeriod': billingPeriod,
        'platformAccountId': ?platformAccountId,
        'paidAmount': ?paidAmount,
        if (transferRef != null && transferRef.trim().isNotEmpty)
          'transferRef': transferRef.trim(),
        if (selectedOptionIds != null && selectedOptionIds.isNotEmpty)
          'selectedOptionIds': selectedOptionIds.join(','),
      },
    );

    try {
      final response = await _dio.post(_basePath, data: formData);
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return SubscriptionModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw StateError('Invalid purchase response.');
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'SubscriptionService.purchase');
      rethrow;
    }
  }

  Future<SubscriptionModel> resubmitPayment({
    required int subscriptionId,
    required XFile screenshot,
    int? platformAccountId,
    double? paidAmount,
    String? transferRef,
  }) async {
    final formData = await _buildSlipForm(
      screenshot: screenshot,
      fields: {
        'platformAccountId': ?platformAccountId,
        'paidAmount': ?paidAmount,
        if (transferRef != null && transferRef.trim().isNotEmpty)
          'transferRef': transferRef.trim(),
      },
    );

    try {
      final response = await _dio.post(
        '$_basePath/$subscriptionId/payments',
        data: formData,
      );
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return SubscriptionModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw StateError('Invalid payment response.');
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'SubscriptionService.resubmitPayment');
      rethrow;
    }
  }

  Future<FormData> _buildSlipForm({
    required XFile screenshot,
    required Map<String, dynamic> fields,
  }) async {
    // Always read bytes — more reliable than fromFile across iOS temp paths
    // and Android picker/cropper copies.
    final bytes = await screenshot.readAsBytes();
    var filename = p.basename(screenshot.name);
    if (filename.trim().isEmpty || !filename.contains('.')) {
      filename = 'payment-slip.jpg';
    }

    final extension = p.extension(filename).toLowerCase();
    final subtype = switch (extension) {
      '.png' => 'png',
      '.webp' => 'webp',
      '.gif' => 'gif',
      // Crop/output is usually JPEG; HEIC/HEIF from iOS still needs a type.
      '.heic' => 'heic',
      '.heif' => 'heif',
      '.jpg' || '.jpeg' => 'jpeg',
      _ => 'jpeg',
    };

    // Prefer a JPEG filename when the cropper produced a .jpg path but the
    // original XFile name was extension-less.
    if (subtype == 'jpeg' &&
        !filename.toLowerCase().endsWith('.jpg') &&
        !filename.toLowerCase().endsWith('.jpeg')) {
      filename = '${p.basenameWithoutExtension(filename)}.jpg';
    }

    final file = MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: MediaType('image', subtype),
    );

    return FormData.fromMap({
      ...fields,
      'screenshot': file,
    });
  }
}

String subscriptionApiErrorMessage(Object error) {
  if (error is DioException) {
    final exception = ApiException.fromDioException(error);
    final details = exception.details?.toString().trim();
    if (details != null && details.isNotEmpty) return details;
    return exception.message;
  }
  return error.toString();
}
