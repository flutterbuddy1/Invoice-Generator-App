/// Export format options for invoices
enum ExportFormat { json, pdf, zip }

/// Date range presets for quick filtering
enum DateRangePreset { daily, weekly, monthly, yearly, custom }

/// Filter configuration for invoice export
class ExportFilter {
  final List<String> selectedInvoiceIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateRangePreset? preset;
  final ExportFormat format;

  ExportFilter({
    this.selectedInvoiceIds = const [],
    this.startDate,
    this.endDate,
    this.preset,
    required this.format,
  });

  bool get hasDateRange => startDate != null && endDate != null;
  bool get hasSelection => selectedInvoiceIds.isNotEmpty;
  bool get isValid => hasDateRange || hasSelection;
}

/// Result of an export operation
class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final int invoiceCount;

  ExportResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.invoiceCount = 0,
  });

  factory ExportResult.success(String filePath, int count) {
    return ExportResult(success: true, filePath: filePath, invoiceCount: count);
  }

  factory ExportResult.error(String message) {
    return ExportResult(success: false, errorMessage: message);
  }
}

/// Extension to get date range from preset
extension DateRangePresetExtension on DateRangePreset {
  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DateRangePreset.daily:
        return DateRange(start: today, end: today.add(const Duration(days: 1)));
      case DateRangePreset.weekly:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return DateRange(
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
        );
      case DateRangePreset.monthly:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return DateRange(start: monthStart, end: monthEnd);
      case DateRangePreset.yearly:
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31);
        return DateRange(start: yearStart, end: yearEnd);
      case DateRangePreset.custom:
        return DateRange(start: today, end: today);
    }
  }

  String get displayName {
    switch (this) {
      case DateRangePreset.daily:
        return 'Today';
      case DateRangePreset.weekly:
        return 'This Week';
      case DateRangePreset.monthly:
        return 'This Month';
      case DateRangePreset.yearly:
        return 'This Year';
      case DateRangePreset.custom:
        return 'Custom Range';
    }
  }
}

/// Date range helper class
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }
}
