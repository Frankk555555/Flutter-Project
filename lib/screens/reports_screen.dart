import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import '../services/customer_service.dart';

/// Comprehensive reports screen with multiple tabs
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();
  final CustomerService _customerService = CustomerService();

  bool _isLoading = true;

  // Sales data
  Map<String, dynamic> _salesSummary = {};
  Map<String, dynamic> _purchaseSummary = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _categoryReport = [];
  List<Map<String, dynamic>> _customerReport = [];

  // Date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _transactionService.getSalesSummary(startDate: _startDate, endDate: _endDate),
        _transactionService.getPurchaseSummary(startDate: _startDate, endDate: _endDate),
        _transactionService.getTopProducts(),
        _categoryService.getProductCountByCategory(),
        _customerService.getCustomerSalesSummary(),
      ]);

      _salesSummary = results[0] as Map<String, dynamic>;
      _purchaseSummary = results[1] as Map<String, dynamic>;
      _topProducts = results[2] as List<Map<String, dynamic>>;
      _categoryReport = results[3] as List<Map<String, dynamic>>;
      _customerReport = results[4] as List<Map<String, dynamic>>;
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
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.bar_chart), SizedBox(width: 8), Text('รายงาน')]),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.point_of_sale), text: 'ยอดขาย'),
            Tab(icon: Icon(Icons.star), text: 'สินค้าขายดี'),
            Tab(icon: Icon(Icons.category), text: 'ตามประเภท'),
            Tab(icon: Icon(Icons.people), text: 'ลูกค้า'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date range selector
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.indigo[50],
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context, initialDate: _startDate,
                              firstDate: DateTime(2020), lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _startDate = date);
                              _loadReports();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                            ]),
                          ),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('ถึง')),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context, initialDate: _endDate,
                              firstDate: DateTime(2020), lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _endDate = date);
                              _loadReports();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesSummaryTab(),
                      _buildTopProductsTab(),
                      _buildCategoryTab(),
                      _buildCustomerTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSalesSummaryTab() {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sales Summary
          Row(
            children: [
              Expanded(child: _buildSummaryCard(
                'ยอดขาย',
                currencyFormat.format(_salesSummary['total_revenue'] ?? 0),
                Icons.trending_up, Colors.green,
                subtitle: '${_salesSummary['total_sales'] ?? 0} รายการ',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(
                'ยอดซื้อ',
                currencyFormat.format(_purchaseSummary['total_cost'] ?? 0),
                Icons.shopping_cart, Colors.orange,
                subtitle: '${_purchaseSummary['total_orders'] ?? 0} รายการ',
              )),
            ],
          ),
          const SizedBox(height: 16),
          // Profit
          _buildSummaryCard(
            'กำไร (ประมาณ)',
            currencyFormat.format(
              (_salesSummary['total_revenue'] ?? 0) - (_purchaseSummary['total_cost'] ?? 0),
            ),
            Icons.account_balance_wallet,
            ((_salesSummary['total_revenue'] ?? 0) - (_purchaseSummary['total_cost'] ?? 0)) >= 0
                ? Colors.green
                : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsTab() {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    if (_topProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('ยังไม่มีข้อมูลการขาย', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topProducts.length,
      itemBuilder: (context, index) {
        final product = _topProducts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('#${index + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800])),
              ),
            ),
            title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ขายได้ ${product['total_sold']} ชิ้น'),
            trailing: Text(currencyFormat.format(product['total_revenue']),
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTab() {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    if (_categoryReport.isEmpty) {
      return Center(child: Text('ยังไม่มีประเภทสินค้า', style: TextStyle(color: Colors.grey[600])));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categoryReport.length,
      itemBuilder: (context, index) {
        final cat = _categoryReport[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('สินค้า', '${cat['product_count']}', Icons.inventory_2),
                    _buildMiniStat('สต๊อก', '${cat['total_stock']}', Icons.layers),
                    _buildMiniStat('มูลค่า', currencyFormat.format(cat['total_value']), Icons.attach_money),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerTab() {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    if (_customerReport.isEmpty) {
      return Center(child: Text('ยังไม่มีข้อมูลลูกค้า', style: TextStyle(color: Colors.grey[600])));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customerReport.length,
      itemBuilder: (context, index) {
        final cust = _customerReport[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.teal[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  cust['name'].toString().isNotEmpty ? cust['name'][0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[700]),
                ),
              ),
            ),
            title: Text(cust['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${cust['total_orders']} คำสั่งซื้อ'),
            trailing: Text(currencyFormat.format(cust['total_spent']),
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ),
            if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
