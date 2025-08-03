class Repair {
  final int id;
  final int vehicleId;
  final int mechanicId;
  final String mechanicName;
  final String description;
  final String status;
  final double? estimatedCost;
  final double? actualCost;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Repair({
    required this.id,
    required this.vehicleId,
    required this.mechanicId,
    required this.mechanicName,
    required this.description,
    required this.status,
    this.estimatedCost,
    this.actualCost,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Repair.fromJson(Map<String, dynamic> json) {
    return Repair(
      id: json['id'] as int,
      vehicleId: json['vehicle_id'] as int,
      mechanicId: json['mechanic_id'] as int,
      mechanicName: json['mechanic_name'] as String? ?? '',
      description: json['description'] as String,
      status: json['status'] as String,
      estimatedCost: json['estimated_cost']?.toDouble(),
      actualCost: json['actual_cost']?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'mechanic_id': mechanicId,
      'mechanic_name': mechanicName,
      'description': description,
      'status': status,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CreateRepairRequest {
  final int vehicleId;
  final int mechanicId;
  final String description;
  final double? estimatedCost;

  const CreateRepairRequest({
    required this.vehicleId,
    required this.mechanicId,
    required this.description,
    this.estimatedCost,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'mechanic_id': mechanicId,
      'description': description,
      'estimated_cost': estimatedCost,
    };
  }
}

class UpdateRepairRequest {
  final String? description;
  final String? status;
  final double? actualCost;

  const UpdateRepairRequest({
    this.description,
    this.status,
    this.actualCost,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (description != null) data['description'] = description;
    if (status != null) data['status'] = status;
    if (actualCost != null) data['actual_cost'] = actualCost;
    return data;
  }
}