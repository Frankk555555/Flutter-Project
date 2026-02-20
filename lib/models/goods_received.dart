/// Goods Received header model
class GoodsReceived {
  final int? id;
  final int? purchaseOrderId;
  final DateTime receivedDate;
  final String? receivedBy;
  final String? note;
  final DateTime? createdAt;
  final List<GoodsReceivedItem> items;

  GoodsReceived({
    this.id,
    this.purchaseOrderId,
    required this.receivedDate,
    this.receivedBy,
    this.note,
    this.createdAt,
    this.items = const [],
  });

  factory GoodsReceived.fromMap(Map<String, dynamic> map) {
    return GoodsReceived(
      id: int.parse(map['id'].toString()),
      purchaseOrderId: map['purchase_order_id'] != null
          ? int.parse(map['purchase_order_id'].toString())
          : null,
      receivedDate: DateTime.parse(map['received_date'].toString()),
      receivedBy: map['received_by'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'purchase_order_id': purchaseOrderId,
      'received_date': receivedDate.toIso8601String().split('T')[0],
      'received_by': receivedBy,
      'note': note,
    };
  }

  @override
  String toString() =>
      'GoodsReceived(id: $id, date: $receivedDate, poId: $purchaseOrderId)';
}

/// Goods Received item (detail line)
class GoodsReceivedItem {
  final int? id;
  final int? goodsReceivedId;
  final int productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  GoodsReceivedItem({
    this.id,
    this.goodsReceivedId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    this.totalPrice = 0,
  });

  factory GoodsReceivedItem.fromMap(Map<String, dynamic> map) {
    return GoodsReceivedItem(
      id: int.parse(map['id'].toString()),
      goodsReceivedId: int.parse(map['goods_received_id'].toString()),
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
