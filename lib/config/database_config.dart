/// Database configuration for MySQL connection
class DatabaseConfig {
  // MySQL connection settings
  static const String host = 'localhost';
  static const int port = 3306;
  static const String user = 'stockapp';
  static const String password = '1234';
  static const String database = 'stock_management';

  // Connection string for display
  static String get connectionInfo => '$user@$host:$port/$database';
}
