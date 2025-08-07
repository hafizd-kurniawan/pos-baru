class SparePartCategory {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SparePartCategory({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SparePartCategory.fromJson(Map<String, dynamic> json) {
    return SparePartCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at'].replaceAll(' ', 'T')),
      updatedAt: DateTime.parse(json['updated_at'].replaceAll(' ', 'T')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SparePartCategory copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SparePartCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CreateSparePartCategoryRequest {
  final String name;
  final String? description;
  final bool isActive;

  const CreateSparePartCategoryRequest({
    required this.name,
    this.description,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}

class UpdateSparePartCategoryRequest {
  final String name;
  final String? description;
  final bool isActive;

  const UpdateSparePartCategoryRequest({
    required this.name,
    this.description,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}
