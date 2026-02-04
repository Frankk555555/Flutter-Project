/// Model class for stock movement history
class StockMovement {
  final int? id;
  final int productId;
  final String productName;
  final String movementType; // 'IN' หรือ 'OUT'
  final int quantity;
  final int previousQuantity;
  final int newQuantity;
  final String? note;
  final DateTime? createdAt;

  StockMovement({
    this.id,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    this.note,
    this.createdAt,
  });

  /// Create from database map
  static StockMovement fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: int.parse(map['id'].toString()),
      productId: int.parse(map['product_id'].toString()),
      productName: map['product_name'] as String,
      movementType: map['movement_type'] as String,
      quantity: int.parse(map['quantity'].toString()),
      previousQuantity: int.parse(map['previous_quantity'].toString()),
      newQuantity: int.parse(map['new_quantity'].toString()),
      note: map['note'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'movement_type': movementType,
      'quantity': quantity,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'note': note,
    };
  }

  /// Get movement type display text
  String get movementTypeDisplay {
    switch (movementType) {
      case 'IN':
        return 'นำเข้า';
      case 'OUT':
        return 'นำออก';
      case 'ADJUST':
        return 'ปรับปรุง';
      case 'NEW':
        return 'สินค้าใหม่';
      default:
        return movementType;
    }
  }

  /// Check if this is an incoming movement
  bool get isIncoming => movementType == 'IN' || movementType == 'NEW';
}
