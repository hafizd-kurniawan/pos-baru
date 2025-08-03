import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/models/vehicle_type.dart';

class VehicleTypeService {
  final ApiClient _apiClient;

  VehicleTypeService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<VehicleType>> getVehicleTypes() async {
    final response = await _apiClient.get(ApiEndpoints.vehicleTypes);
    
    // Handle backend response structure: {success, message, data}
    final responseData = response.data;
    final listData = responseData['data'] ?? responseData;
    
    if (listData is List) {
      return listData.map((json) => VehicleType.fromJson(json)).toList();
    }
    return [];
  }

  Future<VehicleType> getVehicleTypeById(int id) async {
    final response = await _apiClient.get(ApiEndpoints.vehicleTypeById(id));
    
    // Handle backend response structure: {success, message, data}
    final responseData = response.data;
    final typeData = responseData['data'] ?? responseData;
    
    return VehicleType.fromJson(typeData);
  }

  Future<VehicleType> createVehicleType(CreateVehicleTypeRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.vehicleTypes,
      data: request.toJson(),
    );
    
    // Handle backend response structure: {success, message, data}
    final responseData = response.data;
    final typeData = responseData['data'] ?? responseData;
    
    return VehicleType.fromJson(typeData);
  }

  Future<VehicleType> updateVehicleType(int id, UpdateVehicleTypeRequest request) async {
    final response = await _apiClient.put(
      ApiEndpoints.vehicleTypeById(id),
      data: request.toJson(),
    );
    
    // Handle backend response structure: {success, message, data}
    final responseData = response.data;
    final typeData = responseData['data'] ?? responseData;
    
    return VehicleType.fromJson(typeData);
  }

  Future<void> deleteVehicleType(int id) async {
    await _apiClient.delete(ApiEndpoints.vehicleTypeById(id));
  }
}
