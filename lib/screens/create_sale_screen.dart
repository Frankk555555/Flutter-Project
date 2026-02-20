import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../services/product_service.dart';
import '../services/customer_service.dart';
import '../services/transaction_service.dart';

/// Screen for creating a new sale
class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  DateTime _saleDate = DateTime.now();
  String _paymentMethod = 'cash';
  Customer? _selectedCustomer;

  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final TransactionService _transactionService = TransactionService();

  List<Product> _products = [];
  List<Customer> _customers = [];
  List<_SaleLine> _lines = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _products = await _productService.getAllProducts();
      _customers = await _customerService.getAllCustomers();
    } catch (e) {
      // ignore
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _discountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    double total = 0;
    for (var line in _lines) {
      total += (line.quantity * line.unitPrice) - line.discount;
    }
    return total;
  }

  double get _netAmount {
    return _totalAmount - (double.tryParse(_discountController.text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ขายสินค้า'),
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
                    // Sale Date
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('วันที่ขาย'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_saleDate)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _saleDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _saleDate = date);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Customer Dropdown (optional)
                    DropdownButtonFormField<Customer?>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'ลูกค้า (ไม่บังคับ)',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('ลูกค้าทั่วไป (ไม่ระบุ)')),
                        ..._customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _selectedCustomer = v),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'วิธีชำระเงิน',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('เงินสด')),
                        DropdownMenuItem(value: 'transfer', child: Text('โอนเงิน')),
                        DropdownMenuItem(value: 'credit', child: Text('เครดิต')),
                      ],
                      onChanged: (v) => setState(() => _paymentMethod = v!),
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

                    // Sale Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('รายการสินค้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('เพิ่มรายการ'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_lines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text('ยังไม่มีรายการ', style: TextStyle(color: Colors.grey[500]))),
                      ),

                    ..._lines.asMap().entries.map((entry) {
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
                                    Text('${line.quantity} x ${currencyFormat.format(line.unitPrice)}'),
                                    if (line.discount > 0) Text('ส่วนลด: ${currencyFormat.format(line.discount)}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                    Text('คงเหลือในสต๊อก: ${line.stockRemaining}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _lines.removeAt(i))),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Discount
                    TextFormField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'ส่วนลดรวม (บาท)',
                        prefixIcon: Icon(Icons.discount),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('รวม'), Text(currencyFormat.format(_totalAmount)),
                          ]),
                          if ((double.tryParse(_discountController.text) ?? 0) > 0)
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('ส่วนลด'), Text('- ${currencyFormat.format(double.tryParse(_discountController.text) ?? 0)}', style: const TextStyle(color: Colors.red)),
                            ]),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('ยอดสุทธิ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(currencyFormat.format(_netAmount),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _isSaving || _lines.isEmpty ? null : _saveSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกการขาย', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _addLine() async {
    if (_products.isEmpty) return;

    Product? selectedProduct;
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final discCtrl = TextEditingController(text: '0');

    final result = await showDialog<_SaleLine>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('เพิ่มรายการสินค้า'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(labelText: 'เลือกสินค้า *', border: OutlineInputBorder()),
                  items: _products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (คงเหลือ: ${p.quantity})'))).toList(),
                  onChanged: (p) {
                    setDialogState(() {
                      selectedProduct = p;
                      priceCtrl.text = p?.price.toString() ?? '';
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'จำนวน *', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'ราคาขาย *', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: discCtrl, decoration: const InputDecoration(labelText: 'ส่วนลด (บาท)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) return;
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                final price = double.tryParse(priceCtrl.text) ?? 0;
                final disc = double.tryParse(discCtrl.text) ?? 0;
                if (qty <= 0 || price <= 0) return;
                if (qty > selectedProduct!.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('จำนวนเกินสต๊อก'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                Navigator.pop(context, _SaleLine(
                  productId: selectedProduct!.id!, productName: selectedProduct!.name,
                  quantity: qty, unitPrice: price, discount: disc,
                  stockRemaining: selectedProduct!.quantity - qty,
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700], foregroundColor: Colors.white),
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );

    if (result != null) setState(() => _lines.add(result));
  }

  Future<void> _saveSale() async {
    if (_lines.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final sale = Sale(
        customerId: _selectedCustomer?.id,
        saleDate: _saleDate,
        discount: double.tryParse(_discountController.text) ?? 0,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      final items = _lines.map((l) => SaleItem(
            productId: l.productId, quantity: l.quantity, unitPrice: l.unitPrice, discount: l.discount,
          )).toList();

      await _transactionService.createSale(sale, items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการขายเรียบร้อย (สต๊อกอัปเดตแล้ว)'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isSaving = false);
  }
}

class _SaleLine {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final int stockRemaining;
  _SaleLine({
    required this.productId, required this.productName,
    required this.quantity, required this.unitPrice,
    this.discount = 0, this.stockRemaining = 0,
  });
}
