import 'package:mysql_client/mysql_client.dart';
import '../config/database_config.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

/// Service class for CRUD operations on products
class ProductService {
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

  /// Initialize database - create tables if not exists
  Future<void> initDatabase() async {
    final conn = await connection;
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        category VARCHAR(50) NOT NULL,
        price DECIMAL(10,2) NOT NULL,
        quantity INT NOT NULL DEFAULT 0,
        min_quantity INT DEFAULT 10,
        image_url VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    ''');

    // Create stock_movements table for history tracking
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id INT PRIMARY KEY AUTO_INCREMENT,
        product_id INT NOT NULL,
        product_name VARCHAR(100) NOT NULL,
        movement_type ENUM('IN', 'OUT', 'ADJUST', 'NEW') NOT NULL,
        quantity INT NOT NULL,
        previous_quantity INT NOT NULL,
        new_quantity INT NOT NULL,
        note TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// Create - Add a new product
  Future<int> createProduct(Product product) async {
    final conn = await connection;
    final result = await conn.execute(
      '''
      INSERT INTO products (name, description, category, price, quantity, min_quantity, image_url)
      VALUES (:name, :description, :category, :price, :quantity, :min_quantity, :image_url)
      ''',
      {
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'price': product.price,
        'quantity': product.quantity,
        'min_quantity': product.minQuantity,
        'image_url': product.imageUrl,
      },
    );
    return result.lastInsertID.toInt();
  }

  /// Read - Get all products
  Future<List<Product>> getAllProducts() async {
    final conn = await connection;
    final results = await conn.execute('SELECT * FROM products ORDER BY id DESC');
    
    return results.rows.map((row) {
      final map = row.assoc();
      return Product(
        id: int.parse(map['id']!),
        name: map['name']!,
        description: map['description'],
        category: map['category']!,
        price: double.parse(map['price']!),
        quantity: int.parse(map['quantity']!),
        minQuantity: int.parse(map['min_quantity'] ?? '10'),
        imageUrl: map['image_url'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']!) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']!) : null,
      );
    }).toList();
  }

  /// Read - Get product by ID
  Future<Product?> getProductById(int id) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM products WHERE id = :id',
      {'id': id},
    );
    
    if (results.rows.isEmpty) return null;
    
    final map = results.rows.first.assoc();
    return Product(
      id: int.parse(map['id']!),
      name: map['name']!,
      description: map['description'],
      category: map['category']!,
      price: double.parse(map['price']!),
      quantity: int.parse(map['quantity']!),
      minQuantity: int.parse(map['min_quantity'] ?? '10'),
      imageUrl: map['image_url'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']!) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']!) : null,
    );
  }

  /// Read - Search products by name
  Future<List<Product>> searchProducts(String query) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM products WHERE name LIKE :query ORDER BY id DESC',
      {'query': '%$query%'},
    );
    
    return results.rows.map((row) {
      final map = row.assoc();
      return Product(
        id: int.parse(map['id']!),
        name: map['name']!,
        description: map['description'],
        category: map['category']!,
        price: double.parse(map['price']!),
        quantity: int.parse(map['quantity']!),
        minQuantity: int.parse(map['min_quantity'] ?? '10'),
        imageUrl: map['image_url'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']!) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']!) : null,
      );
    }).toList();
  }

  /// Read - Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM products WHERE category = :category ORDER BY id DESC',
      {'category': category},
    );
    
    return results.rows.map((row) {
      final map = row.assoc();
      return Product(
        id: int.parse(map['id']!),
        name: map['name']!,
        description: map['description'],
        category: map['category']!,
        price: double.parse(map['price']!),
        quantity: int.parse(map['quantity']!),
        minQuantity: int.parse(map['min_quantity'] ?? '10'),
        imageUrl: map['image_url'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']!) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']!) : null,
      );
    }).toList();
  }

  /// Read - Get all unique categories
  Future<List<String>> getAllCategories() async {
    final conn = await connection;
    final results = await conn.execute('SELECT DISTINCT category FROM products ORDER BY category');
    
    return results.rows.map((row) => row.assoc()['category']!).toList();
  }

  /// Read - Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM products WHERE quantity < min_quantity ORDER BY quantity ASC',
    );
    
    return results.rows.map((row) {
      final map = row.assoc();
      return Product(
        id: int.parse(map['id']!),
        name: map['name']!,
        description: map['description'],
        category: map['category']!,
        price: double.parse(map['price']!),
        quantity: int.parse(map['quantity']!),
        minQuantity: int.parse(map['min_quantity'] ?? '10'),
        imageUrl: map['image_url'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']!) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']!) : null,
      );
    }).toList();
  }

  /// Update - Update product
  Future<bool> updateProduct(Product product) async {
    if (product.id == null) return false;
    
    final conn = await connection;
    final result = await conn.execute(
      '''
      UPDATE products SET
        name = :name,
        description = :description,
        category = :category,
        price = :price,
        quantity = :quantity,
        min_quantity = :min_quantity,
        image_url = :image_url
      WHERE id = :id
      ''',
      {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'price': product.price,
        'quantity': product.quantity,
        'min_quantity': product.minQuantity,
        'image_url': product.imageUrl,
      },
    );
    return result.affectedRows.toInt() > 0;
  }

  /// Delete - Delete product by ID
  Future<bool> deleteProduct(int id) async {
    final conn = await connection;
    final result = await conn.execute(
      'DELETE FROM products WHERE id = :id',
      {'id': id},
    );
    return result.affectedRows.toInt() > 0;
  }

  /// Get summary statistics
  Future<Map<String, dynamic>> getStockSummary() async {
    final conn = await connection;
    
    final totalResult = await conn.execute(
      'SELECT COUNT(*) as count, SUM(price * quantity) as total_value FROM products',
    );
    final lowStockResult = await conn.execute(
      'SELECT COUNT(*) as count FROM products WHERE quantity < min_quantity',
    );
    
    final totalMap = totalResult.rows.first.assoc();
    final lowStockMap = lowStockResult.rows.first.assoc();
    
    return {
      'totalProducts': int.parse(totalMap['count'] ?? '0'),
      'totalValue': double.parse(totalMap['total_value'] ?? '0'),
      'lowStockCount': int.parse(lowStockMap['count'] ?? '0'),
    };
  }

  // ==================== Stock Movement Methods ====================

  /// Record a stock movement
  Future<void> recordMovement({
    required int productId,
    required String productName,
    required String movementType,
    required int quantity,
    required int previousQuantity,
    required int newQuantity,
    String? note,
  }) async {
    final conn = await connection;
    await conn.execute(
      '''
      INSERT INTO stock_movements (product_id, product_name, movement_type, quantity, previous_quantity, new_quantity, note)
      VALUES (:product_id, :product_name, :movement_type, :quantity, :previous_quantity, :new_quantity, :note)
      ''',
      {
        'product_id': productId,
        'product_name': productName,
        'movement_type': movementType,
        'quantity': quantity,
        'previous_quantity': previousQuantity,
        'new_quantity': newQuantity,
        'note': note,
      },
    );
  }

  /// Get all stock movements (most recent first)
  Future<List<StockMovement>> getAllMovements({int limit = 100}) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM stock_movements ORDER BY created_at DESC LIMIT :limit',
      {'limit': limit},
    );

    return results.rows.map((row) => StockMovement.fromMap(row.assoc())).toList();
  }

  /// Get stock movements for a specific product
  Future<List<StockMovement>> getProductMovements(int productId) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM stock_movements WHERE product_id = :product_id ORDER BY created_at DESC',
      {'product_id': productId},
    );

    return results.rows.map((row) => StockMovement.fromMap(row.assoc())).toList();
  }

  /// Get today's movements
  Future<List<StockMovement>> getTodayMovements() async {
    final conn = await connection;
    final results = await conn.execute(
      "SELECT * FROM stock_movements WHERE DATE(created_at) = CURDATE() ORDER BY created_at DESC",
    );

    return results.rows.map((row) => StockMovement.fromMap(row.assoc())).toList();
  }

  /// Close database connection
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
