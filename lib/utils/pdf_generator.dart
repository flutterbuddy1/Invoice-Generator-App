import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../models/business_profile.dart';
import '../models/invoice.dart';
import '../models/template.dart';
import 'number_to_words.dart';

class PdfGenerator {
  static Future<Uint8List> generate(
    Invoice invoice,
    BusinessProfile profile, {
    required TemplateStyles styles,
    required TemplateLabels labels,
    required Map<String, bool> features,
  }) async {
    final pdf = pw.Document();
    try {
      final image = _tryLoadImage(profile.logoPath);
      final signature = _tryLoadImage(profile.signaturePath);

      // Use standard fonts to avoid network dependency issues
      final font = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      pdf.addPage(
        pw.MultiPage(
          margin: pw.EdgeInsets.all(30),
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (pw.Context context) {
            return [
              _buildTitle(styles, labels),
              _buildHeaderSection(
                invoice,
                profile,
                image,
                styles,
                labels,
                features,
              ),
              _buildConsigneeSection(invoice, styles, labels, features),
              _buildItemsTable(invoice, styles, labels, features),
              _buildFooterSection(
                invoice,
                profile,
                signature,
                styles,
                labels,
                features,
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      final errorPdf = pw.Document();
      errorPdf.addPage(
        pw.Page(
          build: (context) =>
              pw.Center(child: pw.Text('Error generating PDF: $e')),
        ),
      );
      return errorPdf.save();
    }
  }

  /// Generate a single PDF document containing multiple invoices
  /// Invoices will be sorted by date (oldest first)
  static Future<Uint8List> generateMultiple(
    List<Invoice> invoices,
    BusinessProfile profile, {
    required TemplateStyles styles,
    required TemplateLabels labels,
    required Map<String, bool> features,
  }) async {
    final pdf = pw.Document();

    try {
      // Sort invoices by date (oldest first)
      final sortedInvoices = List<Invoice>.from(invoices)
        ..sort((a, b) => a.date.compareTo(b.date));

      final image = _tryLoadImage(profile.logoPath);
      final signature = _tryLoadImage(profile.signaturePath);

      // Use standard fonts
      final font = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      // Add each invoice as separate pages
      for (final invoice in sortedInvoices) {
        pdf.addPage(
          pw.MultiPage(
            margin: pw.EdgeInsets.all(30),
            pageFormat: PdfPageFormat.a4,
            theme: pw.ThemeData.withFont(base: font, bold: boldFont),
            build: (pw.Context context) {
              return [
                _buildTitle(styles, labels),
                _buildHeaderSection(
                  invoice,
                  profile,
                  image,
                  styles,
                  labels,
                  features,
                ),
                _buildConsigneeSection(invoice, styles, labels, features),
                _buildItemsTable(invoice, styles, labels, features),
                _buildFooterSection(
                  invoice,
                  profile,
                  signature,
                  styles,
                  labels,
                  features,
                ),
              ];
            },
          ),
        );
      }

      return pdf.save();
    } catch (e) {
      final errorPdf = pw.Document();
      errorPdf.addPage(
        pw.Page(
          build: (context) =>
              pw.Center(child: pw.Text('Error generating merged PDF: $e')),
        ),
      );
      return errorPdf.save();
    }
  }

  static pw.MemoryImage? _tryLoadImage(String? path) {
    if (path == null) return null;
    try {
      final file = File(path);
      if (file.existsSync()) {
        return pw.MemoryImage(file.readAsBytesSync());
      }
    } catch (e) {
      // Silently fail if image cannot be loaded
      return null;
    }
    return null;
  }

  static pw.Widget _buildTitle(TemplateStyles styles, TemplateLabels labels) {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColor.fromInt(styles.borderColor.value),
        ),
      ),
      child: pw.Text(
        labels.title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 16,
          color: PdfColor.fromInt(styles.textColor.value),
        ),
      ),
    );
  }

  static pw.Widget _buildHeaderSection(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? image,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Business Details
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.businessName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    profile.address,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Ph: ${profile.phone}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                  if (features['showCustomerGstin'] ?? true)
                    pw.Text(
                      'GSTIN: ${profile.gstin}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Middle: Invoice Details
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Column(
                children: [
                  _buildHeaderRow(
                    labels.invoiceNo,
                    invoice.invoiceNumber,
                    styles,
                  ),
                  _buildHeaderRow(
                    labels.dated,
                    DateFormat('dd.MM.yyyy').format(invoice.date),
                    styles,
                  ),
                  if (features['showPaymentTerms'] ?? true)
                    _buildHeaderRow(
                      labels.termsOfPayment,
                      invoice.termsOfPayment,
                      styles,
                    ),
                  if (features['showDueDate'] ?? true)
                    _buildHeaderRow(
                      labels.dueDate,
                      DateFormat('dd.MM.yyyy').format(invoice.dueDate),
                      styles,
                    ),
                ],
              ),
            ),
          ),
          // Right: Logo
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              alignment: pw.Alignment.center,
              height: 100,
              child: image != null
                  ? pw.Image(image, fit: pw.BoxFit.contain)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderRow(
    String label,
    String value,
    TemplateStyles styles,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide()),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
            ),
          ),
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildConsigneeSection(
    Invoice invoice,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Consignee Details
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    labels.consigneeDetailsTitle,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 10,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.Text(
                    invoice.clientName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    invoice.clientAddress,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if ((features['showCustomerGstin'] ?? true) &&
                      invoice.customerGSTIN.isNotEmpty)
                    pw.Text(
                      'GSTIN: ${invoice.customerGSTIN}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Right: Transport Details
          if (features['showTransportFields'] ?? true)
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                children: [
                  _buildHeaderRow(
                    'Terms of Delivery',
                    invoice.termsOfDelivery,
                    styles,
                  ),
                  _buildHeaderRow(
                    'Transport Mode',
                    invoice.transportMode,
                    styles,
                  ),
                  _buildHeaderRow('Vehicle No.', invoice.vehicleNumber, styles),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    Invoice invoice,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) {
    final showHsn = features['showHsn'] ?? true;
    final showGst = features['showGst'] ?? true;

    // Dynamic column widths
    final Map<int, pw.TableColumnWidth> columnWidths = {
      0: const pw.FlexColumnWidth(3), // Desc
    };

    int colIndex = 1;
    if (showHsn) columnWidths[colIndex++] = const pw.FlexColumnWidth(1); // HSN
    columnWidths[colIndex++] = const pw.FlexColumnWidth(0.8); // Qty
    columnWidths[colIndex++] = const pw.FlexColumnWidth(1.2); // Rate
    columnWidths[colIndex++] = const pw.FlexColumnWidth(1.2); // Total (Base)

    if (showGst) {
      columnWidths[colIndex++] = const pw.FlexColumnWidth(1.5); // IGST
      columnWidths[colIndex++] = const pw.FlexColumnWidth(1.5); // SGST
      columnWidths[colIndex++] = const pw.FlexColumnWidth(1.5); // CGST
    }

    // Final Total Column
    columnWidths[colIndex++] = const pw.FlexColumnWidth(1.5);

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: columnWidths,
      children: [
        // Header Row 1 (Main Headers)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(styles.tableHeaderColor.value),
          ),
          children: [
            _buildTableHeader(labels.tableDescription, styles),
            if (showHsn) _buildTableHeader(labels.tableHsn, styles),
            _buildTableHeader(labels.tableQty, styles),
            _buildTableHeader(labels.tableRate, styles),
            _buildTableHeader(
              showGst ? 'Taxable Value' : labels.tableTotal,
              styles,
            ),
            if (showGst) ...[
              _buildTableHeader('IGST', styles),
              _buildTableHeader('SGST', styles),
              _buildTableHeader('CGST', styles),
            ],
            if (showGst) _buildTableHeader(labels.tableTotal, styles),
          ],
        ),
        // Header Row 2 (Sub-headers for Taxes) - Only if GST is enabled
        if (showGst)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(styles.tableSubHeaderColor.value),
            ),
            children: [
              pw.Container(), // Desc
              if (showHsn) pw.Container(), // HSN
              pw.Container(), // Qty
              pw.Container(), // Rate
              pw.Container(), // Total
              _buildSubHeader('Rate | Amt', styles), // IGST
              _buildSubHeader('Rate | Amt', styles), // SGST
              _buildSubHeader('Rate | Amt', styles), // CGST
              pw.Container(), // Total
            ],
          ),
        // Data Rows
        ...invoice.items.map((item) {
          final baseTotal = item.quantity * item.unitPrice;
          final taxAmount = item.total - baseTotal;

          double igstRate = 0, igstAmt = 0;
          double sgstRate = 0, sgstAmt = 0;
          double cgstRate = 0, cgstAmt = 0;

          if (invoice.isIGST) {
            igstRate = item.gstRate;
            igstAmt = taxAmount;
          } else {
            sgstRate = item.gstRate / 2;
            sgstAmt = taxAmount / 2;
            cgstRate = item.gstRate / 2;
            cgstAmt = taxAmount / 2;
          }

          return pw.TableRow(
            children: [
              _buildTableCell(item.description, align: pw.TextAlign.left),
              if (showHsn) _buildTableCell(item.hsnCode),
              _buildTableCell('${item.quantity}'),
              _buildTableCell(item.unitPrice.toStringAsFixed(2)),
              _buildTableCell(baseTotal.toStringAsFixed(2)),
              if (showGst) ...[
                _buildTableCell(
                  '${igstRate.toStringAsFixed(0)}% | ${igstAmt.toStringAsFixed(2)}',
                ),
                _buildTableCell(
                  '${sgstRate.toStringAsFixed(0)}% | ${sgstAmt.toStringAsFixed(2)}',
                ),
                _buildTableCell(
                  '${cgstRate.toStringAsFixed(0)}% | ${cgstAmt.toStringAsFixed(2)}',
                ),
              ],
              if (showGst) _buildTableCell(item.total.toStringAsFixed(2)),
            ],
          );
        }),
        // Empty rows filler
        for (int i = 0; i < (8 - invoice.items.length).clamp(0, 8); i++)
          pw.TableRow(
            children: List.generate(
              colIndex,
              (index) => pw.Container(height: 20),
            ),
          ),
        // Total Row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(styles.footerBackgroundColor.value),
          ),
          children: [
            _buildTableCell('Total', isBold: true),
            if (showHsn) pw.Container(),
            _buildTableCell(
              invoice.items
                  .fold<int>(0, (sum, item) => sum + item.quantity)
                  .toString(),
              isBold: true,
            ),
            pw.Container(), // Rate
            _buildTableCell(
              invoice.items
                  .fold<double>(
                    0,
                    (sum, item) => sum + (item.quantity * item.unitPrice),
                  )
                  .toStringAsFixed(2),
              isBold: true,
            ),
            if (showGst) ...[
              _buildTableCell(
                invoice.isIGST
                    ? (invoice.totalAmount -
                              invoice.items.fold<double>(
                                0,
                                (sum, item) =>
                                    sum + (item.quantity * item.unitPrice),
                              ))
                          .toStringAsFixed(2)
                    : '-',
                isBold: true,
              ),
              _buildTableCell(
                !invoice.isIGST
                    ? ((invoice.totalAmount -
                                  invoice.items.fold<double>(
                                    0,
                                    (sum, item) =>
                                        sum + (item.quantity * item.unitPrice),
                                  )) /
                              2)
                          .toStringAsFixed(2)
                    : '-',
                isBold: true,
              ),
              _buildTableCell(
                !invoice.isIGST
                    ? ((invoice.totalAmount -
                                  invoice.items.fold<double>(
                                    0,
                                    (sum, item) =>
                                        sum + (item.quantity * item.unitPrice),
                                  )) /
                              2)
                          .toStringAsFixed(2)
                    : '-',
                isBold: true,
              ),
            ],
            if (showGst)
              _buildTableCell(
                invoice.totalAmount.toStringAsFixed(2),
                isBold: true,
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, TemplateStyles styles) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColor.fromInt(styles.tableHeaderTextColor.value),
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildSubHeader(String text, TemplateStyles styles) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildFooterSection(
    Invoice invoice,
    BusinessProfile profile,
    pw.MemoryImage? signature,
    TemplateStyles styles,
    TemplateLabels labels,
    Map<String, bool> features,
  ) {
    final totalInWords = NumberToWords.convert(invoice.totalAmount.toInt());
    final baseTotal = invoice.items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final totalTax = invoice.totalAmount - baseTotal;
    final showGst = features['showGst'] ?? true;

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Amount in words & Declaration
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide()),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    labels.amountInWords,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    '$totalInWords Only',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    labels.declaration,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  if (profile.bankName != null &&
                      profile.bankName!.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Bank Details:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Bank: ${profile.bankName}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'A/c No: ${profile.accountNumber}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'IFSC: ${profile.ifscCode}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Branch: ${profile.branchName}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Right: Totals & Signature
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              children: [
                _buildFooterRow(
                  labels
                      .totalAmount, // Usually 'Total Amount' before tax or 'Sub Total'
                  baseTotal.toStringAsFixed(2),
                  styles,
                ),
                if (showGst) ...[
                  if (invoice.isIGST)
                    _buildFooterRow(
                      'Add: IGST',
                      totalTax.toStringAsFixed(2),
                      styles,
                    )
                  else ...[
                    _buildFooterRow(
                      'Add: SGST',
                      (totalTax / 2).toStringAsFixed(2),
                      styles,
                    ),
                    _buildFooterRow(
                      'Add: CGST',
                      (totalTax / 2).toStringAsFixed(2),
                      styles,
                    ),
                  ],
                ],
                _buildFooterRow('Round OFF', '-', styles),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide()),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Grand Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        invoice.totalAmount.toStringAsFixed(2),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  height: 80,
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.bottomCenter,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      if (signature != null)
                        pw.Container(
                          height: 40,
                          child: pw.Image(signature, fit: pw.BoxFit.contain),
                        ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Authorised Signatory',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterRow(
    String label,
    String value,
    TemplateStyles styles,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide()),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
