/// Sale header model
class Sale {
  final int? id;
  final int? customerId;
  final String? customerName;
  final DateTime saleDate;
  final double totalAmount;
  final double discount;
  final double netAmount;
  final String paymentMethod; // cash, transfer, credit
  final String? note;
  final DateTime? createdAt;
  final List<SaleItem> items;

  Sale({
    this.id,
    this.customerId,
    this.customerName,
    required this.saleDate,
    this.totalAmount = 0,
    this.discount = 0,
    this.netAmount = 0,
    this.paymentMethod = 'cash',
    this.note,
    this.createdAt,
    this.items = const [],
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: int.parse(map['id'].toString()),
      customerId: map['customer_id'] != null
          ? int.parse(map['customer_id'].toString())
          : null,
      customerName: map['customer_name'] as String?,
      saleDate: DateTime.parse(map['sale_date'].toString()),
      totalAmount: double.parse(map['total_amount']?.toString() ?? '0'),
      discount: double.parse(map['discount']?.toString() ?? '0'),
      netAmount: double.parse(map['net_amount']?.toString() ?? '0'),
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'sale_date': saleDate.toIso8601String().split('T')[0],
      'total_amount': totalAmount,
      'discount': discount,
      'net_amount': netAmount,
      'payment_method': paymentMethod,
      'note': note,
    };
  }

  /// Payment method display text in Thai
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'cash':
        return 'เงินสด';
      case 'transfer':
        return 'โอนเงิน';
      case 'credit':
        return 'เครดิต';
      default:
        return paymentMethod;
    }
  }

  @override
  String toString() =>
      'Sale(id: $id, customer: $customerName, net: $netAmount, payment: $paymentMethod)';
}

/// Sale item (detail line)
class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double totalPrice;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.totalPrice = 0,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: int.parse(map['id'].toString()),
      saleId: int.parse(map['sale_id'].toString()),
      productId: int.parse(map['product_id'].toString()),
      productName: map['product_name'] as String?,
      quantity: int.parse(map['quantity'].toString()),
      unitPrice: double.parse(map['unit_price'].toString()),
      discount: double.parse(map['discount']?.toString() ?? '0'),
      totalPrice: double.parse(map['total_price']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total_price': (quantity * unitPrice) - discount,
    };
  }
}
