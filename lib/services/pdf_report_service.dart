import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Service for generating PDF reports with Thai language support
class PdfReportService {
  /// Load Sarabun Thai font
  static Future<pw.Font> _loadFont(String assetPath) async {
    final fontData = await rootBundle.load(assetPath);
    return pw.Font.ttf(fontData);
  }

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
    // Load Thai fonts
    final regularFont = await _loadFont('assets/fonts/Sarabun-Regular.ttf');
    final boldFont = await _loadFont('assets/fonts/Sarabun-Bold.ttf');

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat('#,##0.00');

    final totalRevenue = (salesSummary['total_revenue'] ?? 0).toDouble();
    final totalCost = (purchaseSummary['total_cost'] ?? 0).toDouble();
    final profit = totalRevenue - totalCost;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(dateFormat, startDate, endDate, boldFont, regularFont),
        footer: (context) => _buildFooter(context, regularFont),
        build: (context) => [
          // Sales Summary Section
          _buildSectionTitle('สรุปยอดขาย', boldFont),
          pw.SizedBox(height: 8),
          _buildSummaryTable(salesSummary, purchaseSummary, profit, currencyFormat, regularFont, boldFont),
          pw.SizedBox(height: 24),

          // Top Products Section
          if (topProducts.isNotEmpty) ...[
            _buildSectionTitle('สินค้าขายดี', boldFont),
            pw.SizedBox(height: 8),
            _buildTopProductsTable(topProducts, currencyFormat, regularFont, boldFont),
            pw.SizedBox(height: 24),
          ],

          // Category Report Section
          if (categoryReport.isNotEmpty) ...[
            _buildSectionTitle('รายงานตามประเภทสินค้า', boldFont),
            pw.SizedBox(height: 8),
            _buildCategoryTable(categoryReport, currencyFormat, regularFont, boldFont),
            pw.SizedBox(height: 24),
          ],

          // Customer Report Section
          if (customerReport.isNotEmpty) ...[
            _buildSectionTitle('รายงานลูกค้า', boldFont),
            pw.SizedBox(height: 8),
            _buildCustomerTable(customerReport, currencyFormat, regularFont, boldFont),
          ],
        ],
      ),
    );

    return pdf;
  }

  /// Build report header
  static pw.Widget _buildHeader(DateFormat dateFormat, DateTime startDate, DateTime endDate, pw.Font boldFont, pw.Font regularFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ระบบจัดการสต๊อกและขาย',
              style: pw.TextStyle(font: boldFont, fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'รายงาน',
              style: pw.TextStyle(font: regularFont, fontSize: 16, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'ช่วงวันที่: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
          style: pw.TextStyle(font: regularFont, fontSize: 11, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 2, color: PdfColors.indigo),
        pw.SizedBox(height: 12),
      ],
    );
  }

  /// Build report footer with page numbers
  static pw.Widget _buildFooter(pw.Context context, pw.Font regularFont) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'สร้างเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey500),
            ),
            pw.Text(
              'หน้า ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  /// Build section title
  static pw.Widget _buildSectionTitle(String title, pw.Font boldFont) {
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
          font: boldFont,
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
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        _buildTableRow('จำนวนรายการขาย', '${salesSummary['total_sales'] ?? 0} รายการ', regularFont, boldFont),
        _buildTableRow('ยอดขายรวม', '฿${currencyFormat.format(salesSummary['total_revenue'] ?? 0)}', regularFont, boldFont),
        _buildTableRow('จำนวนใบสั่งซื้อ', '${purchaseSummary['total_orders'] ?? 0} รายการ', regularFont, boldFont),
        _buildTableRow('ยอดสั่งซื้อรวม', '฿${currencyFormat.format(purchaseSummary['total_cost'] ?? 0)}', regularFont, boldFont),
        _buildTableRow(
          'กำไร (ประมาณ)',
          '฿${currencyFormat.format(profit)}',
          regularFont,
          boldFont,
          valueColor: profit >= 0 ? PdfColors.green700 : PdfColors.red700,
        ),
      ],
    );
  }

  /// Build a table row
  static pw.TableRow _buildTableRow(String label, String value, pw.Font regularFont, pw.Font boldFont, {PdfColor? valueColor}) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(font: regularFont, fontSize: 11)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
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
  static pw.Widget _buildTopProductsTable(List<Map<String, dynamic>> products, NumberFormat currencyFormat, pw.Font regularFont, pw.Font boldFont) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(6),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      headers: ['อันดับ', 'ชื่อสินค้า', 'จำนวนขาย', 'รายได้ (฿)'],
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
  static pw.Widget _buildCategoryTable(List<Map<String, dynamic>> categories, NumberFormat currencyFormat, pw.Font regularFont, pw.Font boldFont) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(6),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      headers: ['ประเภท', 'จำนวนสินค้า', 'สต๊อก', 'มูลค่า (฿)'],
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
  static pw.Widget _buildCustomerTable(List<Map<String, dynamic>> customers, NumberFormat currencyFormat, pw.Font regularFont, pw.Font boldFont) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(6),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      headers: ['ชื่อลูกค้า', 'คำสั่งซื้อ', 'ยอดซื้อรวม (฿)'],
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
