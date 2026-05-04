import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/review_model.dart';

class ReviewService {
  static const String _summaryPath = '/api/shop/reviews/summary';
  static const String _reviewsPath = '/api/shop/reviews';

  Future<ReviewSummaryModel?> getReviewSummary() async {
    try {
      final response = await ApiClient().dio.get(_summaryPath);

      if (response.data['success'] == true) {
        return ReviewSummaryModel.fromJson(response.data['data']);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.getReviewSummary');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.getReviewSummary');
    }
    return null;
  }

  Future<List<ReviewModel>> getReviews({int page = 1, int limit = 10}) async {
    try {
      final response = await ApiClient().dio.get(
        _reviewsPath,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => ReviewModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.getReviews');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.getReviews');
    }
    return [];
  }
}
