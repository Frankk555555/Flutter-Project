import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/product_service.dart';
import '../services/transaction_service.dart';
import 'product_list_screen.dart';
import 'category_list_screen.dart';
import 'customer_list_screen.dart';
import 'purchase_order_list_screen.dart';
import 'goods_received_list_screen.dart';
import 'sale_list_screen.dart';
import 'stock_history_screen.dart';
import 'reports_screen.dart';

/// Home screen with dashboard and navigation drawer
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();

  Map<String, dynamic> _productSummary = {};
  Map<String, dynamic> _salesSummary = {};
  Map<String, dynamic> _purchaseSummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);

      _productSummary = await _productService.getStockSummary();
      _salesSummary = await _transactionService.getSalesSummary(startDate: startOfMonth, endDate: today);
      _purchaseSummary = await _transactionService.getPurchaseSummary(startDate: startOfMonth, endDate: today);
    } catch (e) {
      // ignore, show whatever we have
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard),
            SizedBox(width: 8),
            Text('ระบบจัดการสต๊อกและขาย'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Text('แดชบอร์ด', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
                    Text('สรุปข้อมูลประจำเดือน ${DateFormat('MMMM yyyy', 'th').format(DateTime.now())}',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 20),

                    // Product Summary Row
                    Row(
                      children: [
                        Expanded(child: _buildDashboardCard(
                          'สินค้าทั้งหมด',
                          '${_productSummary['totalProducts'] ?? 0}',
                          Icons.inventory_2, Colors.blue,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDashboardCard(
                          'มูลค่าสต๊อก',
                          currencyFormat.format(_productSummary['totalValue'] ?? 0),
                          Icons.currency_exchange, Colors.green,
                          customIcon: Text('฿', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDashboardCard(
                          'สินค้าใกล้หมด',
                          '${_productSummary['lowStockCount'] ?? 0}',
                          Icons.warning_amber, Colors.orange,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDashboardCard(
                          'ยอดขาย',
                          currencyFormat.format(_salesSummary['total_revenue'] ?? 0),
                          Icons.point_of_sale, Colors.teal,
                          subtitle: '${_salesSummary['total_sales'] ?? 0} รายการ',
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDashboardCard(
                          'ยอดสั่งซื้อ',
                          currencyFormat.format(_purchaseSummary['total_cost'] ?? 0),
                          Icons.shopping_cart, Colors.purple,
                          subtitle: '${_purchaseSummary['total_orders'] ?? 0} รายการ',
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDashboardCard(
                          'กำไร (ประมาณ)',
                          currencyFormat.format(
                            (_salesSummary['total_revenue'] ?? 0) - (_purchaseSummary['total_cost'] ?? 0),
                          ),
                          Icons.account_balance_wallet,
                          ((_salesSummary['total_revenue'] ?? 0) - (_purchaseSummary['total_cost'] ?? 0)) >= 0
                              ? Colors.green
                              : Colors.red,
                        )),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions
                    Text('ทางลัด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[700])),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildQuickAction('สินค้า', Icons.inventory_2, Colors.blue, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                        }),
                        _buildQuickAction('ขายสินค้า', Icons.point_of_sale, Colors.teal, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleListScreen()));
                        }),
                        _buildQuickAction('สั่งซื้อ', Icons.shopping_cart, Colors.orange, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseOrderListScreen()));
                        }),
                        _buildQuickAction('รับสินค้า', Icons.archive, Colors.green, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const GoodsReceivedListScreen()));
                        }),
                        _buildQuickAction('ลูกค้า', Icons.people, Colors.purple, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen()));
                        }),
                        _buildQuickAction('รายงาน', Icons.bar_chart, Colors.red, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[700]!, Colors.indigo[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.computer, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text('ระบบจัดการสต๊อก', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Stock & Sales Management', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'แดชบอร์ด', () => Navigator.pop(context)),
          const Divider(),
          _buildDrawerSection('ข้อมูลหลัก'),
          _buildDrawerItem(Icons.inventory_2, 'สินค้า', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
          }),
          _buildDrawerItem(Icons.category, 'ประเภทสินค้า', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen()));
          }),
          _buildDrawerItem(Icons.people, 'ลูกค้า', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen()));
          }),
          const Divider(),
          _buildDrawerSection('ธุรกรรม'),
          _buildDrawerItem(Icons.shopping_cart, 'สั่งซื้อสินค้า', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseOrderListScreen()));
          }),
          _buildDrawerItem(Icons.archive, 'รับสินค้า', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GoodsReceivedListScreen()));
          }),
          _buildDrawerItem(Icons.point_of_sale, 'ขายสินค้า', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleListScreen()));
          }),
          const Divider(),
          _buildDrawerSection('ประวัติและรายงาน'),
          _buildDrawerItem(Icons.history, 'ประวัติเคลื่อนไหว', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StockHistoryScreen()));
          }),
          _buildDrawerItem(Icons.bar_chart, 'รายงาน', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo[700]),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildDashboardCard(String title, String value, IconData icon, Color color, {String? subtitle, Widget? customIcon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: customIcon ?? Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ),
            if (subtitle != null)
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
