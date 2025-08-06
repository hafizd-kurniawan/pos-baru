import 'repair.dart';
import 'vehicle.dart';

class RepairItem {
  final int id;
  final int repairId;
  final int sparePartId;
  final String sparePartName;
  final String sparePartCode;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RepairItem({
    required this.id,
    required this.repairId,
    required this.sparePartId,
    required this.sparePartName,
    required this.sparePartCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RepairItem.fromJson(Map<String, dynamic> json) {
    return RepairItem(
      id: json['id'] as int,
      repairId: json['repair_id'] as int,
      sparePartId: json['spare_part_id'] as int,
      sparePartName: json['spare_part_name'] as String,
      sparePartCode: json['spare_part_code'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repair_id': repairId,
      'spare_part_id': sparePartId,
      'spare_part_name': sparePartName,
      'spare_part_code': sparePartCode,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RepairItem copyWith({
    int? id,
    int? repairId,
    int? sparePartId,
    String? sparePartName,
    String? sparePartCode,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RepairItem(
      id: id ?? this.id,
      repairId: repairId ?? this.repairId,
      sparePartId: sparePartId ?? this.sparePartId,
      sparePartName: sparePartName ?? this.sparePartName,
      sparePartCode: sparePartCode ?? this.sparePartCode,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RepairItem(id: $id, sparePartName: $sparePartName, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepairItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Request classes
class CreateRepairItemRequest {
  final int sparePartId;
  final int quantity;
  final double unitPrice;
  final String? notes;

  const CreateRepairItemRequest({
    required this.sparePartId,
    required this.quantity,
    required this.unitPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'spare_part_id': sparePartId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'notes': notes,
    };
  }
}

class UpdateRepairItemRequest {
  final int? quantity;
  final double? unitPrice;
  final String? notes;

  const UpdateRepairItemRequest({
    this.quantity,
    this.unitPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (quantity != null) data['quantity'] = quantity;
    if (unitPrice != null) data['unit_price'] = unitPrice;
    if (notes != null) data['notes'] = notes;
    return data;
  }
}

// Enhanced repair model with items
class RepairWithItems {
  final Repair repair;
  final List<RepairItem> items;
  final Vehicle? vehicle;
  final double totalSparePartsCost;
  final double totalCost;

  const RepairWithItems({
    required this.repair,
    required this.items,
    this.vehicle,
    required this.totalSparePartsCost,
    required this.totalCost,
  });

  factory RepairWithItems.fromJson(Map<String, dynamic> json) {
    final repairData = json['repair'] as Map<String, dynamic>;
    final itemsData = json['items'] as List<dynamic>? ?? [];
    final vehicleData = json['vehicle'] as Map<String, dynamic>?;

    return RepairWithItems(
      repair: Repair.fromJson(repairData),
      items: itemsData
          .map((item) => RepairItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      vehicle: vehicleData != null ? Vehicle.fromJson(vehicleData) : null,
      totalSparePartsCost:
          (json['total_spare_parts_cost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'repair': repair.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'vehicle': vehicle?.toJson(),
      'total_spare_parts_cost': totalSparePartsCost,
      'total_cost': totalCost,
    };
  }
}
