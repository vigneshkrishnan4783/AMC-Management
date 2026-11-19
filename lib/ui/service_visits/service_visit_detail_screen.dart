import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/checklist_item.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/customer.dart';
import 'package:amc/data/models/part_replaced.dart';
import 'package:amc/data/models/service_visit.dart';
import 'package:amc/data/services/pdf_service.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/document_provider.dart';
import 'package:amc/providers/service_visit_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import '../documents/pdf_viewer_screen.dart';
import 'widgets/signature_pad_widget.dart';

class ServiceVisitDetailScreen extends StatefulWidget {
  final String visitId;

  const ServiceVisitDetailScreen({super.key, required this.visitId});

  @override
  State<ServiceVisitDetailScreen> createState() => _ServiceVisitDetailScreenState();
}

class _ServiceVisitDetailScreenState extends State<ServiceVisitDetailScreen> {
  final _workNotesController = TextEditingController();
  final _newChecklistController = TextEditingController();

  // New Part Replaced form controllers
  final _partNameCtrl = TextEditingController();
  final _partNumCtrl = TextEditingController();
  final _partQtyCtrl = TextEditingController(text: '1');
  final _partCostCtrl = TextEditingController(text: '0.00');

  String? _technicianSig;
  String? _customerSig;

  @override
  void dispose() {
    _workNotesController.dispose();
    _newChecklistController.dispose();
    _partNameCtrl.dispose();
    _partNumCtrl.dispose();
    _partQtyCtrl.dispose();
    _partCostCtrl.dispose();
    super.dispose();
  }

  void _addChecklistItem(ServiceVisit visit) {
    if (_newChecklistController.text.trim().isEmpty) return;

    final newItem = ChecklistItem(
      id: const Uuid().v4(),
      visitId: visit.id,
      taskDescription: _newChecklistController.text.trim(),
      isDone: false,
    );

    final updated = visit.copyWith(checklist: [...visit.checklist, newItem]);
    context.read<ServiceVisitProvider>().updateVisit(updated);
    _newChecklistController.clear();
  }

  void _addPartReplaced(ServiceVisit visit) {
    if (_partNameCtrl.text.trim().isEmpty) return;

    final newPart = PartReplaced(
      id: const Uuid().v4(),
      visitId: visit.id,
      partName: _partNameCtrl.text.trim(),
      partNumber: _partNumCtrl.text.trim().isNotEmpty ? _partNumCtrl.text.trim() : null,
      quantity: int.tryParse(_partQtyCtrl.text.trim()) ?? 1,
      unitCost: double.tryParse(_partCostCtrl.text.trim()) ?? 0.0,
    );

    final updated = visit.copyWith(partsReplaced: [...visit.partsReplaced, newPart]);
    context.read<ServiceVisitProvider>().updateVisit(updated);

    _partNameCtrl.clear();
    _partNumCtrl.clear();
    _partQtyCtrl.text = '1';
    _partCostCtrl.text = '0.00';
    Navigator.pop(context);
  }

  void _viewPdf(ServiceVisit visit, Customer customer, Contract contract) {
    final visitCode = visit.id.length >= 8 ? visit.id.substring(0, 8).toUpperCase() : visit.id;
    final settings = context.read<SettingsProvider>().settings;
    final docProv = context.read<DocumentProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          title: 'Service Report - $visitCode',
          filename: 'ServiceReport_$visitCode.pdf',
          pdfBytesBuilder: () async {
            final bytes = await PdfService.generateServiceReportPdf(
              visit: visit,
              customer: customer,
              contract: contract,
              settings: settings,
            );
            await docProv.generateAndSaveVisitPdf(
              visit: visit,
              customer: customer,
              contract: contract,
              settings: settings,
            );
            return bytes;
          },
        ),
      ),
    );
  }

  Future<void> _downloadPdf(ServiceVisit visit, Customer customer, Contract contract) async {
    final docProv = context.read<DocumentProvider>();
    final settingsProv = context.read<SettingsProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing Service Report PDF download...')),
    );

    try {
      final bytes = await PdfService.generateServiceReportPdf(
        visit: visit,
        customer: customer,
        contract: contract,
        settings: settingsProv.settings,
      );

      await docProv.generateAndSaveVisitPdf(
        visit: visit,
        customer: customer,
        contract: contract,
        settings: settingsProv.settings,
      );

      final visitCode = visit.id.length >= 8 ? visit.id.substring(0, 8).toUpperCase() : visit.id;
      final filename = 'ServiceReport_$visitCode.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service Report downloaded & saved: $filename'),
            backgroundColor: AppColors.statusActive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading report: $e'), backgroundColor: AppColors.statusExpired),
        );
      }
    }
  }

  Future<void> _generateDocx(ServiceVisit visit, Customer customer, Contract contract) async {
    final docProv = context.read<DocumentProvider>();
    final settingsProv = context.read<SettingsProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating editable Word (.docx) Service Report...')),
    );

    try {
      await docProv.generateAndSaveVisitDocx(
        visit: visit,
        customer: customer,
        contract: contract,
        settings: settingsProv.settings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Word report (.docx) created in document history!'),
            backgroundColor: AppColors.statusActive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating Word document: $e'), backgroundColor: AppColors.statusExpired),
        );
      }
    }
  }

  Future<void> _completeVisit(ServiceVisit visit) async {
    final notes = _workNotesController.text.trim();
    final updated = visit.copyWith(
      status: 'completed',
      visitDate: DateTime.now(),
      completedAt: DateTime.now(),
      workDoneNotes: notes.isNotEmpty ? notes : visit.workDoneNotes,
      technicianSignatureBase64: _technicianSig ?? visit.technicianSignatureBase64,
      customerSignatureBase64: _customerSig ?? visit.customerSignatureBase64,
    );

    await context.read<ServiceVisitProvider>().updateVisit(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service Visit marked as Completed!'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitProv = context.watch<ServiceVisitProvider>();
    final contractProv = context.watch<ContractProvider>();
    final customerProv = context.watch<CustomerProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    final visit = visitProv.allVisits.cast<ServiceVisit?>().firstWhere(
          (v) => v?.id == widget.visitId,
          orElse: () => null,
        );

    if (visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visit Details')),
        body: const Center(child: Text('Visit record not found.')),
      );
    }

    final contract = contractProv.allContracts.cast<Contract?>().firstWhere(
          (c) => c?.id == visit.contractId,
          orElse: () => null,
        );

    final customer = customerProv.customers.cast<Customer?>().firstWhere(
          (c) => c?.id == visit.customerId,
          orElse: () => null,
        );

    if (_workNotesController.text.isEmpty && visit.workDoneNotes != null) {
      _workNotesController.text = visit.workDoneNotes!;
    }

    final statusColor = Formatters.getVisitStatusColor(visit.status);
    final currency = settingsProv.settings.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text('Service Visit — ${visit.technicianName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.statusExpired),
            tooltip: 'Delete Visit',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Visit Record?'),
                  content: const Text('Are you sure you want to delete this service visit record?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.statusExpired),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await visitProv.deleteVisit(visit.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoints.contentMaxWidth(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Card & Document Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                visit.status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Scheduled: ${Formatters.formatDateTime(visit.scheduledDate)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (customer != null && contract != null) ...[
                              FilledButton.icon(
                                onPressed: () => _viewPdf(visit, customer, contract),
                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                label: const Text('View PDF'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => _downloadPdf(visit, customer, contract),
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('Download PDF'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _generateDocx(visit, customer, contract),
                                icon: const Icon(Icons.article_outlined, size: 16),
                                label: const Text('Export Word (.docx)'),
                              ),
                            ],
                            if (visit.status != 'completed')
                              FilledButton.icon(
                                onPressed: () => _completeVisit(visit),
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Complete Visit'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.statusCompleted),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Technician & Customer details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TECHNICIAN & VISIT INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(height: 10),
                              Text('Assigned Technician: ${visit.technicianName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Contract: ${contract?.contractNumber ?? "N/A"} (${contract?.title ?? ""})', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                              if (visit.completedAt != null)
                                Text('Completed At: ${Formatters.formatDateTime(visit.completedAt)}', style: const TextStyle(fontSize: 12, color: AppColors.statusActive, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isDesktop && customer != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CUSTOMER & SITE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                const SizedBox(height: 10),
                                Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('${Formatters.maskPhoneNumber(customer.phone)} • ${customer.address}', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Interactive Maintenance Checklist
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('MAINTENANCE CHECKLIST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                const SizedBox(height: 2),
                                Text(
                                  '${visit.completedChecklistCount} of ${visit.checklist.length} tasks completed',
                                  style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (visit.completedChecklistCount == visit.checklist.length && visit.checklist.isNotEmpty)
                                    ? AppColors.statusActive.withOpacity(0.15)
                                    : AppColors.statusExpiring.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                visit.checklist.isEmpty
                                    ? 'No Tasks'
                                    : '${((visit.completedChecklistCount / visit.checklist.length) * 100).round()}% Completed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: (visit.completedChecklistCount == visit.checklist.length && visit.checklist.isNotEmpty)
                                      ? AppColors.statusActive
                                      : AppColors.statusExpiring,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (visit.checklist.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No checklist tasks added yet.', style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13)),
                          )
                        else
                          ...visit.checklist.map((item) {
                            return CheckboxListTile(
                              value: item.isDone,
                              onChanged: (_) {
                                visitProv.toggleChecklistItem(visit.id, item.id);
                              },
                              title: Text(
                                item.taskDescription,
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                                  color: item.isDone ? AppColors.lightTextSecondary : null,
                                ),
                              ),
                              secondary: Icon(
                                item.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: item.isDone ? AppColors.statusActive : AppColors.lightTextSecondary,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                            );
                          }),
                        const SizedBox(height: 12),
                        // Add checklist task inline
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newChecklistController,
                                decoration: const InputDecoration(
                                  hintText: 'Add checklist item (e.g. Clean suction filters, check oil level)...',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onSubmitted: (_) => _addChecklistItem(visit),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.tonal(
                              onPressed: () => _addChecklistItem(visit),
                              child: const Text('Add Task'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Parts Replaced Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PARTS REPLACED & CONSUMABLES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                const SizedBox(height: 2),
                                Text(
                                  'Total Parts Cost: ${Formatters.formatCurrency(visit.totalPartsCost, symbol: currency)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Record Part Replaced'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(controller: _partNameCtrl, decoration: const InputDecoration(labelText: 'Part Name *')),
                                        const SizedBox(height: 10),
                                        TextField(controller: _partNumCtrl, decoration: const InputDecoration(labelText: 'Part Number / Code')),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(child: TextField(controller: _partQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))),
                                            const SizedBox(width: 10),
                                            Expanded(child: TextField(controller: _partCostCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Cost'))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => _addPartReplaced(visit), child: const Text('Add Part')),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Part'),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (visit.partsReplaced.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No parts replaced recorded during this service.', style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13)),
                          )
                        else
                          ...visit.partsReplaced.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final part = entry.value;
                            return ListTile(
                              dense: true,
                              title: Text(part.partName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Qty: ${part.quantity} • Unit: ${Formatters.formatCurrency(part.unitCost, symbol: currency)} ${part.partNumber != null ? "• #${part.partNumber}" : ""}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(Formatters.formatCurrency(part.totalCost, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.statusExpired),
                                    onPressed: () {
                                      final updatedParts = List<PartReplaced>.from(visit.partsReplaced)..removeAt(idx);
                                      visitProv.updateVisit(visit.copyWith(partsReplaced: updatedParts));
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Work Done Observations & Sign-off
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WORK DONE & OBSERVATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _workNotesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Record technician notes, operational parameters, or future recommendations...',
                          ),
                          onChanged: (text) {
                            visitProv.updateVisit(visit.copyWith(workDoneNotes: text));
                          },
                        ),
                        const SizedBox(height: 24),

                        // Signature Pads (Technician & Customer)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SignaturePadWidget(
                                title: 'Technician Signature',
                                initialSignatureBase64: visit.technicianSignatureBase64,
                                onSigned: (sig) => _technicianSig = sig,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SignaturePadWidget(
                                title: 'Customer Sign-Off',
                                initialSignatureBase64: visit.customerSignatureBase64,
                                onSigned: (sig) => _customerSig = sig,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Bottom Save / Complete Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _completeVisit(visit),
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: Text(visit.status == 'completed' ? 'Update & Save Visit' : 'Complete & Sign Off Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCompleted,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
