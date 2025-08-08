import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class CategoryService {
  final ApiClient _apiClient = ApiClient();

  /// Get categories with pagination and search
  Future<Map<String, dynamic>> getCategories({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        ApiEndpoints.categories,
        queryParameters: queryParams,
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Get category statistics
  Future<Map<String, dynamic>> getCategoryStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categoryStats);
      return response.data;
    } catch (e) {
      throw Exception('Failed to get category statistics: $e');
    }
  }

  /// Create new category
  Future<Map<String, dynamic>> createCategory(
      String name, String description) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.categories,
        data: {
          'name': name,
          'description': description,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update existing category
  Future<Map<String, dynamic>> updateCategory(
      int id, String name, String description) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.categoryById(id),
        data: {
          'name': name,
          'description': description,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete category
  Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.categoryById(id));
      return response.data;
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Get all active categories for dropdown/filter (simplified format)
  Future<List<String>> getAllCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categoriesAll);

      if (response.data['success'] == true &&
          response.data['data'] != null &&
          response.data['data']['categories'] != null) {
        final categories = response.data['data']['categories'] as List;
        return categories.cast<String>();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get all categories: $e');
    }
  }
}
