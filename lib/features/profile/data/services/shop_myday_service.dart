import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/features/profile/data/models/shop_myday.dart';
import 'package:path/path.dart' as p;

class ShopMyDayService {
  static const _path = '/api/shop/mydays';

  final Dio _dio = ApiClient().dio;

  Future<List<ShopMyDay>> list() async {
    try {
      final response = await _dio.get(_path);
      final body = response.data;
      if (body is! Map || body['success'] != true || body['data'] is! List) {
        return [];
      }

      return (body['data'] as List)
          .whereType<Map>()
          .map((json) => ShopMyDay.fromJson(json.cast<String, dynamic>()))
          .where((item) => item.imageUrl.isNotEmpty && item.isActive)
          .toList();
    } on DioException catch (error) {
      ApiHelper.handleError(error, context: 'ShopMyDayService.list');
      rethrow;
    }
  }

  Future<ShopMyDay> create(XFile photo) async {
    try {
      final extension = p.extension(photo.name).toLowerCase();
      final subtype = switch (extension) {
        '.png' => 'png',
        '.webp' => 'webp',
        '.gif' => 'gif',
        '.heic' => 'heic',
        '.heif' => 'heif',
        _ => 'jpeg',
      };

      final MultipartFile file;
      if (kIsWeb) {
        file = MultipartFile.fromBytes(
          await photo.readAsBytes(),
          filename: photo.name,
          contentType: MediaType('image', subtype),
        );
      } else {
        file = await MultipartFile.fromFile(
          photo.path,
          filename: photo.name,
          contentType: MediaType('image', subtype),
        );
      }

      final response = await _dio.post(
        _path,
        data: FormData.fromMap({'photo': file}),
      );
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return ShopMyDay.fromJson(
          (body['data'] as Map).cast<String, dynamic>(),
        );
      }
      throw StateError('The server returned an invalid MyDay response.');
    } on DioException catch (error) {
      ApiHelper.handleError(error, context: 'ShopMyDayService.create');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final response = await _dio.delete('$_path/$id');
      final body = response.data;
      if (body is Map && body['success'] == false) {
        throw StateError(body['message']?.toString() ?? 'Delete failed.');
      }
    } on DioException catch (error) {
      ApiHelper.handleError(error, context: 'ShopMyDayService.delete');
      rethrow;
    }
  }
}
