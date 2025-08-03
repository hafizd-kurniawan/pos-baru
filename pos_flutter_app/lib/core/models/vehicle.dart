class VehicleBrand {
  final int id;
  final String name;
  final int typeId;
  final DateTime createdAt;

  const VehicleBrand({
    required this.id,
    required this.name,
    required this.typeId,
    required this.createdAt,
  });

  factory VehicleBrand.fromJson(Map<String, dynamic> json) {
    print('VehicleBrand.fromJson: Received JSON: $json');

    return VehicleBrand(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      typeId: (json['type_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type_id': typeId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Vehicle {
  final int id;
  final String code;
  final int brandId;
  final String model;
  final int year;
  final String? color;
  final String? engineCapacity;
  final String? fuelType;
  final String? transmissionType;
  final String? licensePlate;
  final String? chassisNumber;
  final String? engineNumber;
  final int odometer;
  final String sourceType;
  final int? sourceId;
  final double purchasePrice;
  final String conditionStatus;
  final String status;
  final double? repairCost;
  final double? hppPrice;
  final double? sellingPrice;
  final double? soldPrice;
  final DateTime? soldDate;
  final String? notes;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VehicleBrand? brand;

  const Vehicle({
    required this.id,
    required this.code,
    required this.brandId,
    required this.model,
    required this.year,
    this.color,
    this.engineCapacity,
    this.fuelType,
    this.transmissionType,
    this.licensePlate,
    this.chassisNumber,
    this.engineNumber,
    required this.odometer,
    required this.sourceType,
    this.sourceId,
    required this.purchasePrice,
    required this.conditionStatus,
    required this.status,
    this.repairCost,
    this.hppPrice,
    this.sellingPrice,
    this.soldPrice,
    this.soldDate,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.brand,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    print('Vehicle.fromJson: Received JSON: $json');

    final vehicle = Vehicle(
      id: (json['id'] as num? ?? 0).toInt(),
      code: json['code'] as String? ?? '',
      brandId: (json['brand_id'] as num? ?? 0).toInt(),
      model: json['model'] as String? ?? '',
      year: (json['year'] as num? ?? 0).toInt(),
      color: json['color'] as String?,
      engineCapacity: json['engine_capacity'] as String?,
      fuelType: json['fuel_type'] as String?,
      transmissionType: json['transmission_type'] as String?,
      licensePlate: json['license_plate'] as String?,
      chassisNumber: json['chassis_number'] as String?,
      engineNumber: json['engine_number'] as String?,
      odometer: (json['odometer'] as num?)?.toInt() ?? 0,
      sourceType: json['source_type'] as String? ?? '',
      sourceId: (json['source_id'] as num?)?.toInt(),
      purchasePrice: (json['purchase_price'] as num? ?? 0.0).toDouble(),
      conditionStatus: json['condition_status'] as String? ?? '',
      status: json['status'] as String? ?? '',
      repairCost: json['repair_cost'] != null
          ? (json['repair_cost'] as num?)?.toDouble()
          : null,
      hppPrice: json['hpp_price'] != null
          ? (json['hpp_price'] as num?)?.toDouble()
          : null,
      sellingPrice: json['selling_price'] != null
          ? (json['selling_price'] as num?)?.toDouble()
          : null,
      soldPrice: json['sold_price'] != null
          ? (json['sold_price'] as num?)?.toDouble()
          : null,
      soldDate: json['sold_date'] != null
          ? DateTime.parse(json['sold_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdBy: (json['created_by'] as num? ?? 0).toInt(),
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      brand: json['brand'] != null
          ? VehicleBrand.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
    );

    print(
        'Vehicle.fromJson: Parsed vehicle: color=${vehicle.color}, fuelType=${vehicle.fuelType}, transmissionType=${vehicle.transmissionType}');
    return vehicle;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'brand_id': brandId,
      'model': model,
      'year': year,
      'color': color,
      'engine_capacity': engineCapacity,
      'fuel_type': fuelType,
      'transmission_type': transmissionType,
      'license_plate': licensePlate,
      'chassis_number': chassisNumber,
      'engine_number': engineNumber,
      'odometer': odometer,
      'source_type': sourceType,
      'source_id': sourceId,
      'purchase_price': purchasePrice,
      'condition_status': conditionStatus,
      'status': status,
      'repair_cost': repairCost,
      'hpp_price': hppPrice,
      'selling_price': sellingPrice,
      'sold_price': soldPrice,
      'sold_date': soldDate?.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'brand': brand?.toJson(),
    };
  }

  // Getter methods
  String get brandName => brand?.name ?? 'Unknown Brand';
  String get displayName => '$brandName $model ($year)';
  String get statusDisplay => _getStatusDisplay(status);
  String get conditionDisplay => _getConditionDisplay(conditionStatus);

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'available':
        return 'Tersedia';
      case 'in_repair':
        return 'Dalam Perbaikan';
      case 'sold':
        return 'Terjual';
      case 'reserved':
        return 'Dipesan';
      default:
        return status;
    }
  }

  String _getConditionDisplay(String condition) {
    switch (condition) {
      case 'excellent':
        return 'Sangat Baik';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      case 'poor':
        return 'Kurang';
      default:
        return condition;
    }
  }

  Vehicle copyWith({
    int? id,
    String? code,
    int? brandId,
    String? model,
    int? year,
    String? color,
    String? engineCapacity,
    String? fuelType,
    String? transmissionType,
    String? licensePlate,
    String? chassisNumber,
    String? engineNumber,
    int? odometer,
    String? sourceType,
    int? sourceId,
    double? purchasePrice,
    String? conditionStatus,
    String? status,
    double? repairCost,
    double? hppPrice,
    double? sellingPrice,
    double? soldPrice,
    DateTime? soldDate,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    VehicleBrand? brand,
  }) {
    return Vehicle(
      id: id ?? this.id,
      code: code ?? this.code,
      brandId: brandId ?? this.brandId,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      fuelType: fuelType ?? this.fuelType,
      transmissionType: transmissionType ?? this.transmissionType,
      licensePlate: licensePlate ?? this.licensePlate,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      odometer: odometer ?? this.odometer,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      conditionStatus: conditionStatus ?? this.conditionStatus,
      status: status ?? this.status,
      repairCost: repairCost ?? this.repairCost,
      hppPrice: hppPrice ?? this.hppPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      soldPrice: soldPrice ?? this.soldPrice,
      soldDate: soldDate ?? this.soldDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      brand: brand ?? this.brand,
    );
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, code: $code, displayName: $displayName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CreateVehicleRequest {
  final String code;
  final int brandId;
  final String model;
  final int year;
  final String color;
  final String? engineCapacity;
  final String? fuelType;
  final String? transmissionType;
  final String? licensePlate;
  final int? odometer;
  final String sourceType;
  final int? sourceId;
  final double purchasePrice;
  final String conditionStatus;
  final String? description;

  const CreateVehicleRequest({
    required this.code,
    required this.brandId,
    required this.model,
    required this.year,
    required this.color,
    this.engineCapacity,
    this.fuelType,
    this.transmissionType,
    this.licensePlate,
    this.odometer,
    required this.sourceType,
    this.sourceId,
    required this.purchasePrice,
    required this.conditionStatus,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'brand_id': brandId,
      'model': model,
      'year': year,
      'color': color,
      'engine_capacity': engineCapacity,
      'fuel_type': fuelType,
      'transmission_type': transmissionType,
      'license_plate': licensePlate,
      'odometer': odometer,
      'source_type': sourceType,
      'source_id': sourceId,
      'purchase_price': purchasePrice,
      'condition_status': conditionStatus,
      'description': description,
    };
  }
}

class UpdateVehicleRequest {
  final String? code;
  final int? brandId;
  final String? model;
  final int? year;
  final String? color;
  final String? engineCapacity;
  final String? fuelType;
  final String? transmissionType;
  final String? licensePlate;
  final String? chassisNumber;
  final String? engineNumber;
  final int? odometer;
  final String? sourceType;
  final int? sourceId;
  final double? purchasePrice;
  final String? conditionStatus;
  final String? status;
  final double? repairCost;
  final double? hppPrice;
  final double? sellingPrice;
  final double? soldPrice;
  final DateTime? soldDate;
  final String? notes;

  const UpdateVehicleRequest({
    this.code,
    this.brandId,
    this.model,
    this.year,
    this.color,
    this.engineCapacity,
    this.fuelType,
    this.transmissionType,
    this.licensePlate,
    this.chassisNumber,
    this.engineNumber,
    this.odometer,
    this.sourceType,
    this.sourceId,
    this.purchasePrice,
    this.conditionStatus,
    this.status,
    this.repairCost,
    this.hppPrice,
    this.sellingPrice,
    this.soldPrice,
    this.soldDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (code != null) data['code'] = code;
    if (brandId != null) data['brand_id'] = brandId;
    if (model != null) data['model'] = model;
    if (year != null) data['year'] = year;
    if (color != null) data['color'] = color;
    if (engineCapacity != null) data['engine_capacity'] = engineCapacity;
    if (fuelType != null) data['fuel_type'] = fuelType;
    if (transmissionType != null) data['transmission_type'] = transmissionType;
    if (licensePlate != null) data['license_plate'] = licensePlate;
    if (chassisNumber != null) data['chassis_number'] = chassisNumber;
    if (engineNumber != null) data['engine_number'] = engineNumber;
    if (odometer != null) data['odometer'] = odometer;
    if (sourceType != null) data['source_type'] = sourceType;
    if (sourceId != null) data['source_id'] = sourceId;
    if (purchasePrice != null) data['purchase_price'] = purchasePrice;
    if (conditionStatus != null) data['condition_status'] = conditionStatus;
    if (status != null) data['status'] = status;
    if (repairCost != null) data['repair_cost'] = repairCost;
    if (hppPrice != null) data['hpp_price'] = hppPrice;
    if (sellingPrice != null) data['selling_price'] = sellingPrice;
    if (soldPrice != null) data['sold_price'] = soldPrice;
    if (soldDate != null) data['sold_date'] = soldDate!.toIso8601String();
    if (notes != null) data['notes'] = notes;

    return data;
  }
}

class SetSellingPriceRequest {
  final double sellingPrice;

  const SetSellingPriceRequest({
    required this.sellingPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'selling_price': sellingPrice,
    };
  }
}
