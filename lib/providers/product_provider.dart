import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product.dart';
import '../services/product_service.dart';

/// Provider class for managing product state
class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  
  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showLowStockOnly = false;
  Map<String, dynamic> _summary = {};

  // Getters
  List<Product> get products => _filteredProducts;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get showLowStockOnly => _showLowStockOnly;
  Map<String, dynamic> get summary => _summary;

  /// Get filtered products based on search and category
  List<Product> get _filteredProducts {
    var filtered = _products;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    // Filter by low stock
    if (_showLowStockOnly) {
      filtered = filtered.where((p) => p.isLowStock).toList();
    }
    
    return filtered;
  }

  /// Initialize database and load products
  Future<void> init() async {
    if (kIsWeb) {
      _error = '⚠️ ไม่รองรับการใช้งานบน Web Browser\n\n'
          'เนื่องจากข้อจำกัดความปลอดภัยของ Browser ในการเชื่อมต่อ MySQL โดยตรง\n'
          'กรุณารันโปรแกรมบน Windows Desktop แทนด้วยคำสั่ง:\n'
          'flutter run -d windows';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.initDatabase();
      await loadProducts();
      await loadCategories();
      await loadSummary();
    } catch (e) {
      _error = 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all products from database
  Future<void> loadProducts() async {
    try {
      _products = await _service.getAllProducts();
      _error = null;
    } catch (e) {
      _error = 'ไม่สามารถโหลดสินค้าได้: $e';
    }
    notifyListeners();
  }

  /// Load all categories
  Future<void> loadCategories() async {
    try {
      _categories = await _service.getAllCategories();
    } catch (e) {
      // Ignore category loading errors
    }
  }

  /// Load summary statistics
  Future<void> loadSummary() async {
    try {
      _summary = await _service.getStockSummary();
    } catch (e) {
      _summary = {'totalProducts': 0, 'totalValue': 0.0, 'lowStockCount': 0};
    }
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set selected category filter
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Toggle low stock filter
  void toggleLowStockFilter() {
    _showLowStockOnly = !_showLowStockOnly;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _showLowStockOnly = false;
    notifyListeners();
  }

  /// Create new product
  Future<bool> createProduct(Product product) async {
    try {
      final newId = await _service.createProduct(product);
      
      // Record stock movement for new product
      if (product.quantity > 0) {
        await _service.recordMovement(
          productId: newId,
          productName: product.name,
          movementType: 'NEW',
          quantity: product.quantity,
          previousQuantity: 0,
          newQuantity: product.quantity,
          note: 'สินค้าใหม่',
        );
      }
      
      await loadProducts();
      await loadCategories();
      await loadSummary();
      return true;
    } catch (e) {
      _error = 'ไม่สามารถเพิ่มสินค้าได้: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update existing product
  Future<bool> updateProduct(Product product) async {
    try {
      // Get old product to compare quantity
      final oldProduct = await _service.getProductById(product.id!);
      final oldQuantity = oldProduct?.quantity ?? 0;
      final newQuantity = product.quantity;
      
      final success = await _service.updateProduct(product);
      if (success) {
        // Record movement if quantity changed
        if (newQuantity != oldQuantity) {
          final difference = newQuantity - oldQuantity;
          await _service.recordMovement(
            productId: product.id!,
            productName: product.name,
            movementType: difference > 0 ? 'IN' : 'OUT',
            quantity: difference.abs(),
            previousQuantity: oldQuantity,
            newQuantity: newQuantity,
            note: 'ปรับปรุงสต๊อก',
          );
        }
        
        await loadProducts();
        await loadCategories();
        await loadSummary();
      }
      return success;
    } catch (e) {
      _error = 'ไม่สามารถอัปเดตสินค้าได้: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(int id) async {
    try {
      final success = await _service.deleteProduct(id);
      if (success) {
        await loadProducts();
        await loadCategories();
        await loadSummary();
      }
      return success;
    } catch (e) {
      _error = 'ไม่สามารถลบสินค้าได้: $e';
      notifyListeners();
      return false;
    }
  }

  /// Quick adjust stock (เบิกออก/นำเข้า)
  Future<bool> adjustStock({
    required int productId,
    required int adjustment, // positive = นำเข้า, negative = เบิกออก
    String? note,
  }) async {
    try {
      final product = await _service.getProductById(productId);
      if (product == null) return false;

      final oldQuantity = product.quantity;
      final newQuantity = oldQuantity + adjustment;
      
      if (newQuantity < 0) {
        _error = 'จำนวนเกินสต๊อกที่มี';
        notifyListeners();
        return false;
      }

      // Update product quantity
      final updatedProduct = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        category: product.category,
        price: product.price,
        quantity: newQuantity,
        minQuantity: product.minQuantity,
        imageUrl: product.imageUrl,
      );

      final success = await _service.updateProduct(updatedProduct);
      if (success) {
        // Record movement
        await _service.recordMovement(
          productId: productId,
          productName: product.name,
          movementType: adjustment > 0 ? 'IN' : 'OUT',
          quantity: adjustment.abs(),
          previousQuantity: oldQuantity,
          newQuantity: newQuantity,
          note: note ?? (adjustment > 0 ? 'นำเข้าสต๊อก' : 'เบิกออก/ขาย'),
        );

        await loadProducts();
        await loadSummary();
      }
      return success;
    } catch (e) {
      _error = 'ไม่สามารถปรับสต๊อกได้: $e';
      notifyListeners();
      return false;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _service.close();
    super.dispose();
  }
}
