import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Service for generating PDF reports
class PdfReportService {
  /// Generate a comprehensive report PDF
  static Future<pw.Document> generateReport({
    required Map<String, dynamic> salesSummary,
    required Map<String, dynamic> purchaseSummary,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> categoryReport,
    required List<Map<String, dynamic>> customerReport,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat('#,##0.00');

    final totalRevenue = (salesSummary['total_revenue'] ?? 0).toDouble();
    final totalCost = (purchaseSummary['total_cost'] ?? 0).toDouble();
    final profit = totalRevenue - totalCost;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(dateFormat, startDate, endDate),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Sales Summary Section
          _buildSectionTitle('Sales Summary / Summary'),
          pw.SizedBox(height: 8),
          _buildSummaryTable(salesSummary, purchaseSummary, profit, currencyFormat),
          pw.SizedBox(height: 24),

          // Top Products Section
          if (topProducts.isNotEmpty) ...[
            _buildSectionTitle('Top Selling Products'),
            pw.SizedBox(height: 8),
            _buildTopProductsTable(topProducts, currencyFormat),
            pw.SizedBox(height: 24),
          ],

          // Category Report Section
          if (categoryReport.isNotEmpty) ...[
            _buildSectionTitle('Report by Category'),
            pw.SizedBox(height: 8),
            _buildCategoryTable(categoryReport, currencyFormat),
            pw.SizedBox(height: 24),
          ],

          // Customer Report Section
          if (customerReport.isNotEmpty) ...[
            _buildSectionTitle('Customer Report'),
            pw.SizedBox(height: 8),
            _buildCustomerTable(customerReport, currencyFormat),
          ],
        ],
      ),
    );

    return pdf;
  }

  /// Build report header
  static pw.Widget _buildHeader(DateFormat dateFormat, DateTime startDate, DateTime endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Stock & Sales Management',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Report',
              style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Date: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 2, color: PdfColors.indigo),
        pw.SizedBox(height: 12),
      ],
    );
  }

  /// Build report footer with page numbers
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  /// Build section title
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.indigo900,
        ),
      ),
    );
  }

  /// Build sales summary table
  static pw.Widget _buildSummaryTable(
    Map<String, dynamic> salesSummary,
    Map<String, dynamic> purchaseSummary,
    double profit,
    NumberFormat currencyFormat,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        _buildTableRow('Total Sales', '${salesSummary['total_sales'] ?? 0} orders', isHeader: false),
        _buildTableRow('Sales Revenue', '${currencyFormat.format(salesSummary['total_revenue'] ?? 0)} Baht'),
        _buildTableRow('Total Purchase Orders', '${purchaseSummary['total_orders'] ?? 0} orders'),
        _buildTableRow('Purchase Cost', '${currencyFormat.format(purchaseSummary['total_cost'] ?? 0)} Baht'),
        _buildTableRow(
          'Estimated Profit',
          '${currencyFormat.format(profit)} Baht',
          valueColor: profit >= 0 ? PdfColors.green700 : PdfColors.red700,
        ),
      ],
    );
  }

  /// Build a table row
  static pw.TableRow _buildTableRow(String label, String value, {bool isHeader = false, PdfColor? valueColor}) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: isHeader ? PdfColors.indigo100 : null,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isHeader ? pw.FontWeight.bold : null,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Build top products table
  static pw.Widget _buildTopProductsTable(List<Map<String, dynamic>> products, NumberFormat currencyFormat) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(6),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      headers: ['#', 'Product Name', 'Qty Sold', 'Revenue (Baht)'],
      data: products.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        return [
          '${i + 1}',
          p['name']?.toString() ?? '-',
          '${p['total_sold'] ?? 0}',
          currencyFormat.format(p['total_revenue'] ?? 0),
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(3),
      },
    );
  }

  /// Build category report table
  static pw.Widget _buildCategoryTable(List<Map<String, dynamic>> categories, NumberFormat currencyFormat) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(6),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      headers: ['Category', 'Products', 'Stock', 'Value (Baht)'],
      data: categories.map((cat) {
        return [
          cat['name']?.toString() ?? '-',
          '${cat['product_count'] ?? 0}',
          '${cat['total_stock'] ?? 0}',
          currencyFormat.format(cat['total_value'] ?? 0),
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(3),
      },
    );
  }

  /// Build customer report table
  static pw.Widget _buildCustomerTable(List<Map<String, dynamic>> customers, NumberFormat currencyFormat) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(6),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      headers: ['Customer', 'Orders', 'Total Spent (Baht)'],
      data: customers.map((cust) {
        return [
          cust['name']?.toString() ?? '-',
          '${cust['total_orders'] ?? 0}',
          currencyFormat.format(cust['total_spent'] ?? 0),
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
      },
    );
  }
}
