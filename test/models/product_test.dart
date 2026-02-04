import 'package:flutter_test/flutter_test.dart';
import 'package:stock_management/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Should create product correctly', () {
      final product = Product(
        name: 'Test Product',
        category: 'Test Category',
        price: 100.0,
        quantity: 10,
      );

      expect(product.name, 'Test Product');
      expect(product.category, 'Test Category');
      expect(product.price, 100.0);
      expect(product.quantity, 10);
      expect(product.minQuantity, 10); // Default value
    });

    test('isLowStock should work correctly', () {
      final normalProduct = Product(
        name: 'Normal',
        category: 'Test',
        price: 100,
        quantity: 20,
        minQuantity: 10,
      );
      
      final lowStockProduct = Product(
        name: 'Low Stock',
        category: 'Test',
        price: 100,
        quantity: 5,
        minQuantity: 10,
      );

      expect(normalProduct.isLowStock, false);
      expect(lowStockProduct.isLowStock, true);
    });

    test('toMap and fromMap should work correctly', () {
      final originalProduct = Product(
        id: 1,
        name: 'Test Product',
        description: 'Description',
        category: 'Category',
        price: 150.0,
        quantity: 50,
        minQuantity: 20,
        imageUrl: 'http://example.com/image.jpg',
      );

      final map = originalProduct.toMap();
      final fromMapProduct = Product.fromMap(map);

      expect(fromMapProduct.id, originalProduct.id);
      expect(fromMapProduct.name, originalProduct.name);
      expect(fromMapProduct.price, originalProduct.price);
      expect(fromMapProduct.quantity, originalProduct.quantity);
      expect(fromMapProduct.minQuantity, originalProduct.minQuantity);
    });

    test('copyWith should update fields correctly', () {
      final product = Product(
        name: 'Original',
        category: 'Cat 1',
        price: 100,
        quantity: 10,
      );

      final updated = product.copyWith(
        name: 'Updated',
        price: 200,
      );

      expect(updated.name, 'Updated');
      expect(updated.price, 200);
      expect(updated.category, 'Cat 1'); // Should keep original value
      expect(updated.quantity, 10); // Should keep original value
    });
  });
}
