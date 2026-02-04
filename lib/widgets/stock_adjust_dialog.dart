import 'package:flutter/material.dart';
import '../models/product.dart';

/// Dialog for quick stock adjustment (เบิกออก/นำเข้า)
class StockAdjustDialog extends StatefulWidget {
  final Product product;
  final bool isWithdraw; // true = เบิกออก/ขาย, false = นำเข้า

  const StockAdjustDialog({
    super.key,
    required this.product,
    required this.isWithdraw,
  });

  /// Show dialog and return adjustment amount (null if cancelled)
  static Future<Map<String, dynamic>?> show(
    BuildContext context, 
    Product product, 
    {required bool isWithdraw}
  ) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StockAdjustDialog(product: product, isWithdraw: isWithdraw),
    );
  }

  @override
  State<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<StockAdjustDialog> {
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  int get maxQuantity => widget.isWithdraw ? widget.product.quantity : 9999;

  @override
  Widget build(BuildContext context) {
    final isWithdraw = widget.isWithdraw;
    final color = isWithdraw ? Colors.red : Colors.green;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isWithdraw ? Icons.remove_circle : Icons.add_circle,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(isWithdraw ? 'เบิกออก / ขาย' : 'นำเข้าสต๊อก'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'สต๊อกปัจจุบัน: ${widget.product.quantity} ชิ้น',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quantity selector
            const Text('จำนวน:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus button
                IconButton.filled(
                  onPressed: _quantity > 1 
                      ? () => setState(() => _quantity--) 
                      : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 16),

                // Quantity display
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Plus button
                IconButton.filled(
                  onPressed: _quantity < maxQuantity 
                      ? () => setState(() => _quantity++) 
                      : null,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick amount buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [5, 10, 20, 50].map((amount) {
                final isDisabled = amount > maxQuantity;
                return ActionChip(
                  label: Text('+$amount'),
                  onPressed: isDisabled ? null : () {
                    setState(() {
                      _quantity = (_quantity + amount).clamp(1, maxQuantity);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Result preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.product.quantity}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Icon(
                    isWithdraw ? Icons.arrow_forward : Icons.arrow_forward,
                    color: color,
                  ),
                  Text(
                    '${isWithdraw ? widget.product.quantity - _quantity : widget.product.quantity + _quantity}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(' ชิ้น', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Note field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'หมายเหตุ (ไม่บังคับ)',
                hintText: isWithdraw ? 'เช่น ขายให้ลูกค้า' : 'เช่น รับเข้าจากซัพพลาย',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (isWithdraw && _quantity > widget.product.quantity) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('จำนวนเกินสต๊อกที่มี'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'quantity': _quantity,
              'note': _noteController.text.trim(),
            });
          },
          icon: Icon(isWithdraw ? Icons.remove_circle : Icons.add_circle),
          label: Text(isWithdraw ? 'เบิกออก' : 'นำเข้า'),
          style: FilledButton.styleFrom(backgroundColor: color),
        ),
      ],
    );
  }
}
