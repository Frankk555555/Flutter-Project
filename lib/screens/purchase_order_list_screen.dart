import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/purchase_order.dart';
import '../services/transaction_service.dart';
import 'create_purchase_order_screen.dart';

/// Screen for listing purchase orders
class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  final TransactionService _service = TransactionService();
  List<PurchaseOrder> _orders = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final all = await _service.getAllPurchaseOrders();
      if (_statusFilter == 'all') {
        _orders = all;
      } else {
        _orders = all.where((o) => o.status == _statusFilter).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.shopping_cart), SizedBox(width: 8), Text('สั่งซื้อสินค้า')]),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'ทั้งหมด', Icons.list),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'รอดำเนินการ', Icons.hourglass_empty),
                  const SizedBox(width: 8),
                  _buildFilterChip('received', 'รับแล้ว', Icons.check_circle),
                  const SizedBox(width: 8),
                  _buildFilterChip('cancelled', 'ยกเลิก', Icons.cancel),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('ไม่มีรายการสั่งซื้อ', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final po = _orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(po.status).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.receipt_long, color: _getStatusColor(po.status)),
                                ),
                                title: Text('PO #${po.id} - ${po.supplierName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('วันที่: ${dateFormat.format(po.orderDate)}'),
                                    Row(
                                      children: [
                                        Text(currencyFormat.format(po.totalAmount),
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(po.status).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(po.statusDisplay,
                                              style: TextStyle(fontSize: 12, color: _getStatusColor(po.status))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                onTap: () => _showPODetail(po.id!),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePurchaseOrderScreen()));
          _loadOrders();
        },
        icon: const Icon(Icons.add),
        label: const Text('สั่งซื้อ'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(label),
      ]),
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _loadOrders();
      },
      selectedColor: Colors.indigo[100],
    );
  }

  Future<void> _showPODetail(int poId) async {
    try {
      final po = await _service.getPurchaseOrderById(poId);
      if (po == null || !mounted) return;

      final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('PO #${po.id} - ${po.supplierName}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('สถานะ: ${po.statusDisplay}'),
                Text('วันที่สั่ง: ${DateFormat('dd/MM/yyyy').format(po.orderDate)}'),
                if (po.note != null) Text('หมายเหตุ: ${po.note}'),
                const Divider(),
                const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...po.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.productName ?? 'สินค้า #${item.productId}')),
                          Text('${item.quantity} x ${currencyFormat.format(item.unitPrice)}'),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('รวมทั้งหมด', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(currencyFormat.format(po.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
