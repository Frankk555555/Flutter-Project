import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/transaction_service.dart';
import 'create_sale_screen.dart';

/// Screen for listing sales
class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  final TransactionService _service = TransactionService();
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      _sales = await _service.getAllSales();
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
        title: const Row(children: [Icon(Icons.point_of_sale), SizedBox(width: 8), Text('ขายสินค้า')]),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.point_of_sale_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('ไม่มีรายการขาย', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSales,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.receipt, color: Colors.amber[800]),
                          ),
                          title: Text('SALE #${sale.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('วันที่: ${dateFormat.format(sale.saleDate)}'),
                              if (sale.customerName != null) Text('ลูกค้า: ${sale.customerName}'),
                              Row(
                                children: [
                                  Text(currencyFormat.format(sale.netAmount),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(sale.paymentMethodDisplay,
                                        style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _showSaleDetail(sale.id!),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSaleScreen()));
          _loadSales();
        },
        icon: const Icon(Icons.add),
        label: const Text('ขายสินค้า'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showSaleDetail(int saleId) async {
    try {
      final sale = await _service.getSaleById(saleId);
      if (sale == null || !mounted) return;

      final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('SALE #${sale.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('วันที่: ${DateFormat('dd/MM/yyyy').format(sale.saleDate)}'),
                if (sale.customerName != null) Text('ลูกค้า: ${sale.customerName}'),
                Text('ชำระโดย: ${sale.paymentMethodDisplay}'),
                if (sale.note != null) Text('หมายเหตุ: ${sale.note}'),
                const Divider(),
                const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...sale.items.map((item) => Padding(
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('รวม'), Text(currencyFormat.format(sale.totalAmount)),
                ]),
                if (sale.discount > 0)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('ส่วนลด'), Text('- ${currencyFormat.format(sale.discount)}', style: const TextStyle(color: Colors.red)),
                  ]),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('ยอดสุทธิ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(currencyFormat.format(sale.netAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                ]),
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
