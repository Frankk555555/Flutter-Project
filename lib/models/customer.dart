/// Customer model class
class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Customer from database map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: int.parse(map['id'].toString()),
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  /// Create a copy with updated fields
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, phone: $phone)';
}
