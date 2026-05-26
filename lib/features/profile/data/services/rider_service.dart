import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/rider_model.dart';

class RiderService {
  static const String _basePath = '/api/shop/delivery-drivers';

  Future<List<Rider>> getRiders() async {
    try {
      final response = await ApiClient().dio.get(_basePath);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final dynamic rawData = data['data'];
          List jsonList;
          if (rawData is List) {
            jsonList = rawData;
          } else if (rawData is Map && rawData['content'] is List) {
            jsonList = rawData['content'];
          } else {
            jsonList = [];
          }
          return jsonList.map((e) => Rider.fromJson(e)).toList();
        } else if (data['data'] == null && data['success'] == null) {
          if (data is List) {
            return (data as List).map((e) => Rider.fromJson(e)).toList();
          }
        }
      }

    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.getRiders');
    } catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.getRiders');
    }
    return [];
  }

  Future<Rider?> createRider(Map<String, dynamic> riderData, {File? image}) async {
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
          await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
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
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return Rider.fromJson(data['data']);
        }
        return Rider.fromJson(data);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.createRider');
    } catch (e) {
      ApiHelper.handleError(e, context: 'RiderService.createRider');
    }
    return null;
  }

  Future<Rider?> updateRider(int id, Map<String, dynamic> riderData, {File? image}) async {
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
          await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
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
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return Rider.fromJson(data['data']);
        }
        return Rider.fromJson(data);
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
