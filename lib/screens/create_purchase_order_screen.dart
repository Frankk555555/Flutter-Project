import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../services/product_service.dart';
import '../services/transaction_service.dart';

/// Screen for creating a new purchase order
class CreatePurchaseOrderScreen extends StatefulWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  State<CreatePurchaseOrderScreen> createState() => _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends State<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _orderDate = DateTime.now();

  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();

  List<Product> _products = [];
  List<_OrderLine> _orderLines = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _products = await _productService.getAllProducts();
    } catch (e) {
      // ignore
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    double total = 0;
    for (var line in _orderLines) {
      total += line.quantity * line.unitPrice;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างใบสั่งซื้อ'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Supplier Name
                    TextFormField(
                      controller: _supplierController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อผู้จำหน่าย *',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อผู้จำหน่าย' : null,
                    ),
                    const SizedBox(height: 16),

                    // Order Date
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('วันที่สั่งซื้อ'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_orderDate)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _orderDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _orderDate = date);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Note
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'หมายเหตุ',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('รายการสินค้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addOrderLine,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('เพิ่มรายการ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_orderLines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('ยังไม่มีรายการสินค้า\nกดปุ่ม "เพิ่มรายการ" เพื่อเพิ่ม',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
                        ),
                      ),

                    ..._orderLines.asMap().entries.map((entry) {
                      final i = entry.key;
                      final line = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(line.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${line.quantity} x ${currencyFormat.format(line.unitPrice)} = ${currencyFormat.format(line.quantity * line.unitPrice)}'),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _orderLines.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const Divider(height: 32),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('รวมทั้งหมด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(currencyFormat.format(_totalAmount),
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _isSaving || _orderLines.isEmpty ? null : _savePO,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกใบสั่งซื้อ', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _addOrderLine() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบสินค้าในระบบ'), backgroundColor: Colors.orange),
      );
      return;
    }

    Product? selectedProduct;
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();

    final result = await showDialog<_OrderLine>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('เพิ่มรายการสินค้า'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                decoration: const InputDecoration(labelText: 'เลือกสินค้า *', border: OutlineInputBorder()),
                items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (p) {
                  setDialogState(() {
                    selectedProduct = p;
                    priceCtrl.text = p?.price.toString() ?? '';
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(labelText: 'จำนวน *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'ราคาต่อหน่วย *', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) return;
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (qty <= 0 || price <= 0) return;
                Navigator.pop(context, _OrderLine(
                  productId: selectedProduct!.id!,
                  productName: selectedProduct!.name,
                  quantity: qty,
                  unitPrice: price,
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700], foregroundColor: Colors.white),
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _orderLines.add(result));
    }
  }

  Future<void> _savePO() async {
    if (!_formKey.currentState!.validate()) return;
    if (_orderLines.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final po = PurchaseOrder(
        supplierName: _supplierController.text.trim(),
        orderDate: _orderDate,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      final items = _orderLines.map((line) => PurchaseOrderItem(
            productId: line.productId,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
          )).toList();

      await _transactionService.createPurchaseOrder(po, items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างใบสั่งซื้อเรียบร้อย'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isSaving = false);
  }
}

/// Helper class for order lines in the form
class _OrderLine {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  _OrderLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
}
