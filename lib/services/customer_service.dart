import 'package:mysql_client/mysql_client.dart';
import '../config/database_config.dart';
import '../models/customer.dart';

/// Service class for Customer CRUD operations
class CustomerService {
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

  /// Create a new customer
  Future<int> createCustomer(Customer customer) async {
    final conn = await connection;
    final result = await conn.execute(
      '''INSERT INTO customers (name, phone, email, address)
         VALUES (:name, :phone, :email, :address)''',
      {
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
      },
    );
    return result.lastInsertID.toInt();
  }

  /// Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM customers ORDER BY name',
    );
    return results.rows
        .map((row) => Customer.fromMap(row.assoc()))
        .toList();
  }

  /// Search customers by name or phone
  Future<List<Customer>> searchCustomers(String query) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM customers WHERE name LIKE :q OR phone LIKE :q ORDER BY name',
      {'q': '%$query%'},
    );
    return results.rows
        .map((row) => Customer.fromMap(row.assoc()))
        .toList();
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM customers WHERE id = :id',
      {'id': id},
    );
    if (results.rows.isEmpty) return null;
    return Customer.fromMap(results.rows.first.assoc());
  }

  /// Update customer
  Future<bool> updateCustomer(Customer customer) async {
    if (customer.id == null) return false;
    final conn = await connection;
    final result = await conn.execute(
      '''UPDATE customers SET name = :name, phone = :phone, email = :email, address = :address
         WHERE id = :id''',
      {
        'id': customer.id,
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
      },
    );
    return result.affectedRows.toInt() > 0;
  }

  /// Delete customer
  Future<bool> deleteCustomer(int id) async {
    final conn = await connection;
    final result = await conn.execute(
      'DELETE FROM customers WHERE id = :id',
      {'id': id},
    );
    return result.affectedRows.toInt() > 0;
  }

  /// Get customer with total purchase summary (for reports)
  Future<List<Map<String, dynamic>>> getCustomerSalesSummary() async {
    final conn = await connection;
    final results = await conn.execute('''
      SELECT c.id, c.name, c.phone, c.email,
             COUNT(s.id) as total_orders,
             COALESCE(SUM(s.net_amount), 0) as total_spent
      FROM customers c
      LEFT JOIN sales s ON s.customer_id = c.id
      GROUP BY c.id, c.name, c.phone, c.email
      ORDER BY total_spent DESC
    ''');
    return results.rows.map((row) {
      final map = row.assoc();
      return {
        'id': int.parse(map['id']!),
        'name': map['name']!,
        'phone': map['phone'] ?? '',
        'email': map['email'] ?? '',
        'total_orders': int.parse(map['total_orders'] ?? '0'),
        'total_spent': double.parse(map['total_spent'] ?? '0'),
      };
    }).toList();
  }

  /// Close connection
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
