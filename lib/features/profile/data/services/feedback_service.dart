import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  static const String _feedbackPath = '/api/shop/feedback';

  Future<List<FeedbackModel>> getFeedbacks() async {
    try {
      debugPrint('GET REQUEST: $_feedbackPath');
      final response = await ApiClient().dio.get(_feedbackPath);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> feedbackJson = data['data'];
          return feedbackJson.map((e) => FeedbackModel.fromJson(e)).toList();
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'FeedbackService.getFeedbacks');
    } catch (e) {
      ApiHelper.handleError(e, context: 'FeedbackService.getFeedbacks');
    }
    return [];
  }

  Future<bool> createFeedback(String description) async {
    try {
      debugPrint('POST REQUEST: $_feedbackPath');
      final response = await ApiClient().dio.post(
        _feedbackPath,
        data: {'description': description},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'FeedbackService.createFeedback');
    } catch (e) {
      ApiHelper.handleError(e, context: 'FeedbackService.createFeedback');
    }
    return false;
  }
}
