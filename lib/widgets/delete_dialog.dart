import 'package:flutter/material.dart';

/// Dialog widget for confirming product deletion
class DeleteDialog extends StatelessWidget {
  final String productName;
  final VoidCallback onConfirm;

  const DeleteDialog({
    super.key,
    required this.productName,
    required this.onConfirm,
  });

  /// Show delete confirmation dialog
  static Future<bool?> show(BuildContext context, String productName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteDialog(
        productName: productName,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Text('ยืนยันการลบ'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'คุณต้องการลบสินค้า',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            '"$productName"',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'หรือไม่?',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton.icon(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete, size: 18),
          label: const Text('ลบ'),
        ),
      ],
    );
  }
}
