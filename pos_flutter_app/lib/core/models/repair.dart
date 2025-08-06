import 'package:flutter/material.dart';

import 'spare_part.dart';
import 'user.dart';
import 'vehicle.dart';

class RepairOrder {
  final int id;
  final String code;
  final int vehicleId;
  final Vehicle? vehicle;
  final int mechanicId;
  final User? mechanic;
  final int assignedBy;
  final User? assignedByUser;
  final String description;
  final double estimatedCost;
  final double? actualCost;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final List<RepairSparePart>? spareParts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RepairOrder({
    required this.id,
    required this.code,
    required this.vehicleId,
    this.vehicle,
    required this.mechanicId,
    this.mechanic,
    required this.assignedBy,
    this.assignedByUser,
    required this.description,
    required this.estimatedCost,
    this.actualCost,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.spareParts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RepairOrder.fromJson(Map<String, dynamic> json) {
    return RepairOrder(
      id: json['id'] as int,
      code: json['code'] as String,
      vehicleId: json['vehicle_id'] as int,
      vehicle:
          json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      mechanicId: json['mechanic_id'] as int,
      mechanic:
          json['mechanic'] != null ? User.fromJson(json['mechanic']) : null,
      assignedBy: json['assigned_by'] as int,
      assignedByUser: json['assigner'] != null
          ? User.fromJson(json['assigner'])
          : (json['assigned_by_user'] != null
              ? User.fromJson(json['assigned_by_user'])
              : null),
      description: json['description'] as String,
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
      actualCost: json['actual_cost']?.toDouble(),
      status: json['status'] as String,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      spareParts: json['spare_parts'] != null
          ? (json['spare_parts'] as List)
              .map((e) => RepairSparePart.fromJson(e))
              .toList()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  double get totalSparePartsCost {
    if (spareParts == null) return 0.0;
    return spareParts!.fold(0.0, (sum, part) => sum + part.totalPrice);
  }

  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'in_progress':
        return 'Dalam Proses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'vehicle_id': vehicleId,
      'vehicle': vehicle?.toJson(),
      'mechanic_id': mechanicId,
      'mechanic': mechanic?.toJson(),
      'assigned_by': assignedBy,
      'assigned_by_user': assignedByUser?.toJson(),
      'description': description,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'status': status,
      'notes': notes,
      'spare_parts': spareParts?.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class RepairSparePart {
  final int id;
  final int repairId;
  final int sparePartId;
  final SparePart? sparePart;
  final int quantityUsed;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;

  const RepairSparePart({
    required this.id,
    required this.repairId,
    required this.sparePartId,
    this.sparePart,
    required this.quantityUsed,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
  });

  factory RepairSparePart.fromJson(Map<String, dynamic> json) {
    return RepairSparePart(
      id: json['id'] as int,
      repairId: json['repair_order_id'] as int,
      sparePartId: json['spare_part_id'] as int,
      sparePart: json['spare_part'] != null
          ? SparePart.fromJson(json['spare_part'])
          : null,
      quantityUsed: json['quantity_used'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repair_order_id': repairId,
      'spare_part_id': sparePartId,
      'spare_part': sparePart?.toJson(),
      'quantity_used': quantityUsed,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class RepairOrderCreateRequest {
  final int vehicleId;
  final int mechanicId;
  final String description;
  final double estimatedCost;
  final String? notes;

  const RepairOrderCreateRequest({
    required this.vehicleId,
    required this.mechanicId,
    required this.description,
    required this.estimatedCost,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'mechanic_id': mechanicId,
      'description': description,
      'estimated_cost': estimatedCost,
      'notes': notes,
    };
  }
}

class RepairOrderUpdateRequest {
  final String? description;
  final String? status;
  final double? estimatedCost;
  final double? actualCost;
  final String? notes;

  const RepairOrderUpdateRequest({
    this.description,
    this.status,
    this.estimatedCost,
    this.actualCost,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (description != null) data['description'] = description;
    if (status != null) data['status'] = status;
    if (estimatedCost != null) data['estimated_cost'] = estimatedCost;
    if (actualCost != null) data['actual_cost'] = actualCost;
    if (notes != null) data['notes'] = notes;
    return data;
  }
}

class RepairProgressUpdateRequest {
  final String status;
  final double? actualCost;
  final String? notes;

  const RepairProgressUpdateRequest({
    required this.status,
    this.actualCost,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'actual_cost': actualCost,
      'notes': notes,
    };
  }
}

class RepairSparePartCreateRequest {
  final int sparePartId;
  final int quantityUsed;

  const RepairSparePartCreateRequest({
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

// Backward compatibility aliases
typedef Repair = RepairOrder;
typedef CreateRepairRequest = RepairOrderCreateRequest;
typedef UpdateRepairRequest = RepairOrderUpdateRequest;

// Backward compatibility getters
extension RepairOrderBackwardCompatibility on RepairOrder {
  String get mechanicName => mechanic?.name ?? 'Unknown Mechanic';
}
