/// Purchase Order header model
class PurchaseOrder {
  final int? id;
  final String supplierName;
  final DateTime orderDate;
  final double totalAmount;
  final String status; // pending, received, cancelled
  final String? note;
  final DateTime? createdAt;
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    this.id,
    required this.supplierName,
    required this.orderDate,
    this.totalAmount = 0,
    this.status = 'pending',
    this.note,
    this.createdAt,
    this.items = const [],
  });

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: int.parse(map['id'].toString()),
      supplierName: map['supplier_name'] as String,
      orderDate: DateTime.parse(map['order_date'].toString()),
      totalAmount: double.parse(map['total_amount']?.toString() ?? '0'),
      status: map['status'] as String? ?? 'pending',
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplier_name': supplierName,
      'order_date': orderDate.toIso8601String().split('T')[0],
      'total_amount': totalAmount,
      'status': status,
      'note': note,
    };
  }

  /// Status display text in Thai
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'received':
        return 'รับสินค้าแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  @override
  String toString() =>
      'PurchaseOrder(id: $id, supplier: $supplierName, total: $totalAmount, status: $status)';
}

/// Purchase Order item (detail line)
class PurchaseOrderItem {
  final int? id;
  final int? purchaseOrderId;
  final int productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  PurchaseOrderItem({
    this.id,
    this.purchaseOrderId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    this.totalPrice = 0,
  });

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: int.parse(map['id'].toString()),
      purchaseOrderId: int.parse(map['purchase_order_id'].toString()),
      productId: int.parse(map['product_id'].toString()),
      productName: map['product_name'] as String?,
      quantity: int.parse(map['quantity'].toString()),
      unitPrice: double.parse(map['unit_price'].toString()),
      totalPrice: double.parse(map['total_price']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': quantity * unitPrice,
    };
  }
}
