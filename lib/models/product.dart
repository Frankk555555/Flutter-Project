/// Product model class representing a product in the stock
class Product {
  final int? id;
  final String name;
  final String? description;
  final String category;
  final double price;
  final int quantity;
  final int minQuantity;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.quantity,
    this.minQuantity = 10,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if product is low in stock
  bool get isLowStock => quantity < minQuantity;

  /// Create Product from database map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      minQuantity: map['min_quantity'] as int? ?? 10,
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  /// Convert Product to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'image_url': imageUrl,
    };
  }

  /// Create a copy of Product with updated fields
  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    int? minQuantity,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, price: $price, quantity: $quantity)';
  }
}
