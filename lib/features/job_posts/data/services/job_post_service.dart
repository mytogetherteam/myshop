import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';

import '../models/job_post_model.dart';

class JobPostService {
  static const String _basePath = '/api/shop/job-posts';

  final Dio _dio = ApiClient().dio;

  List<JobPostModel> _parseList(dynamic rawData) {
    if (rawData is List) {
      return rawData
          .whereType<Map>()
          .map((e) => JobPostModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<JobPostListResult> getJobPosts({
    int page = 1,
    int size = 20,
    String? search,
    JobType? jobType,
    JobPostStatus? status,
  }) async {
    try {
      final response = await _dio.get(
        _basePath,
        queryParameters: {
          'page': page,
          'size': size,
          if (search != null && search.isNotEmpty) 'search': search,
          if (jobType != null) 'jobType': jobTypeToApi(jobType),
          if (status != null) 'status': jobPostStatusToApi(status),
        },
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
        return JobPostListResult(
          items: items,
          total: total,
          page: page,
          hasMore: page < lastPage,
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.getJobPosts');
    } catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.getJobPosts');
    }
    return JobPostListResult(
      items: const [],
      total: 0,
      page: page,
      hasMore: false,
    );
  }

  Future<JobPostModel?> getJobPost(int id) async {
    try {
      final response = await _dio.get('$_basePath/$id');
      final body = response.data;
      if (body is Map &&
          body['success'] == true &&
          body['data'] is Map) {
        return JobPostModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.getJobPost');
    } catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.getJobPost');
    }
    return null;
  }

  Future<JobPostModel?> createJobPost(JobPostModel draft) async {
    try {
      final response = await _dio.post(_basePath, data: draft.toCreateJson());
      final body = response.data;
      if (body is Map &&
          body['success'] == true &&
          body['data'] is Map) {
        return JobPostModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.createJobPost');
      rethrow;
    } catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.createJobPost');
      rethrow;
    }
    return null;
  }

  Future<JobPostModel?> updateJobPost(int id, JobPostModel draft) async {
    try {
      final response =
          await _dio.patch('$_basePath/$id', data: draft.toUpdateJson());
      final body = response.data;
      if (body is Map &&
          body['success'] == true &&
          body['data'] is Map) {
        return JobPostModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.updateJobPost');
      rethrow;
    } catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.updateJobPost');
      rethrow;
    }
    return null;
  }

  Future<bool> deleteJobPost(int id) async {
    try {
      final response = await _dio.delete('$_basePath/$id');
      final body = response.data;
      return body is Map && body['success'] == true;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.deleteJobPost');
    } catch (e) {
      ApiHelper.handleError(e, context: 'JobPostService.deleteJobPost');
    }
    return false;
  }
}
