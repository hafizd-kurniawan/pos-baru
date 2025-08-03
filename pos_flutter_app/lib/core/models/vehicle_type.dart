class VehicleType {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  const VehicleType({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VehicleType copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return VehicleType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'VehicleType(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CreateVehicleTypeRequest {
  final String name;
  final String? description;

  const CreateVehicleTypeRequest({
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class UpdateVehicleTypeRequest {
  final String? name;
  final String? description;

  const UpdateVehicleTypeRequest({
    this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    
    return data;
  }
}
