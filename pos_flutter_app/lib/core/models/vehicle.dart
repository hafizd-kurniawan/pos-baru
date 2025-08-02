class Vehicle {
  final int id;
  final String code;
  final int brandId;
  final String brandName;
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
  final String? sourceName;
  final double purchasePrice;
  final double? sellingPrice;
  final double hpp;
  final String conditionStatus;
  final String status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.code,
    required this.brandId,
    required this.brandName,
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
    this.sourceName,
    required this.purchasePrice,
    this.sellingPrice,
    required this.hpp,
    required this.conditionStatus,
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      code: json['code'],
      brandId: json['brand_id'],
      brandName: json['brand_name'],
      model: json['model'],
      year: json['year'],
      color: json['color'],
      engineCapacity: json['engine_capacity'],
      fuelType: json['fuel_type'],
      transmissionType: json['transmission_type'],
      licensePlate: json['license_plate'],
      odometer: json['odometer'],
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      sourceName: json['source_name'],
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      sellingPrice: json['selling_price'] != null ? (json['selling_price'] as num).toDouble() : null,
      hpp: (json['hpp'] as num).toDouble(),
      conditionStatus: json['condition_status'],
      status: json['status'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'brand_id': brandId,
      'brand_name': brandName,
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
      'source_name': sourceName,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'hpp': hpp,
      'condition_status': conditionStatus,
      'status': status,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

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
    String? brandName,
    String? model,
    int? year,
    String? color,
    String? engineCapacity,
    String? fuelType,
    String? transmissionType,
    String? licensePlate,
    int? odometer,
    String? sourceType,
    int? sourceId,
    String? sourceName,
    double? purchasePrice,
    double? sellingPrice,
    double? hpp,
    String? conditionStatus,
    String? status,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      code: code ?? this.code,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      fuelType: fuelType ?? this.fuelType,
      transmissionType: transmissionType ?? this.transmissionType,
      licensePlate: licensePlate ?? this.licensePlate,
      odometer: odometer ?? this.odometer,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      hpp: hpp ?? this.hpp,
      conditionStatus: conditionStatus ?? this.conditionStatus,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
  final String? model;
  final int? year;
  final String? color;
  final String? engineCapacity;
  final String? fuelType;
  final String? transmissionType;
  final String? licensePlate;
  final int? odometer;
  final String? conditionStatus;
  final String? description;

  const UpdateVehicleRequest({
    this.model,
    this.year,
    this.color,
    this.engineCapacity,
    this.fuelType,
    this.transmissionType,
    this.licensePlate,
    this.odometer,
    this.conditionStatus,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (model != null) data['model'] = model;
    if (year != null) data['year'] = year;
    if (color != null) data['color'] = color;
    if (engineCapacity != null) data['engine_capacity'] = engineCapacity;
    if (fuelType != null) data['fuel_type'] = fuelType;
    if (transmissionType != null) data['transmission_type'] = transmissionType;
    if (licensePlate != null) data['license_plate'] = licensePlate;
    if (odometer != null) data['odometer'] = odometer;
    if (conditionStatus != null) data['condition_status'] = conditionStatus;
    if (description != null) data['description'] = description;
    
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