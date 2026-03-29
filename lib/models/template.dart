import 'package:flutter/material.dart';

class InvoiceTemplate {
  final String id;
  final String name;
  final String description;
  final TemplateStyles styles;
  final TemplateLabels labels;
  final Map<String, bool> features;

  InvoiceTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.styles,
    required this.labels,
    this.features = const <String, bool>{},
  });

  factory InvoiceTemplate.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      styles: TemplateStyles.fromJson(json['styles'] as Map<String, dynamic>),
      labels: TemplateLabels.fromJson(json['labels'] as Map<String, dynamic>),
      features:
          (json['features'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool? ?? false),
          ) ??
          <String, bool>{},
    );
  }
}

class TemplateStyles {
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final Color tableHeaderColor;
  final Color tableHeaderTextColor;
  final Color tableSubHeaderColor;
  final Color footerBackgroundColor;
  final Color borderColor;

  TemplateStyles({
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.tableHeaderColor,
    required this.tableHeaderTextColor,
    required this.tableSubHeaderColor,
    required this.footerBackgroundColor,
    required this.borderColor,
  });

  factory TemplateStyles.fromJson(Map<String, dynamic> json) {
    return TemplateStyles(
      primaryColor: _hexToColor(json['primaryColor'] as String),
      secondaryColor: _hexToColor(json['secondaryColor'] as String),
      textColor: _hexToColor(json['textColor'] as String),
      tableHeaderColor: _hexToColor(json['tableHeaderColor'] as String),
      tableHeaderTextColor: _hexToColor(json['tableHeaderTextColor'] as String),
      tableSubHeaderColor: _hexToColor(json['tableSubHeaderColor'] as String),
      footerBackgroundColor: _hexToColor(
        json['footerBackgroundColor'] as String,
      ),
      borderColor: _hexToColor(json['borderColor'] as String),
    );
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  // To allow overriding colors
  TemplateStyles copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? textColor,
    Color? tableHeaderColor,
    Color? tableHeaderTextColor,
    Color? tableSubHeaderColor,
    Color? footerBackgroundColor,
    Color? borderColor,
  }) {
    return TemplateStyles(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      textColor: textColor ?? this.textColor,
      tableHeaderColor: tableHeaderColor ?? this.tableHeaderColor,
      tableHeaderTextColor: tableHeaderTextColor ?? this.tableHeaderTextColor,
      tableSubHeaderColor: tableSubHeaderColor ?? this.tableSubHeaderColor,
      footerBackgroundColor:
          footerBackgroundColor ?? this.footerBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}

class TemplateLabels {
  final String title;
  final String businessDetails;
  final String consigneeDetailsTitle;
  final String invoiceNo;
  final String dated;
  final String termsOfPayment;
  final String dueDate;
  final String tableDescription;
  final String tableHsn;
  final String tableQty;
  final String tableRate;
  final String tableTotal;
  final String totalAmount;
  final String amountInWords;
  final String declaration;
  final String bankDetails;
  final String authorizedSignatory;

  TemplateLabels({
    required this.title,
    required this.businessDetails,
    required this.consigneeDetailsTitle,
    required this.invoiceNo,
    required this.dated,
    required this.termsOfPayment,
    required this.dueDate,
    required this.tableDescription,
    required this.tableHsn,
    required this.tableQty,
    required this.tableRate,
    required this.tableTotal,
    required this.totalAmount,
    required this.amountInWords,
    required this.declaration,
    required this.bankDetails,
    required this.authorizedSignatory,
  });

  factory TemplateLabels.fromJson(Map<String, dynamic> json) {
    return TemplateLabels(
      title: json['title'] ?? 'ESTIMATE',
      businessDetails: json['businessDetails'] ?? 'Business Details',
      consigneeDetailsTitle:
          json['consigneeDetailsTitle'] ?? 'CONSIGNEE DETAILS',
      invoiceNo: json['invoiceNo'] ?? 'Invoice No.',
      dated: json['dated'] ?? 'Dated',
      termsOfPayment: json['termsOfPayment'] ?? 'Terms of Payment',
      dueDate: json['dueDate'] ?? 'Due Date',
      tableDescription: json['tableDescription'] ?? 'Description of Goods',
      tableHsn: json['tableHsn'] ?? 'HSN Code',
      tableQty: json['tableQty'] ?? 'Qty',
      tableRate: json['tableRate'] ?? 'Unit Price',
      tableTotal: json['tableTotal'] ?? 'Total',
      totalAmount: json['totalAmount'] ?? 'Total Amount',
      amountInWords: json['amountInWords'] ?? 'Amount Chargeable (in words):',
      declaration: json['declaration'] ?? 'Declaration:',
      bankDetails: json['bankDetails'] ?? 'Bank Details:',
      authorizedSignatory:
          json['authorizedSignatory'] ?? 'Authorised Signatory',
    );
  }

  Map<String, String> toMap() {
    return {
      'title': title,
      'businessDetails': businessDetails,
      'consigneeDetailsTitle': consigneeDetailsTitle,
      'invoiceNo': invoiceNo,
      'dated': dated,
      'termsOfPayment': termsOfPayment,
      'dueDate': dueDate,
      'tableDescription': tableDescription,
      'tableHsn': tableHsn,
      'tableQty': tableQty,
      'tableRate': tableRate,
      'tableTotal': tableTotal,
      'totalAmount': totalAmount,
      'amountInWords': amountInWords,
      'declaration': declaration,
      'bankDetails': bankDetails,
      'authorizedSignatory': authorizedSignatory,
    };
  }

  TemplateLabels copyWith({
    String? title,
    String? businessDetails,
    String? consigneeDetailsTitle,
    String? invoiceNo,
    String? dated,
    String? termsOfPayment,
    String? dueDate,
    String? tableDescription,
    String? tableHsn,
    String? tableQty,
    String? tableRate,
    String? tableTotal,
    String? totalAmount,
    String? amountInWords,
    String? declaration,
    String? bankDetails,
    String? authorizedSignatory,
  }) {
    return TemplateLabels(
      title: title ?? this.title,
      businessDetails: businessDetails ?? this.businessDetails,
      consigneeDetailsTitle:
          consigneeDetailsTitle ?? this.consigneeDetailsTitle,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      dated: dated ?? this.dated,
      termsOfPayment: termsOfPayment ?? this.termsOfPayment,
      dueDate: dueDate ?? this.dueDate,
      tableDescription: tableDescription ?? this.tableDescription,
      tableHsn: tableHsn ?? this.tableHsn,
      tableQty: tableQty ?? this.tableQty,
      tableRate: tableRate ?? this.tableRate,
      tableTotal: tableTotal ?? this.tableTotal,
      totalAmount: totalAmount ?? this.totalAmount,
      amountInWords: amountInWords ?? this.amountInWords,
      declaration: declaration ?? this.declaration,
      bankDetails: bankDetails ?? this.bankDetails,
      authorizedSignatory: authorizedSignatory ?? this.authorizedSignatory,
    );
  }
}
