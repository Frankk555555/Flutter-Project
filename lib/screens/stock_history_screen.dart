import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_movement.dart';
import '../services/product_service.dart';

/// Screen for viewing stock movement history
class StockHistoryScreen extends StatefulWidget {
  final int? productId;
  final String? productName;

  const StockHistoryScreen({
    super.key,
    this.productId,
    this.productName,
  });

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final ProductService _service = ProductService();
  List<StockMovement> _movements = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, today, in, out

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);

    try {
      List<StockMovement> movements;
      
      if (widget.productId != null) {
        movements = await _service.getProductMovements(widget.productId!);
      } else if (_filter == 'today') {
        movements = await _service.getTodayMovements();
      } else {
        movements = await _service.getAllMovements();
      }

      // Apply type filter
      if (_filter == 'in') {
        movements = movements.where((m) => m.isIncoming).toList();
      } else if (_filter == 'out') {
        movements = movements.where((m) => !m.isIncoming).toList();
      }

      setState(() {
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName != null 
            ? 'ประวัติ: ${widget.productName}'
            : 'ประวัติการเคลื่อนไหวสต๊อก'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          if (widget.productId == null)
            Container(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'ทั้งหมด', Icons.list),
                    const SizedBox(width: 8),
                    _buildFilterChip('today', 'วันนี้', Icons.today),
                    const SizedBox(width: 8),
                    _buildFilterChip('in', 'นำเข้า', Icons.add_circle),
                    const SizedBox(width: 8),
                    _buildFilterChip('out', 'นำออก', Icons.remove_circle),
                  ],
                ),
              ),
            ),

          // Movement List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _movements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'ยังไม่มีประวัติการเคลื่อนไหว',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMovements,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _movements.length,
                          itemBuilder: (context, index) {
                            final movement = _movements[index];
                            final isIncoming = movement.isIncoming;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isIncoming 
                                        ? Colors.green[100] 
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isIncoming 
                                        ? Icons.add_circle 
                                        : Icons.remove_circle,
                                    color: isIncoming 
                                        ? Colors.green[700] 
                                        : Colors.red[700],
                                  ),
                                ),
                                title: Text(
                                  movement.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${movement.movementTypeDisplay}: ${isIncoming ? '+' : '-'}${movement.quantity} ชิ้น',
                                      style: TextStyle(
                                        color: isIncoming ? Colors.green[700] : Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${movement.previousQuantity} → ${movement.newQuantity} ชิ้น',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    if (movement.note != null && movement.note!.isNotEmpty)
                                      Text(
                                        'หมายเหตุ: ${movement.note}',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  movement.createdAt != null
                                      ? dateFormat.format(movement.createdAt!)
                                      : '-',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) {
        setState(() => _filter = value);
        _loadMovements();
      },
      selectedColor: Colors.indigo[100],
    );
  }
}
