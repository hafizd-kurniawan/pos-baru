class SparePart {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String category;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final int stockQuantity;
  final int minimumStock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SparePart({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.category,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.minimumStock,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SparePart.fromJson(Map<String, dynamic> json) {
    return SparePart(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'General',
      unit: json['unit'] ?? 'pcs',
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: json['stock_quantity'] ?? 0,
      minimumStock: json['minimum_stock'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'category': category,
      'unit': unit,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'minimum_stock': minimumStock,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isLowStock => stockQuantity <= minimumStock;

  String get stockStatus {
    if (!isActive) return 'Tidak Aktif';
    if (stockQuantity == 0) return 'Habis';
    if (isLowStock) return 'Stok Rendah';
    return 'Tersedia';
  }

  double get profit => sellingPrice - purchasePrice;
  double get profitMargin =>
      purchasePrice > 0 ? (profit / purchasePrice) * 100 : 0;

  SparePart copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    String? category,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    int? stockQuantity,
    int? minimumStock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SparePart(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SparePart(id: $id, code: $code, name: $name, stockQuantity: $stockQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SparePart && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Alias for category to match repair card usage
  String? get brand => category;
}

// Request Models
class CreateSparePartRequest {
  final String code;
  final String name;
  final String? description;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final int stockQuantity;
  final int minimumStock;

  const CreateSparePartRequest({
    required this.code,
    required this.name,
    this.description,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.minimumStock,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'unit': unit,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'minimum_stock': minimumStock,
    };
  }
}

class UpdateSparePartRequest {
  final String? name;
  final String? description;
  final String? unit;
  final double? purchasePrice;
  final double? sellingPrice;
  final int? stockQuantity;
  final int? minimumStock;
  final bool? isActive;

  const UpdateSparePartRequest({
    this.name,
    this.description,
    this.unit,
    this.purchasePrice,
    this.sellingPrice,
    this.stockQuantity,
    this.minimumStock,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (unit != null) data['unit'] = unit;
    if (purchasePrice != null) data['purchase_price'] = purchasePrice;
    if (sellingPrice != null) data['selling_price'] = sellingPrice;
    if (stockQuantity != null) data['stock_quantity'] = stockQuantity;
    if (minimumStock != null) data['minimum_stock'] = minimumStock;
    if (isActive != null) data['is_active'] = isActive;

    return data;
  }
}

class UpdateStockRequest {
  final int quantity;
  final String operation; // 'add' or 'subtract'
  final String? notes;

  const UpdateStockRequest({
    required this.quantity,
    required this.operation,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'operation': operation,
      'notes': notes,
    };
  }
}
