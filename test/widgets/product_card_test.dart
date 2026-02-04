import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_management/models/product.dart';
import 'package:stock_management/widgets/product_card.dart';

void main() {
  group('ProductCard Widget Tests', () {
    testWidgets('Should render product information correctly', (WidgetTester tester) async {
      final product = Product(
        name: 'Test Scroll Bar',
        category: 'Stationery',
        price: 50.0,
        quantity: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify product name is displayed
      expect(find.text('Test Scroll Bar'), findsOneWidget);
      
      // Verify category is displayed
      expect(find.text('หมวดหมู่: Stationery'), findsOneWidget);
      
      // Verify price is displayed (formatted with currency)
      expect(find.textContaining('50.00'), findsOneWidget);
      
      // Verify quantity is displayed
      expect(find.text('คงเหลือ: 100'), findsOneWidget);
    });

    testWidgets('Should show low stock warning when quantity < minQuantity', (WidgetTester tester) async {
      final lowStockProduct = Product(
        name: 'Low Stock Item',
        category: 'Test',
        price: 100,
        quantity: 2,
        minQuantity: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: lowStockProduct,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify "Stock Low" label is displayed
      expect(find.text('สต๊อกต่ำ'), findsOneWidget);
      
      // Verify icon warning is displayed
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });
  });
}
