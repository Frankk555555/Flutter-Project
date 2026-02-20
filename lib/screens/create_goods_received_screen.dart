import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/goods_received.dart';
import '../models/purchase_order.dart';
import '../services/product_service.dart';
import '../services/transaction_service.dart';

/// Screen for creating a new goods received record
class CreateGoodsReceivedScreen extends StatefulWidget {
  const CreateGoodsReceivedScreen({super.key});

  @override
  State<CreateGoodsReceivedScreen> createState() => _CreateGoodsReceivedScreenState();
}

class _CreateGoodsReceivedScreenState extends State<CreateGoodsReceivedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receivedByController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _receivedDate = DateTime.now();

  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();

  List<Product> _products = [];
  List<PurchaseOrder> _pendingPOs = [];
  PurchaseOrder? _selectedPO;
  List<_ReceiveLine> _lines = [];
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
      final results = await Future.wait([
        _productService.getAllProducts(),
        _transactionService.getAllPurchaseOrders(),
      ]);
      
      _products = results[0] as List<Product>;
      final allPOs = results[1] as List<PurchaseOrder>;
      // Filter only pending POs
      _pendingPOs = allPOs.where((po) => po.status == 'pending').toList();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _onPOSelected(PurchaseOrder? po) async {
    setState(() {
      _selectedPO = po;
      _lines = []; // Clear current lines
    });

    if (po == null) return;

    // Load PO details with items
    setState(() => _isLoading = true);
    try {
      final fullPO = await _transactionService.getPurchaseOrderById(po.id!);
      if (fullPO != null) {
        setState(() {
          _lines = fullPO.items.map((item) => _ReceiveLine(
            productId: item.productId,
            productName: item.productName ?? 'Product #${item.productId}',
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          )).toList();
          
          // Auto-fill note
          if (_noteController.text.isEmpty) {
            _noteController.text = 'รับสินค้าจาก PO #${po.id}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PO details: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _receivedByController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกรับสินค้า'),
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
                    // PO Selection
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('อ้างอิงใบสั่งซื้อ (Purchase Order)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<PurchaseOrder>(
                              decoration: const InputDecoration(
                                labelText: 'เลือกใบสั่งซื้อ (แนะนำ)',
                                prefixIcon: Icon(Icons.receipt_long),
                                border: OutlineInputBorder(),
                                helperText: 'เลือก "ไม่ระบุ" หากต้องการเพิ่มรายการเอง',
                              ),
                              value: _selectedPO,
                              items: [
                                const DropdownMenuItem<PurchaseOrder>(
                                  value: null,
                                  child: Text('ไม่ระบุ (เพิ่มรายการเอง)'),
                                ),
                                ..._pendingPOs.map((po) => DropdownMenuItem(
                                      value: po,
                                      child: Text('PO #${po.id} - ${po.supplierName} (${DateFormat('dd/MM').format(po.orderDate)})'),
                                    )),
                              ],
                              onChanged: _onPOSelected,
                            ),
                            if (_selectedPO != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[100]!),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('ผู้จำหน่าย: ${_selectedPO!.supplierName}'),
                                        Text('วันที่สั่ง: ${DateFormat('dd/MM/yyyy').format(_selectedPO!.orderDate)}'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('ยอดรวม: ${currencyFormat.format(_selectedPO!.totalAmount)}'),
                                        const Text('สถานะ: รอดำเนินการ', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Received Date
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('วันที่รับสินค้า'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_receivedDate)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _receivedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _receivedDate = date);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Received By
                    TextFormField(
                      controller: _receivedByController,
                      decoration: const InputDecoration(
                        labelText: 'ผู้รับสินค้า',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
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

                    // Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('รายการสินค้าที่รับ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        child: Center(
                          child: Text(_selectedPO != null ? 'ไม่มีรายการสินค้าใน PO นี้' : 'ยังไม่มีรายการ',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
                        ),
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
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editLine(i),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _lines.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _isSaving || _lines.isEmpty ? null : _saveGR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกรับสินค้า', style: const TextStyle(fontSize: 16)),
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

    final result = await showDialog<_ReceiveLine>(
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
                  Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'จำนวน *', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'ราคาต่อหน่วย *', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
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
                Navigator.pop(context, _ReceiveLine(
                  productId: selectedProduct!.id!, productName: selectedProduct!.name,
                  quantity: qty, unitPrice: price,
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
  
  Future<void> _editLine(int index) async {
    final line = _lines[index];
    final qtyCtrl = TextEditingController(text: line.quantity.toString());
    final priceCtrl = TextEditingController(text: line.unitPrice.toString());

    final result = await showDialog<_ReceiveLine>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('แก้ไขรายการ: ${line.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'จำนวน *', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'ราคาต่อหน่วย *', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              final price = double.tryParse(priceCtrl.text) ?? 0;
              if (qty <= 0 || price <= 0) return;
              Navigator.pop(context, _ReceiveLine(
                productId: line.productId, productName: line.productName,
                quantity: qty, unitPrice: price,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700], foregroundColor: Colors.white),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _lines[index] = result;
      });
    }
  }

  Future<void> _saveGR() async {
    if (_lines.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final gr = GoodsReceived(
        purchaseOrderId: _selectedPO?.id, // Link to PO if selected
        receivedDate: _receivedDate,
        receivedBy: _receivedByController.text.trim().isNotEmpty ? _receivedByController.text.trim() : null,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      final items = _lines.map((l) => GoodsReceivedItem(
            productId: l.productId, quantity: l.quantity, unitPrice: l.unitPrice,
          )).toList();

      await _transactionService.createGoodsReceived(gr, items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedPO != null 
              ? 'บันทึกรับสินค้าและอัปเดต PO เรียบร้อย' 
              : 'บันทึกรับสินค้าเรียบร้อย'), 
            backgroundColor: Colors.green
          ),
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

class _ReceiveLine {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  _ReceiveLine({required this.productId, required this.productName, required this.quantity, required this.unitPrice});
}
