import 'package:dio/dio.dart';

import '../../../../core/models/spare_part_category.dart';
import '../../../../core/network/api_client.dart';

class SparePartCategoryResponse {
  final List<SparePartCategory> data;
  final bool hasMore;
  final int currentPage;
  final int total;

  const SparePartCategoryResponse({
    required this.data,
    required this.hasMore,
    required this.currentPage,
    required this.total,
  });
}

class SparePartCategoryService {
  final ApiClient _apiClient = ApiClient();

  /// Get list of spare part categories with pagination
  Future<SparePartCategoryResponse> getCategories({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
    required String token,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (isActive != null) {
        queryParams['active'] = isActive.toString();
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        '/api/spare-part-categories',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;

      // Backend sends data directly as array, not nested in 'categories'
      final categoriesData = data['data'] as List;
      final pagination = data['meta'];

      final categories = categoriesData
          .map((json) => SparePartCategory.fromJson(json))
          .toList();

      return SparePartCategoryResponse(
        data: categories,
        total: pagination['total'] ?? 0,
        hasMore: (pagination['page'] ?? 1) < (pagination['total_pages'] ?? 1),
        currentPage: pagination['page'] ?? 1,
      );
    } catch (e) {
      throw Exception('Failed to get spare part categories: $e');
    }
  }

  /// Get category by ID
  Future<SparePartCategory> getCategoryById(int id, String token) async {
    try {
      final response = await _apiClient.get(
        '/api/spare-part-categories/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data['data']['category'];
      return SparePartCategory.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get spare part category: $e');
    }
  }

  /// Create new category
  Future<SparePartCategory> createCategory({
    required CreateSparePartCategoryRequest request,
    required String token,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/spare-part-categories',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data['data']['category'];
      return SparePartCategory.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create spare part category: $e');
    }
  }

  /// Update category
  Future<SparePartCategory> updateCategory({
    required int id,
    required UpdateSparePartCategoryRequest request,
    required String token,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/spare-part-categories/$id',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data['data']['category'];
      return SparePartCategory.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update spare part category: $e');
    }
  }

  /// Delete category
  Future<void> deleteCategory(int id, String token) async {
    try {
      await _apiClient.delete(
        '/api/spare-part-categories/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to delete spare part category: $e');
    }
  }

  /// Get all categories (for dropdown)
  Future<List<SparePartCategory>> getAllCategories(String token) async {
    try {
      final response = await _apiClient.get(
        '/api/spare-part-categories/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data['data'] as List;
      return data.map((json) => SparePartCategory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get all spare part categories: $e');
    }
  }
}
