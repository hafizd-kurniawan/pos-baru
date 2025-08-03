class SparePart {
  final int id;
  final String code;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? minStock;
  final String? supplier;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SparePart({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.minStock,
    this.supplier,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SparePart.fromJson(Map<String, dynamic> json) {
    return SparePart(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      minStock: json['min_stock'],
      supplier: json['supplier'],
      category: json['category'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'min_stock': minStock,
      'supplier': supplier,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isLowStock => minStock != null && stock <= minStock!;

  String get stockStatus {
    if (!isActive) return 'Tidak Aktif';
    if (stock == 0) return 'Habis';
    if (isLowStock) return 'Stok Rendah';
    return 'Tersedia';
  }

  SparePart copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    double? price,
    int? stock,
    int? minStock,
    String? supplier,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SparePart(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      supplier: supplier ?? this.supplier,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SparePart(id: $id, code: $code, name: $name, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SparePart && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CreateSparePartRequest {
  final String code;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? minStock;
  final String? supplier;
  final String category;

  const CreateSparePartRequest({
    required this.code,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.minStock,
    this.supplier,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'min_stock': minStock,
      'supplier': supplier,
      'category': category,
    };
  }
}

class UpdateSparePartRequest {
  final String? name;
  final String? description;
  final double? price;
  final int? minStock;
  final String? supplier;
  final String? category;
  final bool? isActive;

  const UpdateSparePartRequest({
    this.name,
    this.description,
    this.price,
    this.minStock,
    this.supplier,
    this.category,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (minStock != null) data['min_stock'] = minStock;
    if (supplier != null) data['supplier'] = supplier;
    if (category != null) data['category'] = category;
    if (isActive != null) data['is_active'] = isActive;
    
    return data;
  }
}

class UpdateStockRequest {
  final int quantity;
  final String type; // 'add' or 'subtract'
  final String? notes;

  const UpdateStockRequest({
    required this.quantity,
    required this.type,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'type': type,
      'notes': notes,
    };
  }
}