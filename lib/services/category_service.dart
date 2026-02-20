import 'package:mysql_client/mysql_client.dart';
import '../config/database_config.dart';
import '../models/category.dart';

/// Service class for Category CRUD operations
class CategoryService {
  MySQLConnection? _connection;

  /// Get database connection
  Future<MySQLConnection> get connection async {
    if (_connection == null || !_connection!.connected) {
      _connection = await MySQLConnection.createConnection(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        userName: DatabaseConfig.user,
        password: DatabaseConfig.password,
        databaseName: DatabaseConfig.database,
        secure: false,
      );
      await _connection!.connect();
    }
    return _connection!;
  }

  /// Create a new category
  Future<int> createCategory(Category category) async {
    final conn = await connection;
    final result = await conn.execute(
      'INSERT INTO categories (name, description) VALUES (:name, :description)',
      {'name': category.name, 'description': category.description},
    );
    return result.lastInsertID.toInt();
  }

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM categories ORDER BY name',
    );
    return results.rows
        .map((row) => Category.fromMap(row.assoc()))
        .toList();
  }

  /// Get category by ID
  Future<Category?> getCategoryById(int id) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM categories WHERE id = :id',
      {'id': id},
    );
    if (results.rows.isEmpty) return null;
    return Category.fromMap(results.rows.first.assoc());
  }

  /// Update category
  Future<bool> updateCategory(Category category) async {
    if (category.id == null) return false;
    final conn = await connection;
    final result = await conn.execute(
      'UPDATE categories SET name = :name, description = :description WHERE id = :id',
      {'id': category.id, 'name': category.name, 'description': category.description},
    );
    return result.affectedRows.toInt() > 0;
  }

  /// Delete category
  Future<bool> deleteCategory(int id) async {
    final conn = await connection;
    final result = await conn.execute(
      'DELETE FROM categories WHERE id = :id',
      {'id': id},
    );
    return result.affectedRows.toInt() > 0;
  }

  /// Get product count per category (for reports)
  Future<List<Map<String, dynamic>>> getProductCountByCategory() async {
    final conn = await connection;
    final results = await conn.execute('''
      SELECT c.id, c.name, c.description,
             COUNT(p.id) as product_count,
             COALESCE(SUM(p.quantity), 0) as total_stock,
             COALESCE(SUM(p.price * p.quantity), 0) as total_value
      FROM categories c
      LEFT JOIN products p ON p.category = c.name
      GROUP BY c.id, c.name, c.description
      ORDER BY c.name
    ''');
    return results.rows.map((row) {
      final map = row.assoc();
      return {
        'id': int.parse(map['id']!),
        'name': map['name']!,
        'description': map['description'] ?? '',
        'product_count': int.parse(map['product_count'] ?? '0'),
        'total_stock': int.parse(map['total_stock'] ?? '0'),
        'total_value': double.parse(map['total_value'] ?? '0'),
      };
    }).toList();
  }

  /// Close connection
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
