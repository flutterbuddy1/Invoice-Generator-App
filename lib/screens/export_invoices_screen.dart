import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/invoice.dart';
import '../models/export_models.dart';
import '../providers/invoice_provider.dart';
import '../providers/business_provider.dart';
import '../providers/template_provider.dart';
import '../services/export_service.dart';
import '../services/ad_service.dart';

class ExportInvoicesScreen extends StatefulWidget {
  const ExportInvoicesScreen({super.key});

  @override
  State<ExportInvoicesScreen> createState() => _ExportInvoicesScreenState();
}

class _ExportInvoicesScreenState extends State<ExportInvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExportService _exportService = ExportService();

  // Selection state
  final Set<String> _selectedInvoiceIds = {};
  bool _selectAll = false;

  // Date range state
  DateRangePreset _selectedPreset = DateRangePreset.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Export format
  ExportFormat _selectedFormat = ExportFormat.pdf;

  // Merge PDF option (only for PDF format with multiple invoices)
  bool _mergePdfs = true;

  // Loading state
  bool _isExporting = false;

  // Banner ad
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd()
      ..load().then((_) {
        setState(() {
          _isBannerAdReady = true;
        });
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Export Invoices', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Select Invoices'),
            Tab(text: 'Date Range'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSelectInvoicesTab(), _buildDateRangeTab()],
            ),
          ),
          _buildExportControls(),
          if (_isBannerAdReady)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectInvoicesTab() {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        final invoices = provider.invoices;

        if (invoices.isEmpty) {
          return const Center(child: Text('No invoices available'));
        }

        return Column(
          children: [
            // Select All Toggle
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedInvoiceIds.length} of ${invoices.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: Icon(_selectAll ? Icons.deselect : Icons.select_all),
                    label: Text(_selectAll ? 'Deselect All' : 'Select All'),
                    onPressed: () {
                      setState(() {
                        if (_selectAll) {
                          _selectedInvoiceIds.clear();
                        } else {
                          _selectedInvoiceIds.addAll(
                            invoices.map((inv) => inv.id),
                          );
                        }
                        _selectAll = !_selectAll;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Invoice List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  final isSelected = _selectedInvoiceIds.contains(invoice.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedInvoiceIds.add(invoice.id);
                          } else {
                            _selectedInvoiceIds.remove(invoice.id);
                          }
                          _selectAll =
                              _selectedInvoiceIds.length == invoices.length;
                        });
                      },
                      title: Text(
                        invoice.clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('#${invoice.invoiceNumber}'),
                          Text(
                            DateFormat('dd MMM yyyy').format(invoice.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      secondary: Text(
                        '₹${invoice.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateRangeTab() {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        final invoices = provider.invoices;
        final filteredCount = _getFilteredInvoiceCount(invoices);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Presets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip(DateRangePreset.daily),
                  _buildPresetChip(DateRangePreset.weekly),
                  _buildPresetChip(DateRangePreset.monthly),
                  _buildPresetChip(DateRangePreset.yearly),
                  _buildPresetChip(DateRangePreset.custom),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedPreset == DateRangePreset.custom) ...[
                const Text(
                  'Custom Date Range',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: 'From',
                        date: _customStartDate,
                        onTap: () => _selectDate(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateField(
                        label: 'To',
                        date: _customEndDate,
                        onTap: () => _selectDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$filteredCount invoice(s) found in selected range',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(DateRangePreset preset) {
    final isSelected = _selectedPreset == preset;
    return ChoiceChip(
      label: Text(preset.displayName),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPreset = preset;
          if (preset != DateRangePreset.custom) {
            _customStartDate = null;
            _customEndDate = null;
          }
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select date',
          style: TextStyle(color: date != null ? Colors.black87 : Colors.grey),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked;
        }
      });
    }
  }

  Widget _buildExportControls() {
    final isValid = _isExportValid();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Export Format',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormatOption(
                  ExportFormat.pdf,
                  Icons.picture_as_pdf,
                  'PDF',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatOption(
                  ExportFormat.json,
                  Icons.code,
                  'JSON',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatOption(
                  ExportFormat.zip,
                  Icons.folder_zip,
                  'ZIP',
                ),
              ),
            ],
          ),
          // Merge PDF option (only for PDF format with multiple invoices)
          if (_selectedFormat == ExportFormat.pdf && _getExportCount() > 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.merge_type, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merge into single PDF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'OFF = ZIP file with individual PDFs',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _mergePdfs,
                    onChanged: (value) {
                      setState(() {
                        _mergePdfs = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isValid && !_isExporting ? _handleExport : null,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isExporting ? 'Exporting...' : 'Export'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(ExportFormat format, IconData icon, String label) {
    final isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFormat = format;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isExportValid() {
    if (_tabController.index == 0) {
      // Selection tab
      return _selectedInvoiceIds.isNotEmpty;
    } else {
      // Date range tab
      if (_selectedPreset == DateRangePreset.custom) {
        return _customStartDate != null && _customEndDate != null;
      }
      return true;
    }
  }

  int _getFilteredInvoiceCount(List<Invoice> invoices) {
    if (_selectedPreset == DateRangePreset.custom) {
      if (_customStartDate == null || _customEndDate == null) {
        return 0;
      }
      return invoices.where((invoice) {
        return invoice.date.isAfter(
              _customStartDate!.subtract(const Duration(days: 1)),
            ) &&
            invoice.date.isBefore(_customEndDate!.add(const Duration(days: 1)));
      }).length;
    } else {
      final dateRange = _selectedPreset.getDateRange();
      return invoices.where((invoice) {
        return dateRange.contains(invoice.date);
      }).length;
    }
  }

  int _getExportCount() {
    if (_tabController.index == 0) {
      return _selectedInvoiceIds.length;
    } else {
      final provider = Provider.of<InvoiceProvider>(context, listen: false);
      return _getFilteredInvoiceCount(provider.invoices);
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final invoiceProvider = Provider.of<InvoiceProvider>(
        context,
        listen: false,
      );
      final businessProvider = Provider.of<BusinessProvider>(
        context,
        listen: false,
      );
      final templateProvider = Provider.of<TemplateProvider>(
        context,
        listen: false,
      );

      final invoices = invoiceProvider.invoices;
      final profile = businessProvider.businessProfile!;

      // Ensure templates are loaded
      if (templateProvider.isLoading) {
        await templateProvider.loadTemplates();
      }

      final template = templateProvider.selectedTemplate;

      if (template == null) {
        setState(() {
          _isExporting = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No template selected. Please select a template from Settings.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ExportResult result;

      // Get invoices to export
      List<Invoice> invoicesToExport;
      if (_tabController.index == 0) {
        // Export selected invoices
        invoicesToExport = invoices
            .where((inv) => _selectedInvoiceIds.contains(inv.id))
            .toList();
      } else {
        // Export by date range
        DateTime startDate, endDate;
        if (_selectedPreset == DateRangePreset.custom) {
          startDate = _customStartDate!;
          endDate = _customEndDate!;
        } else {
          final dateRange = _selectedPreset.getDateRange();
          startDate = dateRange.start;
          endDate = dateRange.end;
        }

        invoicesToExport = invoices.where((invoice) {
          return invoice.date.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              invoice.date.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();
      }

      // Check if we should use merged PDF
      if (_selectedFormat == ExportFormat.pdf &&
          _mergePdfs &&
          _getExportCount() > 1) {
        // Get invoices to merge
        List<Invoice> invoicesToMerge;
        if (_tabController.index == 0) {
          invoicesToMerge = invoices
              .where((inv) => _selectedInvoiceIds.contains(inv.id))
              .toList();
        } else {
          DateTime startDate, endDate;
          if (_selectedPreset == DateRangePreset.custom) {
            startDate = _customStartDate!;
            endDate = _customEndDate!;
          } else {
            final dateRange = _selectedPreset.getDateRange();
            startDate = dateRange.start;
            endDate = dateRange.end;
          }

          invoicesToMerge = invoices.where((invoice) {
            return invoice.date.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                invoice.date.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();
        }

        // Use merged PDF export
        result = await _exportService.exportMergedPdf(
          invoicesToMerge,
          profile,
          templateProvider.currentStyles!,
          templateProvider.currentLabels!,
          templateProvider.currentFeatures,
        );
      } else if (_tabController.index == 0) {
        // Export selected invoices
        result = await _exportService.exportSelectedInvoices(
          invoices,
          _selectedInvoiceIds.toList(),
          _selectedFormat,
          profile,
          templateProvider.currentStyles!,
          templateProvider.currentLabels!,
          templateProvider.currentFeatures,
        );
      } else {
        // Export by date range (original method)
        DateTime startDate, endDate;
        if (_selectedPreset == DateRangePreset.custom) {
          startDate = _customStartDate!;
          endDate = _customEndDate!;
        } else {
          final dateRange = _selectedPreset.getDateRange();
          startDate = dateRange.start;
          endDate = dateRange.end;
        }

        result = await _exportService.exportByDateRange(
          invoices,
          startDate,
          endDate,
          _selectedFormat,
          profile,
          templateProvider.currentStyles!,
          templateProvider.currentLabels!,
          templateProvider.currentFeatures,
        );
      }

      setState(() {
        _isExporting = false;
      });

      if (!mounted) return;

      if (result.success) {
        // Show success and share
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Text(
              'Successfully exported ${result.invoiceCount} invoice(s).\n\n'
              'File: ${result.filePath!.split('/').last}\n'
              'Size: ${_exportService.getFileSize(result.filePath!)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Done'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Share'),
              ),
            ],
          ),
        );

        if (shouldShare == true && result.filePath != null) {
          await _exportService.shareFile(result.filePath!);
        }
      } else {
        // Show error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Export failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
