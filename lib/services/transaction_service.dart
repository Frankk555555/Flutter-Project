import 'package:mysql_client/mysql_client.dart';
import '../config/database_config.dart';
import '../models/purchase_order.dart';
import '../models/goods_received.dart';
import '../models/sale.dart';

/// Service class for transaction operations (Purchase Orders, Goods Received, Sales)
class TransactionService {
  MySQLConnection? _connection;

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

  // ==================== Purchase Orders ====================

  /// Create a purchase order with items
  Future<int> createPurchaseOrder(PurchaseOrder po, List<PurchaseOrderItem> items) async {
    final conn = await connection;

    // Calculate total
    double total = 0;
    for (var item in items) {
      total += item.quantity * item.unitPrice;
    }

    // Insert header
    final result = await conn.execute(
      '''INSERT INTO purchase_orders (supplier_name, order_date, total_amount, status, note)
         VALUES (:supplier_name, :order_date, :total_amount, :status, :note)''',
      {
        'supplier_name': po.supplierName,
        'order_date': po.orderDate.toIso8601String().split('T')[0],
        'total_amount': total,
        'status': 'pending',
        'note': po.note,
      },
    );
    final poId = result.lastInsertID.toInt();

    // Insert items
    for (var item in items) {
      await conn.execute(
        '''INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price, total_price)
           VALUES (:po_id, :product_id, :quantity, :unit_price, :total_price)''',
        {
          'po_id': poId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.quantity * item.unitPrice,
        },
      );
    }
    return poId;
  }

  /// Get all purchase orders
  Future<List<PurchaseOrder>> getAllPurchaseOrders() async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM purchase_orders ORDER BY created_at DESC',
    );
    return results.rows.map((row) => PurchaseOrder.fromMap(row.assoc())).toList();
  }

  /// Get purchase order with items
  Future<PurchaseOrder?> getPurchaseOrderById(int id) async {
    final conn = await connection;
    final headerResult = await conn.execute(
      'SELECT * FROM purchase_orders WHERE id = :id',
      {'id': id},
    );
    if (headerResult.rows.isEmpty) return null;

    final po = PurchaseOrder.fromMap(headerResult.rows.first.assoc());

    final itemsResult = await conn.execute(
      '''SELECT poi.*, p.name as product_name
         FROM purchase_order_items poi
         LEFT JOIN products p ON p.id = poi.product_id
         WHERE poi.purchase_order_id = :po_id''',
      {'po_id': id},
    );

    final items = itemsResult.rows.map((row) => PurchaseOrderItem.fromMap(row.assoc())).toList();

    return PurchaseOrder(
      id: po.id,
      supplierName: po.supplierName,
      orderDate: po.orderDate,
      totalAmount: po.totalAmount,
      status: po.status,
      note: po.note,
      createdAt: po.createdAt,
      items: items,
    );
  }

  /// Update purchase order status
  Future<bool> updatePurchaseOrderStatus(int id, String status) async {
    final conn = await connection;
    final result = await conn.execute(
      'UPDATE purchase_orders SET status = :status WHERE id = :id',
      {'id': id, 'status': status},
    );
    return result.affectedRows.toInt() > 0;
  }

  // ==================== Goods Received ====================

  /// Create goods received with items and auto-update product stock
  Future<int> createGoodsReceived(GoodsReceived gr, List<GoodsReceivedItem> items) async {
    final conn = await connection;

    // Insert header
    final result = await conn.execute(
      '''INSERT INTO goods_received (purchase_order_id, received_date, received_by, note)
         VALUES (:po_id, :received_date, :received_by, :note)''',
      {
        'po_id': gr.purchaseOrderId,
        'received_date': gr.receivedDate.toIso8601String().split('T')[0],
        'received_by': gr.receivedBy,
        'note': gr.note,
      },
    );
    final grId = result.lastInsertID.toInt();

    // Insert items and update stock
    for (var item in items) {
      await conn.execute(
        '''INSERT INTO goods_received_items (goods_received_id, product_id, quantity, unit_price, total_price)
           VALUES (:gr_id, :product_id, :quantity, :unit_price, :total_price)''',
        {
          'gr_id': grId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.quantity * item.unitPrice,
        },
      );

      // Auto-update product stock (increase)
      await conn.execute(
        'UPDATE products SET quantity = quantity + :qty WHERE id = :id',
        {'qty': item.quantity, 'id': item.productId},
      );

      // Record stock movement
      // Get current quantity for the movement record
      final prodResult = await conn.execute(
        'SELECT name, quantity FROM products WHERE id = :id',
        {'id': item.productId},
      );
      if (prodResult.rows.isNotEmpty) {
        final prodMap = prodResult.rows.first.assoc();
        final newQty = int.parse(prodMap['quantity'] ?? '0');
        await conn.execute(
          '''INSERT INTO stock_movements (product_id, product_name, movement_type, quantity, previous_quantity, new_quantity, note)
             VALUES (:pid, :pname, 'IN', :qty, :prev, :new_qty, :note)''',
          {
            'pid': item.productId,
            'pname': prodMap['name'] ?? '',
            'qty': item.quantity,
            'prev': newQty - item.quantity,
            'new_qty': newQty,
            'note': 'รับสินค้า #$grId',
          },
        );
      }
    }

    // Update PO status if linked
    if (gr.purchaseOrderId != null) {
      await updatePurchaseOrderStatus(gr.purchaseOrderId!, 'received');
    }

    return grId;
  }

  /// Get all goods received
  Future<List<GoodsReceived>> getAllGoodsReceived() async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM goods_received ORDER BY created_at DESC',
    );
    return results.rows.map((row) => GoodsReceived.fromMap(row.assoc())).toList();
  }

  /// Get goods received with items
  Future<GoodsReceived?> getGoodsReceivedById(int id) async {
    final conn = await connection;
    final headerResult = await conn.execute(
      'SELECT * FROM goods_received WHERE id = :id',
      {'id': id},
    );
    if (headerResult.rows.isEmpty) return null;

    final gr = GoodsReceived.fromMap(headerResult.rows.first.assoc());

    final itemsResult = await conn.execute(
      '''SELECT gri.*, p.name as product_name
         FROM goods_received_items gri
         LEFT JOIN products p ON p.id = gri.product_id
         WHERE gri.goods_received_id = :gr_id''',
      {'gr_id': id},
    );

    final items = itemsResult.rows.map((row) => GoodsReceivedItem.fromMap(row.assoc())).toList();

    return GoodsReceived(
      id: gr.id,
      purchaseOrderId: gr.purchaseOrderId,
      receivedDate: gr.receivedDate,
      receivedBy: gr.receivedBy,
      note: gr.note,
      createdAt: gr.createdAt,
      items: items,
    );
  }

  // ==================== Sales ====================

  /// Create a sale with items and auto-deduct product stock
  Future<int> createSale(Sale sale, List<SaleItem> items) async {
    final conn = await connection;

    // Calculate totals
    double totalAmount = 0;
    for (var item in items) {
      totalAmount += (item.quantity * item.unitPrice) - item.discount;
    }
    final netAmount = totalAmount - sale.discount;

    // Insert header
    final result = await conn.execute(
      '''INSERT INTO sales (customer_id, sale_date, total_amount, discount, net_amount, payment_method, note)
         VALUES (:customer_id, :sale_date, :total_amount, :discount, :net_amount, :payment_method, :note)''',
      {
        'customer_id': sale.customerId,
        'sale_date': sale.saleDate.toIso8601String().split('T')[0],
        'total_amount': totalAmount,
        'discount': sale.discount,
        'net_amount': netAmount,
        'payment_method': sale.paymentMethod,
        'note': sale.note,
      },
    );
    final saleId = result.lastInsertID.toInt();

    // Insert items and deduct stock
    for (var item in items) {
      await conn.execute(
        '''INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, discount, total_price)
           VALUES (:sale_id, :product_id, :quantity, :unit_price, :discount, :total_price)''',
        {
          'sale_id': saleId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': item.discount,
          'total_price': (item.quantity * item.unitPrice) - item.discount,
        },
      );

      // Auto-deduct product stock
      await conn.execute(
        'UPDATE products SET quantity = quantity - :qty WHERE id = :id',
        {'qty': item.quantity, 'id': item.productId},
      );

      // Record stock movement
      final prodResult = await conn.execute(
        'SELECT name, quantity FROM products WHERE id = :id',
        {'id': item.productId},
      );
      if (prodResult.rows.isNotEmpty) {
        final prodMap = prodResult.rows.first.assoc();
        final newQty = int.parse(prodMap['quantity'] ?? '0');
        await conn.execute(
          '''INSERT INTO stock_movements (product_id, product_name, movement_type, quantity, previous_quantity, new_quantity, note)
             VALUES (:pid, :pname, 'OUT', :qty, :prev, :new_qty, :note)''',
          {
            'pid': item.productId,
            'pname': prodMap['name'] ?? '',
            'qty': item.quantity,
            'prev': newQty + item.quantity,
            'new_qty': newQty,
            'note': 'ขายสินค้า #$saleId',
          },
        );
      }
    }

    return saleId;
  }

  /// Get all sales
  Future<List<Sale>> getAllSales() async {
    final conn = await connection;
    final results = await conn.execute(
      '''SELECT s.*, c.name as customer_name
         FROM sales s LEFT JOIN customers c ON c.id = s.customer_id
         ORDER BY s.created_at DESC''',
    );
    return results.rows.map((row) => Sale.fromMap(row.assoc())).toList();
  }

  /// Get sale with items
  Future<Sale?> getSaleById(int id) async {
    final conn = await connection;
    final headerResult = await conn.execute(
      '''SELECT s.*, c.name as customer_name
         FROM sales s LEFT JOIN customers c ON c.id = s.customer_id
         WHERE s.id = :id''',
      {'id': id},
    );
    if (headerResult.rows.isEmpty) return null;

    final sale = Sale.fromMap(headerResult.rows.first.assoc());

    final itemsResult = await conn.execute(
      '''SELECT si.*, p.name as product_name
         FROM sale_items si
         LEFT JOIN products p ON p.id = si.product_id
         WHERE si.sale_id = :sale_id''',
      {'sale_id': id},
    );

    final items = itemsResult.rows.map((row) => SaleItem.fromMap(row.assoc())).toList();

    return Sale(
      id: sale.id,
      customerId: sale.customerId,
      customerName: sale.customerName,
      saleDate: sale.saleDate,
      totalAmount: sale.totalAmount,
      discount: sale.discount,
      netAmount: sale.netAmount,
      paymentMethod: sale.paymentMethod,
      note: sale.note,
      createdAt: sale.createdAt,
      items: items,
    );
  }

  // ==================== Reports ====================

  /// Get sales summary by date range
  Future<Map<String, dynamic>> getSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conn = await connection;
    String whereClause = '';
    Map<String, dynamic> params = {};

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE sale_date BETWEEN :start AND :end';
      params = {
        'start': startDate.toIso8601String().split('T')[0],
        'end': endDate.toIso8601String().split('T')[0],
      };
    }

    final result = await conn.execute(
      'SELECT COUNT(*) as total_sales, COALESCE(SUM(net_amount), 0) as total_revenue FROM sales $whereClause',
      params,
    );

    final map = result.rows.first.assoc();
    return {
      'total_sales': int.parse(map['total_sales'] ?? '0'),
      'total_revenue': double.parse(map['total_revenue'] ?? '0'),
    };
  }

  /// Get purchase summary by date range
  Future<Map<String, dynamic>> getPurchaseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conn = await connection;
    String whereClause = '';
    Map<String, dynamic> params = {};

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE order_date BETWEEN :start AND :end';
      params = {
        'start': startDate.toIso8601String().split('T')[0],
        'end': endDate.toIso8601String().split('T')[0],
      };
    }

    final result = await conn.execute(
      'SELECT COUNT(*) as total_orders, COALESCE(SUM(total_amount), 0) as total_cost FROM purchase_orders $whereClause',
      params,
    );

    final map = result.rows.first.assoc();
    return {
      'total_orders': int.parse(map['total_orders'] ?? '0'),
      'total_cost': double.parse(map['total_cost'] ?? '0'),
    };
  }

  /// Get top selling products
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 10}) async {
    final conn = await connection;
    final results = await conn.execute(
      '''SELECT p.name, SUM(si.quantity) as total_sold, SUM(si.total_price) as total_revenue
         FROM sale_items si
         JOIN products p ON p.id = si.product_id
         GROUP BY p.id, p.name
         ORDER BY total_sold DESC
         LIMIT :limit''',
      {'limit': limit},
    );
    return results.rows.map((row) {
      final map = row.assoc();
      return {
        'name': map['name']!,
        'total_sold': int.parse(map['total_sold'] ?? '0'),
        'total_revenue': double.parse(map['total_revenue'] ?? '0'),
      };
    }).toList();
  }

  /// Get goods received summary
  Future<Map<String, dynamic>> getGoodsReceivedSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conn = await connection;
    String whereClause = '';
    Map<String, dynamic> params = {};

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE received_date BETWEEN :start AND :end';
      params = {
        'start': startDate.toIso8601String().split('T')[0],
        'end': endDate.toIso8601String().split('T')[0],
      };
    }

    final result = await conn.execute(
      'SELECT COUNT(*) as total_received FROM goods_received $whereClause',
      params,
    );

    final itemsResult = await conn.execute(
      '''SELECT COALESCE(SUM(gri.total_price), 0) as total_value
         FROM goods_received_items gri
         JOIN goods_received gr ON gr.id = gri.goods_received_id
         ${whereClause.replaceAll('WHERE', 'WHERE')}''',
      params,
    );

    final map = result.rows.first.assoc();
    final itemsMap = itemsResult.rows.first.assoc();
    return {
      'total_received': int.parse(map['total_received'] ?? '0'),
      'total_value': double.parse(itemsMap['total_value'] ?? '0'),
    };
  }

  /// Close connection
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
