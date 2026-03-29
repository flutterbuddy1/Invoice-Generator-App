import 'dart:convert';
import '../models/template.dart';

final List<String> defaultTemplatesJson = [
  // Car Service
  '''{
    "id": "car_service",
    "name": "Car Service / Auto",
    "description": "Professional invoice for automotive repairs and services.",
    "styles": {
      "primaryColor": "4A148C",
      "secondaryColor": "E1BEE7",
      "textColor": "000000",
      "tableHeaderColor": "4A148C",
      "tableHeaderTextColor": "FFFFFF",
      "tableSubHeaderColor": "E1BEE7",
      "footerBackgroundColor": "EEEEEE",
      "borderColor": "000000"
    },
    "features": {
      "showTransportFields": true,
      "showPaymentTerms": true,
      "showCustomerGstin": true,
      "showHsn": true,
      "showGst": true,
      "showDueDate": true
    },
    "labels": {
      "title": "TAX INVOICE",
      "businessDetails": "Service Center Details",
      "consigneeDetailsTitle": "CUSTOMER DETAILS",
      "invoiceNo": "Invoice No.",
      "dated": "Date",
      "termsOfPayment": "Payment Mode",
      "dueDate": "Due Date",
      "tableDescription": "Service / Part Description",
      "tableHsn": "SAC/HSN",
      "tableQty": "Qty",
      "tableRate": "Rate",
      "tableTotal": "Amount",
      "totalAmount": "Grand Total",
      "amountInWords": "Amount in words:",
      "declaration": "Terms & Conditions:",
      "bankDetails": "Bank Details:",
      "authorizedSignatory": "For Service Center"
    }
  }''',

  // Freelancer
  '''{
    "id": "freelancer",
    "name": "Freelancer / Creative",
    "description": "Clean and modern design for freelancers and creative professionals.",
    "styles": {
      "primaryColor": "00796B",
      "secondaryColor": "B2DFDB",
      "textColor": "212121",
      "tableHeaderColor": "00796B",
      "tableHeaderTextColor": "FFFFFF",
      "tableSubHeaderColor": "E0F2F1",
      "footerBackgroundColor": "F5F5F5",
      "borderColor": "BDBDBD"
    },
    "features": {
      "showTransportFields": false,
      "showPaymentTerms": true,
      "showCustomerGstin": false,
      "showHsn": false,
      "showGst": true,
      "showDueDate": true
    },
    "labels": {
      "title": "INVOICE",
      "businessDetails": "Freelancer Details",
      "consigneeDetailsTitle": "BILL TO",
      "invoiceNo": "Invoice #",
      "dated": "Date of Issue",
      "termsOfPayment": "Payment Terms",
      "dueDate": "Due Date",
      "tableDescription": "Service Description",
      "tableHsn": "Code",
      "tableQty": "Hours/Qty",
      "tableRate": "Rate",
      "tableTotal": "Subtotal",
      "totalAmount": "Total Amount",
      "amountInWords": "Total in words:",
      "declaration": "Notes:",
      "bankDetails": "Payment Info:",
      "authorizedSignatory": "Signature"
    }
  }''',

  // Retail
  '''{
    "id": "retail",
    "name": "Retail / General Store",
    "description": "Standard invoice for retail shops and grocery stores.",
    "styles": {
      "primaryColor": "1976D2",
      "secondaryColor": "BBDEFB",
      "textColor": "212121",
      "tableHeaderColor": "1976D2",
      "tableHeaderTextColor": "FFFFFF",
      "tableSubHeaderColor": "E3F2FD",
      "footerBackgroundColor": "F5F5F5",
      "borderColor": "1976D2"
    },
    "features": {
      "showTransportFields": true,
      "showPaymentTerms": true,
      "showCustomerGstin": true,
      "showHsn": true,
      "showGst": true,
      "showDueDate": true
    },
    "labels": {
      "title": "CASH MEMO",
      "businessDetails": "Store Details",
      "consigneeDetailsTitle": "CUSTOMER DETAILS",
      "invoiceNo": "Bill No.",
      "dated": "Date",
      "termsOfPayment": "Payment",
      "dueDate": "Due Date",
      "tableDescription": "Product Description",
      "tableHsn": "HSN",
      "tableQty": "Qty",
      "tableRate": "Rate",
      "tableTotal": "Total",
      "totalAmount": "Bill Total",
      "amountInWords": "Rupees in words:",
      "declaration": "Terms & Conditions:",
      "bankDetails": "G-Pay/PhonePe:",
      "authorizedSignatory": "Proprietor"
    }
  }''',

  // Medical
  '''{
    "id": "medical",
    "name": "Medical / Pharmacy",
    "description": "Professional medical bill for doctors and pharmacies.",
    "styles": {
      "primaryColor": "C62828",
      "secondaryColor": "FFCDD2",
      "textColor": "212121",
      "tableHeaderColor": "C62828",
      "tableHeaderTextColor": "FFFFFF",
      "tableSubHeaderColor": "FFEBEE",
      "footerBackgroundColor": "FAFAFA",
      "borderColor": "C62828"
    },
    "features": {
      "showTransportFields": false,
      "showPaymentTerms": false,
      "showCustomerGstin": false,
      "showHsn": true,
      "showGst": true,
      "showDueDate": false
    },
    "labels": {
      "title": "PRESCRIPTION BILL",
      "businessDetails": "Hospital / Clinic Details",
      "consigneeDetailsTitle": "PATIENT DETAILS",
      "invoiceNo": "Ref No.",
      "dated": "Date",
      "termsOfPayment": "Mode",
      "dueDate": "Valid Till",
      "tableDescription": "Description of Medicines/Service",
      "tableHsn": "Batch",
      "tableQty": "Qty",
      "tableRate": "Rate",
      "tableTotal": "Amount",
      "totalAmount": "Total Bill",
      "amountInWords": "Amount in words:",
      "declaration": "Medical Disclaimer:",
      "bankDetails": "Insurance Info:",
      "authorizedSignatory": "Physician / Pharmacist"
    }
  }''',

  // IT Services
  '''{
    "id": "it_services",
    "name": "IT / Software Services",
    "description": "Modern design for software development and IT consultancies.",
    "styles": {
      "primaryColor": "0D47A1",
      "secondaryColor": "E3F2FD",
      "textColor": "0D47A1",
      "tableHeaderColor": "0D47A1",
      "tableHeaderTextColor": "FFFFFF",
      "tableSubHeaderColor": "BBDEFB",
      "footerBackgroundColor": "F5F9FF",
      "borderColor": "1976D2"
    },
    "features": {
      "showTransportFields": false,
      "showPaymentTerms": true,
      "showCustomerGstin": true,
      "showHsn": false,
      "showGst": true,
      "showDueDate": true
    },
    "labels": {
      "title": "SERVICE INVOICE",
      "businessDetails": "Company Details",
      "consigneeDetailsTitle": "CLIENT DETAILS",
      "invoiceNo": "Project ID / Inv #",
      "dated": "Issue Date",
      "termsOfPayment": "Project Phase",
      "dueDate": "Due Date",
      "tableDescription": "Task / Deliverable",
      "tableHsn": "SKU",
      "tableQty": "Hrs/Units",
      "tableRate": "Price",
      "tableTotal": "Total",
      "totalAmount": "Total Payable",
      "amountInWords": "Amount in words:",
      "declaration": "Service Level Agreement:",
      "bankDetails": "Wire Transfer Details:",
      "authorizedSignatory": "Operations Head"
    }
  }''',

  // Real Estate
  '''{
    "id": "real_estate",
    "name": "Real Estate / Logistics",
    "description": "Professional bill for property and logistics services.",
    "styles": {
      "primaryColor": "37474F",
      "secondaryColor": "CFD8DC",
      "textColor": "263238",
      "tableHeaderColor": "37474F",
      "tableHeaderTextColor": "FFFFFF",
      "tableSubHeaderColor": "ECEFF1",
      "footerBackgroundColor": "F9FBFB",
      "borderColor": "455A64"
    },
    "features": {
      "showTransportFields": true,
      "showPaymentTerms": true,
      "showCustomerGstin": true,
      "showHsn": true,
      "showGst": true,
      "showDueDate": true
    },
    "labels": {
      "title": "RENT / SERVICE BILL",
      "businessDetails": "Agent / Company Details",
      "consigneeDetailsTitle": "TENANT / CLIENT",
      "invoiceNo": "Property Ref #",
      "dated": "Date",
      "termsOfPayment": "Period",
      "dueDate": "Last Date",
      "tableDescription": "Description of Charges",
      "tableHsn": "SAC",
      "tableQty": "Area/Qty",
      "tableRate": "Rate",
      "tableTotal": "Total",
      "totalAmount": "Grand Total",
      "amountInWords": "Amount in words:",
      "declaration": "Terms & Conditions:",
      "bankDetails": "Bank Details:",
      "authorizedSignatory": "Authorized Signatory"
    }
  }''',

  // Minimalist
  '''{
    "id": "minimalist",
    "name": "Minimalist / Basic",
    "description": "Simple black and white design for a clean look.",
    "styles": {
      "primaryColor": "000000",
      "secondaryColor": "EEEEEE",
      "textColor": "000000",
      "tableHeaderColor": "000000",
      "tableHeaderTextColor": "FFFFFF",
      "tableSubHeaderColor": "F5F5F5",
      "footerBackgroundColor": "FFFFFF",
      "borderColor": "000000"
    },
    "features": {
      "showTransportFields": false,
      "showPaymentTerms": true,
      "showCustomerGstin": true,
      "showHsn": true,
      "showGst": true,
      "showDueDate": true
    },
    "labels": {
      "title": "INVOICE",
      "businessDetails": "From",
      "consigneeDetailsTitle": "To",
      "invoiceNo": "Invoice No.",
      "dated": "Date",
      "termsOfPayment": "Terms",
      "dueDate": "Due Date",
      "tableDescription": "Item",
      "tableHsn": "HSN",
      "tableQty": "Qty",
      "tableRate": "Price",
      "tableTotal": "Total",
      "totalAmount": "Total",
      "amountInWords": "Amount in words:",
      "declaration": "Terms:",
      "bankDetails": "Bank:",
      "authorizedSignatory": "Authorized"
    }
  }''',

  // Custom Builder
  '''{
    "id": "custom",
    "name": "Custom Builder",
    "description": "Start with a clean slate and design your own matching your brand.",
    "styles": {
      "primaryColor": "2196F3",
      "secondaryColor": "BBDEFB",
      "textColor": "212121",
      "tableHeaderColor": "2196F3",
      "tableHeaderTextColor": "FFFFFF",
      "tableSubHeaderColor": "E3F2FD",
      "footerBackgroundColor": "F5F5F5",
      "borderColor": "2196F3"
    },
    "features": {
      "showTransportFields": true,
      "showPaymentTerms": true,
      "showCustomerGstin": true,
      "showHsn": true,
      "showGst": true,
      "showDueDate": true
    },
    "labels": {
      "title": "INVOICE",
      "businessDetails": "Business Details",
      "consigneeDetailsTitle": "BILL TO",
      "invoiceNo": "Invoice No.",
      "dated": "Date",
      "termsOfPayment": "Terms",
      "dueDate": "Due Date",
      "tableDescription": "Description",
      "tableHsn": "HSN/SAC",
      "tableQty": "Qty",
      "tableRate": "Price",
      "tableTotal": "Total",
      "totalAmount": "Total Amount",
      "amountInWords": "Amount in words:",
      "declaration": "Declaration:",
      "bankDetails": "Bank Details:",
      "authorizedSignatory": "Authorized Signatory"
    }
  }'''
];

List<InvoiceTemplate> getBuiltInTemplates() {
  return defaultTemplatesJson.map((jsonStr) => InvoiceTemplate.fromJson(json.decode(jsonStr))).toList();
}
