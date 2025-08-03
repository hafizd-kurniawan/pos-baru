class Supplier {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? contactPerson;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.contactPerson,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      contactPerson: json['contact_person'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'contact_person': contactPerson,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CreateSupplierRequest {
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? contactPerson;

  const CreateSupplierRequest({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.contactPerson,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'contact_person': contactPerson,
    };
  }
}

class UpdateSupplierRequest {
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final String? contactPerson;
  final bool? isActive;

  const UpdateSupplierRequest({
    this.name,
    this.phone,
    this.email,
    this.address,
    this.contactPerson,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    if (address != null) data['address'] = address;
    if (contactPerson != null) data['contact_person'] = contactPerson;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}