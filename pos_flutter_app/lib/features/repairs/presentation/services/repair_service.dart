import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/repair.dart';
import '../../../../core/network/api_client.dart';

class RepairService {
  final ApiClient _apiClient;

  RepairService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get repairs with pagination
  Future<List<Repair>> getRepairs({
    required String token,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        ApiEndpoints.repairs,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> repairsData =
            response.data['data']['repairs'] ?? [];
        return repairsData.map((data) => Repair.fromJson(data)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get repairs');
      }
    } catch (e) {
      throw Exception('Failed to get repairs: $e');
    }
  }

  /// Get repair by ID
  Future<Repair> getRepairById({
    required int id,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.repairById(id),
      );

      if (response.data['success'] == true) {
        return Repair.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get repair');
      }
    } catch (e) {
      throw Exception('Failed to get repair: $e');
    }
  }

  /// Create new repair
  Future<Repair> createRepair({
    required CreateRepairRequest request,
    required String token,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.repairs,
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        return Repair.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create repair');
      }
    } catch (e) {
      throw Exception('Failed to create repair: $e');
    }
  }

  /// Update repair
  Future<Repair> updateRepair({
    required int id,
    required UpdateRepairRequest request,
    required String token,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.repairById(id),
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        return Repair.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update repair');
      }
    } catch (e) {
      throw Exception('Failed to update repair: $e');
    }
  }

  /// Delete repair
  Future<void> deleteRepair({
    required int id,
    required String token,
  }) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.repairById(id),
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete repair');
      }
    } catch (e) {
      throw Exception('Failed to delete repair: $e');
    }
  }

  /// Update repair progress
  Future<void> updateRepairProgress({
    required int id,
    required String status,
    required double actualCost,
    String? notes,
    required List<RepairSparePartRequest> spareParts,
    required String token,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.updateRepairProgress(id),
        data: {
          'status': status,
          'actual_cost': actualCost,
          'notes': notes,
          'spare_parts': spareParts.map((sp) => sp.toJson()).toList(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] != true) {
        throw Exception(
            response.data['message'] ?? 'Failed to update repair progress');
      }
    } catch (e) {
      throw Exception('Failed to update repair progress: $e');
    }
  }

  /// Add spare part to repair order
  Future<void> addSparePartToRepair({
    required int repairId,
    required int sparePartId,
    required int quantityUsed,
    required String token,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.repairSpareParts(repairId),
        data: {
          'spare_part_id': sparePartId,
          'quantity_used': quantityUsed,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] != true) {
        throw Exception(
            response.data['message'] ?? 'Failed to add spare part to repair');
      }
    } catch (e) {
      throw Exception('Failed to add spare part to repair: $e');
    }
  }

  /// Create new repair order
  Future<Repair> createRepairOrder({
    required String code,
    required int vehicleId,
    required int mechanicId,
    String? description,
    double estimatedCost = 0.0,
    String? notes,
    required String token,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.repairs,
        data: {
          'code': code,
          'vehicle_id': vehicleId,
          'mechanic_id': mechanicId,
          'description':
              description ?? 'Repair created from mechanic spare parts page',
          'estimated_cost': estimatedCost,
          'notes': notes,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return Repair.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create repair');
      }
    } catch (e) {
      throw Exception('Failed to create repair: $e');
    }
  }
}

/// Request model for repair spare part
class RepairSparePartRequest {
  final int sparePartId;
  final int quantityUsed;

  RepairSparePartRequest({
    required this.sparePartId,
    required this.quantityUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'spare_part_id': sparePartId,
      'quantity_used': quantityUsed,
    };
  }
}
