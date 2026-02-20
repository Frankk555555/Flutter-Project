/// Category model class representing a product category
class Category {
  final int? id;
  final String name;
  final String? description;
  final DateTime? createdAt;

  Category({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  /// Create Category from database map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: int.parse(map['id'].toString()),
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  /// Convert Category to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
    };
  }

  /// Create a copy with updated fields
  Category copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
