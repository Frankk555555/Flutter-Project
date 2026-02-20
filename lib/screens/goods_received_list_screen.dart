import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goods_received.dart';
import '../services/transaction_service.dart';
import 'create_goods_received_screen.dart';

/// Screen for listing goods received records
class GoodsReceivedListScreen extends StatefulWidget {
  const GoodsReceivedListScreen({super.key});

  @override
  State<GoodsReceivedListScreen> createState() => _GoodsReceivedListScreenState();
}

class _GoodsReceivedListScreenState extends State<GoodsReceivedListScreen> {
  final TransactionService _service = TransactionService();
  List<GoodsReceived> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      _records = await _service.getAllGoodsReceived();
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.archive), SizedBox(width: 8), Text('รับสินค้า')]),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('ไม่มีรายการรับสินค้า', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final gr = _records[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.inventory, color: Colors.green[700]),
                          ),
                          title: Text('GR #${gr.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('วันที่รับ: ${dateFormat.format(gr.receivedDate)}'),
                              if (gr.receivedBy != null) Text('ผู้รับ: ${gr.receivedBy}'),
                              if (gr.purchaseOrderId != null) Text('อ้างอิง PO #${gr.purchaseOrderId}'),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _showGRDetail(gr.id!),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGoodsReceivedScreen()));
          _loadRecords();
        },
        icon: const Icon(Icons.add),
        label: const Text('รับสินค้า'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showGRDetail(int grId) async {
    try {
      final gr = await _service.getGoodsReceivedById(grId);
      if (gr == null || !mounted) return;

      final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('GR #${gr.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('วันที่รับ: ${DateFormat('dd/MM/yyyy').format(gr.receivedDate)}'),
                if (gr.receivedBy != null) Text('ผู้รับ: ${gr.receivedBy}'),
                if (gr.purchaseOrderId != null) Text('อ้างอิง PO #${gr.purchaseOrderId}'),
                if (gr.note != null) Text('หมายเหตุ: ${gr.note}'),
                const Divider(),
                const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...gr.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.productName ?? 'สินค้า #${item.productId}')),
                          Text('${item.quantity} x ${currencyFormat.format(item.unitPrice)}'),
                        ],
                      ),
                    )),
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
