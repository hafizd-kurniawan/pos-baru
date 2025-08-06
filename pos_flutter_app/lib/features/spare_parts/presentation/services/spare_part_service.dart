import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/spare_part.dart';
import '../../../../core/network/api_client.dart';

class SparePartResponse {
  final List<SparePart> data;
  final bool hasMore;
  final int currentPage;
  final int total;

  const SparePartResponse({
    required this.data,
    required this.hasMore,
    required this.currentPage,
    required this.total,
  });
}

class SparePartService {
  final ApiClient _apiClient = ApiClient();

  /// Get list of spare parts with pagination and filters
  Future<SparePartResponse> getSpareParts({
    int page = 1,
    int limit = 20,
    String? search,
    String? stockFilter,
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

      if (stockFilter != null) {
        queryParams['stock_filter'] = stockFilter;
      }

      final response = await _apiClient.get(
        ApiEndpoints.spareParts,
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      final sparePartsData = data['data']['spare_parts'] as List;
      final pagination = data['data']['pagination'];

      final spareParts =
          sparePartsData.map((json) => SparePart.fromJson(json)).toList();

      return SparePartResponse(
        data: spareParts,
        total: pagination['total'] ?? 0,
        hasMore: (pagination['current_page'] ?? 1) <
            (pagination['total_pages'] ?? 1),
        currentPage: pagination['current_page'] ?? 1,
      );
    } catch (e) {
      throw Exception('Failed to get spare parts: $e');
    }
  }

  /// Get spare part by ID
  Future<SparePart> getSparePartById(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.sparePartById(id));
      final data = response.data['data']['spare_part'];
      return SparePart.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get spare part: $e');
    }
  }

  /// Get spare part by code
  Future<SparePart> getSparePartByCode(String code) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.sparePartByCode(code));
      final data = response.data['data']['spare_part'];
      return SparePart.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get spare part: $e');
    }
  }

  /// Create new spare part
  Future<SparePart> createSparePart({
    required CreateSparePartRequest request,
    required String token,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.spareParts,
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data['data']['spare_part'];
      return SparePart.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create spare part: $e');
    }
  }

  /// Update spare part
  Future<SparePart> updateSparePart({
    required int id,
    required UpdateSparePartRequest request,
    required String token,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.sparePartById(id),
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data['data']['spare_part'];
      return SparePart.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update spare part: $e');
    }
  }

  /// Delete spare part
  Future<void> deleteSparePart({
    required int id,
    required String token,
  }) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.sparePartById(id),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to delete spare part: $e');
    }
  }

  /// Update spare part stock
  Future<SparePart> updateStock({
    required int id,
    required UpdateStockRequest request,
    required String token,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.updateSparePartStock(id),
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data['data']['spare_part'];
      return SparePart.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  /// Get low stock spare parts
  Future<List<SparePart>> getLowStockSpareParts() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.lowStockSpareParts);
      final data = response.data['data']['spare_parts'] as List;
      return data.map((json) => SparePart.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get low stock spare parts: $e');
    }
  }
}
