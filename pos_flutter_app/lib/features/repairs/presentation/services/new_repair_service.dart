import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/repair.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/network/api_client.dart';

class RepairService {
  final ApiClient _apiClient;

  RepairService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get all repair orders
  Future<List<RepairOrder>> getRepairOrders({
    String? status,
    int? mechanicId,
    int page = 1,
    int limit = 20,
    String? role,
  }) async {
    print(
        'Getting repair orders with params: status=$status, mechanicId=$mechanicId, page=$page, limit=$limit, role=$role');

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (status != null && status != 'all') queryParams['status'] = status;
    if (mechanicId != null) queryParams['mechanic_id'] = mechanicId;
    if (role != null) queryParams['role'] = role;

    try {
      print(
          'Making API request to ${ApiEndpoints.repairs} with params: $queryParams');

      final response = await _apiClient.get(
        ApiEndpoints.repairs,
        queryParameters: queryParams,
      );

      print('API Response: ${response.data}');

      final data = response.data;
      if (data['data'] == null) {
        print('No repair data found in response');
        return [];
      }

      // Response structure: { data: { repairs: [...], pagination: {...} } }
      final responseData = data['data'];
      if (responseData['repairs'] == null) {
        print('No repairs array found in response data');
        return [];
      }

      final List<dynamic> repairsList = responseData['repairs'];
      print('Found ${repairsList.length} repairs');

      return repairsList.map((json) => RepairOrder.fromJson(json)).toList();
    } catch (e) {
      print('Error getting repair orders: $e');
      rethrow;
    }
  }

  /// Get repair order by ID
  Future<RepairOrder> getRepairOrderById(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.repairs}/$id');
    return RepairOrder.fromJson(response.data['data']);
  }

  /// Get detailed repair order with spare parts
  Future<RepairOrder?> getRepairDetail(int id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.repairs}/$id');

      if (response.data['data'] != null) {
        final repair = RepairOrder.fromJson(response.data['data']);
        return repair;
      }
      return null;
    } catch (e) {
      print('Error getting repair detail: $e');
      rethrow;
    }
  }

  /// Create new repair order
  Future<RepairOrder> createRepairOrder(
      RepairOrderCreateRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.repairs,
      data: request.toJson(),
    );
    return RepairOrder.fromJson(response.data['data']);
  }

  /// Update repair order
  Future<RepairOrder> updateRepairOrder(
      int id, RepairOrderUpdateRequest request) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.repairs}/$id',
      data: request.toJson(),
    );
    return RepairOrder.fromJson(response.data['data']);
  }

  /// Update repair progress (status, actual cost)
  Future<RepairOrder> updateRepairProgress(
      int id, RepairProgressUpdateRequest request) async {
    print('Updating repair progress for ID $id with data: ${request.toJson()}');

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.updateRepairProgress(id),
        data: request.toJson(),
      );
      print('Update progress response: ${response.data}');

      if (response.data == null) {
        throw Exception('Empty response from server');
      }

      if (response.data['data'] == null) {
        throw Exception('Invalid response format: missing data field');
      }

      return RepairOrder.fromJson(response.data['data']);
    } catch (e) {
      print('Update progress error: $e');
      if (e.toString().contains('404')) {
        throw Exception('Endpoint tidak ditemukan - silakan hubungi admin');
      } else if (e.toString().contains('500')) {
        throw Exception('Server error - silakan coba lagi nanti');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Koneksi timeout - periksa koneksi internet');
      } else {
        throw Exception('Gagal mengupdate progress: ${e.toString()}');
      }
    }
  }

  /// Complete repair order
  Future<RepairOrder> completeRepairOrder(int id,
      {double? actualCost, String? notes}) async {
    print(
        'Completing repair order $id with actualCost: $actualCost, notes: $notes');

    try {
      // First get current repair to check status
      final currentRepair = await getRepairOrderById(id);
      print('Current repair status: ${currentRepair.status}');

      // If status is pending, first move to in_progress
      if (currentRepair.status == 'pending') {
        print('Repair is pending, moving to in_progress first...');
        await updateRepairProgress(
            id,
            RepairProgressUpdateRequest(
              status: 'in_progress',
            ));
        print('Successfully moved to in_progress');
      }

      print('Now completing repair...');
      // Use progress update endpoint to complete repair
      final request = RepairProgressUpdateRequest(
        status: 'completed',
        actualCost: actualCost,
        notes: notes,
      );

      print('Request data: ${request.toJson()}');
      final result = await updateRepairProgress(id, request);
      print('Repair completed successfully, result: ${result.toJson()}');
      return result;
    } catch (e) {
      print('Failed to complete repair: $e');
      throw Exception('Tidak dapat menyelesaikan reparasi: $e');
    }
  }

  /// Delete repair order
  Future<void> deleteRepairOrder(int id) async {
    await _apiClient.delete('${ApiEndpoints.repairs}/$id');
  }

  /// Get spare parts for a repair order
  Future<List<RepairSparePart>> getRepairSpareParts(int repairId) async {
    final response =
        await _apiClient.get('${ApiEndpoints.repairs}/$repairId/spare-parts');
    final List<dynamic> sparePartsList = response.data['data'];
    return sparePartsList
        .map((json) => RepairSparePart.fromJson(json))
        .toList();
  }

  /// Add spare part to repair order
  Future<RepairSparePart> addSparePartToRepair(
      int repairId, RepairSparePartCreateRequest request) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.repairs}/$repairId/spare-parts',
      data: request.toJson(),
    );
    return RepairSparePart.fromJson(response.data['data']);
  }

  /// Remove spare part from repair order
  Future<void> removeSparePartFromRepair(int repairId, int sparePartId) async {
    await _apiClient
        .delete('${ApiEndpoints.repairs}/$repairId/spare-parts/$sparePartId');
  }

  /// Get repair statistics
  Future<Map<String, dynamic>> getRepairStats({
    int? mechanicId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, dynamic>{};

    if (mechanicId != null) queryParams['mechanic_id'] = mechanicId;
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();

    final response = await _apiClient.get(
      '${ApiEndpoints.repairStats}',
      queryParameters: queryParams,
    );

    return response.data['data'];
  }

  /// Get mechanic workload
  Future<List<Map<String, dynamic>>> getMechanicWorkload() async {
    final response = await _apiClient.get('${ApiEndpoints.mechanicWorkload}');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  /// Get vehicles that need repair orders (vehicles with in_repair status but no active repair order)
  Future<List<Vehicle>> getVehiclesNeedingRepairOrders() async {
    try {
      final response = await _apiClient
          .get('${ApiEndpoints.repairs}/vehicles-needing-orders');

      final List<dynamic> vehiclesList = response.data['data'];
      return vehiclesList.map((json) => Vehicle.fromJson(json)).toList();
    } catch (e) {
      print('Error getting vehicles needing repair orders: $e');
      return [];
    }
  }
}
