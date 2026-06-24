import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/rider_model.dart';

class RiderService {
  static const String _basePath = '/api/shop/delivery-drivers';

  List<Rider> _parseRiderList(dynamic rawData) {
    if (rawData is List) {
      return rawData
          .map((e) => Rider.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (rawData is Map && rawData['content'] is List) {
      return (rawData['content'] as List)
          .map((e) => Rider.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Map<String, dynamic>? _unwrapListPayload(Map<String, dynamic> body) {
    if (body['success'] == true && body['data'] != null) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (body['content'] is List) return body;
    return null;
  }

  /// Keeps only drivers that are active and not currently on another delivery.
  List<Rider> _eligibleForOrderAssignment(Iterable<Rider> riders) {
    return riders.where((r) => r.isSelectableForOrder).toList();
  }

  Future<RiderListResult> getRiders({
    int page = 1,
    int size = 100,
    String? search,
    bool? isActive,
  }) async {
    try {
      final response = await ApiClient().dio.get(
        _basePath,
        queryParameters: {
          'page': page,
          'size': size,
          if (search != null && search.isNotEmpty) 'search': search,
          if (isActive != null) 'isActive': isActive,
        },
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(
          response.data as Map,
        );
        final rawData = _unwrapListPayload(body);
        if (rawData != null) {
          final riders = _parseRiderList(rawData);
          return RiderListResult(
            riders: riders,
            totalElements: rawData['totalElements'] as int? ?? riders.length,
            totalPages: rawData['totalPages'] as int? ?? 1,
            page: rawData['page'] as int? ?? page,
            size: rawData['size'] as int? ?? size,
          );
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.getRiders');
    } catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.getRiders');
    }
    return RiderListResult(
      riders: [],
      totalElements: 0,
      totalPages: 0,
      page: page,
      size: size,
    );
  }

  /// Riders eligible for assignment in the order driver picker.
  ///
  /// Requests active drivers from the API, then keeps only those who are also
  /// not busy on another delivery (`isActive && !isBusy`).
  Future<List<Rider>> getSelectableRiders() async {
    final result = await getRiders(page: 1, size: 100, isActive: true);
    return _eligibleForOrderAssignment(result.riders);
  }

  Future<Rider?> createRider(Map<String, dynamic> riderData, {XFile? image}) async {
    try {
      final formData = FormData();

      for (final entry in riderData.entries) {
        final value = entry.value;
        if (value is List || value is Map) {
          formData.fields.add(MapEntry(entry.key, jsonEncode(value)));
        } else {
          formData.fields.add(MapEntry(entry.key, value.toString()));
        }
      }

      if (image != null) {
        formData.files.add(MapEntry(
          'profilePhoto',
          MultipartFile.fromBytes(
            await image.readAsBytes(),
            filename: image.name,
          ),
        ));
      }

      final response = await ApiClient().dio.post(
        _basePath,
        data: formData,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          response.data as Map,
        );
        if (data['success'] == true && data['data'] != null) {
          return Rider.fromJson(Map<String, dynamic>.from(data['data'] as Map));
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.createRider');
    } catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.createRider');
    }
    return null;
  }

  Future<Rider?> updateRider(int id, Map<String, dynamic> riderData, {XFile? image}) async {
    try {
      final formData = FormData();

      for (final entry in riderData.entries) {
        final value = entry.value;
        if (value is List || value is Map) {
          formData.fields.add(MapEntry(entry.key, jsonEncode(value)));
        } else {
          formData.fields.add(MapEntry(entry.key, value.toString()));
        }
      }

      if (image != null) {
        formData.files.add(MapEntry(
          'profilePhoto',
          MultipartFile.fromBytes(
            await image.readAsBytes(),
            filename: image.name,
          ),
        ));
      }

      final response = await ApiClient().dio.put(
        '$_basePath/$id',
        data: formData,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          response.data as Map,
        );
        if (data['success'] == true && data['data'] != null) {
          return Rider.fromJson(Map<String, dynamic>.from(data['data'] as Map));
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.updateRider');
    } catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.updateRider');
    }
    return null;
  }

  Future<bool> deleteRider(int id) async {
    try {
      final response = await ApiClient().dio.delete('$_basePath/$id');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.deleteRider');
    } catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.deleteRider');
    }
    return false;
  }
}
