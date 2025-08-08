import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/models/repair.dart';
import '../../../../core/models/spare_part.dart';
import '../../../../core/network/api_client.dart';

// Temporary classes for now until proper models are created
class RepairItem {
  final int id;
  final int repairId;
  final int sparePartId;
  final String sparePartName;
  final String? sparePartCode;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  RepairItem({
    required this.id,
    required this.repairId,
    required this.sparePartId,
    required this.sparePartName,
    this.sparePartCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory RepairItem.fromJson(Map<String, dynamic> json) {
    return RepairItem(
      id: json['id'] ?? 0,
      repairId: json['repair_id'] ?? 0,
      sparePartId: json['spare_part_id'] ?? 0,
      sparePartName: json['spare_part_name'] ?? '',
      sparePartCode: json['spare_part_code'],
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }
}

class RepairWithItems {
  final Repair repair;
  final List<RepairItem> items;

  RepairWithItems({
    required this.repair,
    required this.items,
  });

  // Getter for vehicle ID since vehicle object is not available in repair
  int get vehicleId => repair.vehicleId;

  // Getter for total spare parts cost
  double get totalSparePartsCost {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Getter for total cost (spare parts + actual cost if available)
  double get totalCost {
    return totalSparePartsCost + (repair.actualCost ?? 0.0);
  }

  factory RepairWithItems.fromJson(Map<String, dynamic> json) {
    return RepairWithItems(
      repair: Repair.fromJson(json['repair'] ?? {}),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => RepairItem.fromJson(item))
          .toList(),
    );
  }
}

class CreateRepairItemRequest {
  final int sparePartId;
  final int quantity;
  final double unitPrice;

  CreateRepairItemRequest({
    required this.sparePartId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'spare_part_id': sparePartId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}

class UpdateRepairItemRequest {
  final int? quantity;
  final double? unitPrice;

  UpdateRepairItemRequest({
    this.quantity,
    this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (quantity != null) data['quantity'] = quantity;
    if (unitPrice != null) data['unit_price'] = unitPrice;
    return data;
  }
}

class MechanicRepairService {
  final ApiClient _apiClient;

  MechanicRepairService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get repairs assigned to mechanic
  Future<List<RepairWithItems>> getMechanicRepairs({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.repairs,
        queryParameters: {
          'status': status,
          'page': page,
          'limit': limit,
          'role': 'mechanic',
        },
      );

      // Safe null check for repairs data
      final dynamic responseData = response.data['data'];
      if (responseData == null) {
        return <RepairWithItems>[];
      }

      final dynamic repairsData = responseData['repairs'];
      if (repairsData == null) {
        return <RepairWithItems>[];
      }

      final List<dynamic> repairsList =
          repairsData as List<dynamic>? ?? <dynamic>[];
      return repairsList
          .map((repair) => RepairWithItems.fromJson(repair))
          .toList();
    } catch (e) {
      throw Exception('Failed to get mechanic repairs: $e');
    }
  }

  /// Get repair detail with items
  Future<RepairWithItems> getRepairDetail({
    required int repairId,
  }) async {
    try {
      // Get repair detail
      final repairResponse = await _apiClient.get(
        ApiEndpoints.repairDetail(repairId),
      );

      final repair =
          Repair.fromJson(repairResponse.data['data'] as Map<String, dynamic>);

      // Get repair items
      final itemsResponse = await _apiClient.get(
        ApiEndpoints.repairItems(repairId),
      );

      final dynamic itemsResponseData = itemsResponse.data['data'];
      final List<dynamic> itemsData =
          itemsResponseData as List<dynamic>? ?? <dynamic>[];
      final items = itemsData.map((item) => RepairItem.fromJson(item)).toList();

      return RepairWithItems(
        repair: repair,
        items: items,
      );
    } catch (e) {
      throw Exception('Failed to get repair detail: $e');
    }
  }

  /// Get repair basic info only
  Future<Repair> getRepairInfo({
    required int repairId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.repairDetail(repairId),
      );

      return Repair.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get repair detail: $e');
    }
  }

  /// Get repair items
  Future<List<RepairItem>> getRepairItems({
    required int repairId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.repairItems(repairId),
      );

      final dynamic itemsResponseData = response.data['data'];
      final List<dynamic> itemsData =
          itemsResponseData as List<dynamic>? ?? <dynamic>[];
      return itemsData.map((item) => RepairItem.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get repair items: $e');
    }
  }

  /// Update repair status
  Future<Repair> updateRepairStatus({
    required int repairId,
    required String status,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'status': status,
      };

      if (notes != null) {
        data['notes'] = notes;
      }

      final response = await _apiClient.put(
        '/api/repairs/$repairId/status',
        data: data,
      );

      return Repair.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update repair status: $e');
    }
  }

  /// Add spare part to repair
  Future<RepairItem> addRepairItem({
    required int repairId,
    required CreateRepairItemRequest request,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/repairs/$repairId/items',
        data: request.toJson(),
      );

      return RepairItem.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add repair item: $e');
    }
  }

  /// Update repair item
  Future<RepairItem> updateRepairItem({
    required int repairId,
    required int itemId,
    required UpdateRepairItemRequest request,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/repairs/$repairId/items/$itemId',
        data: request.toJson(),
      );

      return RepairItem.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update repair item: $e');
    }
  }

  /// Remove repair item
  Future<void> removeRepairItem({
    required int repairId,
    required int itemId,
  }) async {
    try {
      await _apiClient.delete(
        '/api/repairs/$repairId/items/$itemId',
      );
    } catch (e) {
      throw Exception('Failed to remove repair item: $e');
    }
  }

  /// Search spare parts for repair
  Future<List<SparePart>> searchSpareParts(String query,
      {int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/api/spare-parts/search',
        queryParameters: {
          'q': query,
          'limit': limit,
          'is_active': true,
        },
      );

      // Safe null check for spare parts data
      final dynamic responseData = response.data['data'];
      if (responseData == null) {
        return <SparePart>[];
      }

      final dynamic sparePartsData = responseData['spare_parts'];
      if (sparePartsData == null) {
        return <SparePart>[];
      }

      final List<dynamic> sparePartsList =
          sparePartsData as List<dynamic>? ?? <dynamic>[];
      return sparePartsList
          .map((sparePart) =>
              SparePart.fromJson(sparePart as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search spare parts: $e');
    }
  }

  /// Add spare part to repair
  Future<RepairItem> addSparePartToRepair(
    int repairId,
    int sparePartId,
    int quantity,
    double unitPrice,
    String? notes,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.repairItems(repairId),
        data: {
          'spare_part_id': sparePartId,
          'quantity': quantity,
          'unit_price': unitPrice,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      return RepairItem.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add spare part to repair: $e');
    }
  }

  /// Complete repair with labor cost
  Future<Repair> completeRepair({
    required int repairId,
    required double laborCost,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'status': 'completed',
        'labor_cost': laborCost,
      };

      if (notes != null) {
        data['completion_notes'] = notes;
      }

      final response = await _apiClient.put(
        '/api/repairs/$repairId/complete',
        data: data,
      );

      return Repair.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to complete repair: $e');
    }
  }

  /// Start repair work
  Future<Repair> startRepair({
    required int repairId,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'status': 'in_progress',
      };

      if (notes != null) {
        data['notes'] = notes;
      }

      final response = await _apiClient.put(
        '/api/repairs/$repairId/start',
        data: data,
      );

      return Repair.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to start repair: $e');
    }
  }
}
