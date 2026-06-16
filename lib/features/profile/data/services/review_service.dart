import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/review_model.dart';

class ReviewService {
  static const String _reviewsPath = '/api/shop/reviews';
  static const String _summaryPath = '/api/shop/reviews/summary';

  Future<ReviewSummaryModel?> getReviewSummary() async {
    try {
      final response = await ApiClient().dio.get(_summaryPath);

      if (response.data['success'] == true && response.data['data'] != null) {
        return ReviewSummaryModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.getReviewSummary');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.getReviewSummary');
    }
    return null;
  }

  Future<List<ReviewModel>> getReviews({int page = 1, int size = 10}) async {
    try {
      final response = await ApiClient().dio.get(
        _reviewsPath,
        queryParameters: {'page': page, 'size': size},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        // shop/reviews returns a Spring-style page object:
        // data: { content: [...], totalElements, totalPages, page, size }
        final data = response.data['data'];
        final List<dynamic> list = data is Map
            ? (data['content'] as List? ?? const [])
            : (data as List);
        return list
            .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.getReviews');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.getReviews');
    }
    return [];
  }

  Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await ApiClient().dio.delete('$_reviewsPath/$reviewId');
      return response.data is Map && response.data['success'] == true;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.deleteReview');
      return false;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.deleteReview');
      return false;
    }
  }

  /// Reply to (or update the reply on) a review.
  /// PUT /api/shop/reviews/{id}/reply with body { reply }.
  Future<bool> replyReview(String reviewId, String replyText) async {
    try {
      final response = await ApiClient().dio.put(
        '$_reviewsPath/$reviewId/reply',
        data: {'reply': replyText},
      );
      return response.data is Map && response.data['success'] == true;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.replyReview');
      return false;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ReviewService.replyReview');
      return false;
    }
  }
}
