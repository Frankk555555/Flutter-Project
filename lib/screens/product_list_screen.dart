import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/stock_adjust_dialog.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'stock_history_screen.dart';

/// Main screen displaying product list with search and filter
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize database and load products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.computer),
            SizedBox(width: 8),
            Text('สต๊อกอุปกรณ์คอมพิวเตอร์'),
          ],
        ),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ประวัติสต๊อก',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StockHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังโหลดข้อมูล...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.init(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search Bar
              Container(
                color: Colors.indigo[700],
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาสินค้า...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) => provider.setSearchQuery(value),
                ),
              ),

              // Filters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Category Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedCategory,
                            hint: const Text('หมวดหมู่ทั้งหมด'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('หมวดหมู่ทั้งหมด'),
                              ),
                              ...provider.categories.map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              ),
                            ],
                            onChanged: (value) => provider.setCategory(value),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Low Stock Filter
                    FilterChip(
                      label: const Text('สต๊อกต่ำ'),
                      selected: provider.showLowStockOnly,
                      onSelected: (_) => provider.toggleLowStockFilter(),
                      selectedColor: Colors.red[100],
                      avatar: provider.showLowStockOnly
                          ? const Icon(Icons.warning, size: 18, color: Colors.red)
                          : null,
                    ),
                  ],
                ),
              ),

              // Summary Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[600]!, Colors.indigo[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.inventory_2,
                      label: 'สินค้าทั้งหมด',
                      value: '${provider.summary['totalProducts'] ?? 0}',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildSummaryItem(
                      customIcon: const Text('฿', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      label: 'มูลค่ารวม',
                      value: currencyFormat.format(
                        provider.summary['totalValue'] ?? 0,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildSummaryItem(
                      icon: Icons.warning_amber,
                      label: 'สต๊อกต่ำ',
                      value: '${provider.summary['lowStockCount'] ?? 0}',
                      valueColor: Colors.yellow,
                    ),
                  ],
                ),
              ),

              // Product List
              Expanded(
                child: provider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ไม่พบสินค้า',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'เพิ่มสินค้าใหม่โดยกดปุ่ม + ด้านล่าง',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadProducts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: provider.products.length,
                          itemBuilder: (context, index) {
                            final product = provider.products[index];
                            return ProductCard(
                              product: product,
                              onEdit: () => _navigateToEdit(product.id!),
                              onDelete: () => _confirmDelete(product.id!, product.name),
                              onWithdraw: () => _showAdjustDialog(product, isWithdraw: true),
                              onStockIn: () => _showAdjustDialog(product, isWithdraw: false),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสินค้า'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryItem({
    IconData? icon,
    Widget? customIcon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        customIcon ?? Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
  }

  void _navigateToEdit(int productId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProductScreen(productId: productId)),
    );
  }

  Future<void> _confirmDelete(int productId, String productName) async {
    final confirmed = await DeleteDialog.show(context, productName);
    if (confirmed == true && mounted) {
      final success = await context.read<ProductProvider>().deleteProduct(productId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบ "$productName" เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showAdjustDialog(product, {required bool isWithdraw}) async {
    final result = await StockAdjustDialog.show(
      context,
      product,
      isWithdraw: isWithdraw,
    );

    if (result != null && mounted) {
      final quantity = result['quantity'] as int;
      final note = result['note'] as String?;
      
      final adjustment = isWithdraw ? -quantity : quantity;
      final success = await context.read<ProductProvider>().adjustStock(
        productId: product.id!,
        adjustment: adjustment,
        note: note?.isNotEmpty == true ? note : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isWithdraw 
                  ? 'เบิกออก "${ product.name}" $quantity ชิ้น'
                  : 'นำเข้า "${product.name}" $quantity ชิ้น',
            ),
            backgroundColor: isWithdraw ? Colors.orange : Colors.green,
          ),
        );
      }
    }
  }
}
