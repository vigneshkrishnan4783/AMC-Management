import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/customer.dart';
import 'package:amc/data/models/equipment.dart';
import 'package:amc/data/services/pdf_service.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/document_provider.dart';
import 'package:amc/providers/service_visit_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import '../equipment/equipment_form_dialog.dart';
import '../reminders/reminder_email_preview_dialog.dart';
import '../service_visits/service_visit_detail_screen.dart';
import '../service_visits/service_visit_form_screen.dart';
import 'contract_form_screen.dart';

class ContractDetailScreen extends StatefulWidget {
  final String contractId;

  const ContractDetailScreen({super.key, required this.contractId});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  List<Equipment> _equipment = [];
  bool _isLoadingEquipment = true;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() => _isLoadingEquipment = true);
    final contractProv = context.read<ContractProvider>();
    final eq = await contractProv.getEquipmentForContract(widget.contractId);
    if (mounted) {
      setState(() {
        _equipment = eq;
        _isLoadingEquipment = false;
      });
    }
  }

  Future<void> _generatePdf(Contract contract, Customer customer) async {
    final docProv = context.read<DocumentProvider>();
    final settingsProv = context.read<SettingsProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating AMC Agreement PDF...')),
    );

    try {
      final docRecord = await docProv.generateAndSaveContractPdf(
        contract: contract,
        customer: customer,
        equipmentList: _equipment,
        settings: settingsProv.settings,
      );

      if (!kIsWeb) {
        final file = File(docRecord.filePath);
        final bytes = await file.readAsBytes();
        await PdfService.shareOrPrintPdf(bytes, '${contract.contractNumber}_Agreement.pdf');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Agreement PDF saved to document history! (${docRecord.title})'),
            backgroundColor: AppColors.statusActive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: AppColors.statusExpired),
        );
      }
    }
  }

  Future<void> _generateDocx(Contract contract, Customer customer) async {
    final docProv = context.read<DocumentProvider>();
    final settingsProv = context.read<SettingsProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating editable Word (.docx) document...')),
    );

    try {
      final docRecord = await docProv.generateAndSaveContractDocx(
        contract: contract,
        customer: customer,
        equipmentList: _equipment,
        settings: settingsProv.settings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Word copy (.docx) saved to document history: ${docRecord.filePath}'),
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

  void _openEmailReminderDialog(Contract contract, Customer customer) {
    final settings = context.read<SettingsProvider>().settings;
    showDialog(
      context: context,
      builder: (_) => ReminderEmailPreviewDialog(
        contract: contract,
        customer: customer,
        equipmentList: _equipment,
        settings: settings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractProv = context.watch<ContractProvider>();
    final customerProv = context.watch<CustomerProvider>();
    final visitProv = context.watch<ServiceVisitProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    final contract = contractProv.allContracts.cast<Contract?>().firstWhere(
          (c) => c?.id == widget.contractId,
          orElse: () => null,
        );

    if (contract == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contract Details')),
        body: const Center(child: Text('Contract not found.')),
      );
    }

    final customer = customerProv.customers.cast<Customer?>().firstWhere(
          (c) => c?.id == contract.customerId,
          orElse: () => null,
        );

    final visits = visitProv.allVisits.where((v) => v.contractId == contract.id).toList();
    final statusColor = Formatters.getContractStatusColor(contract.computedStatus);
    final currency = settingsProv.settings.currencySymbol;
    final days = contract.daysUntilExpiry;

    return Scaffold(
      appBar: AppBar(
        title: Text('${contract.contractNumber} — ${contract.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Contract',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContractFormScreen(contract: contract),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.statusExpired),
            tooltip: 'Delete Contract',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Contract?'),
                  content: Text('Are you sure you want to delete ${contract.contractNumber}?'),
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
                await contractProv.deleteContract(contract.id);
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
                // Top Action Toolbar (Generate PDF, Export Word, Send Renewal Email, Schedule Visit)
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
                                Formatters.formatStatusLabel(contract.computedStatus),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              days < 0 ? 'Expired ${-days} days ago' : '$days days until expiry',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: days < 0 ? AppColors.statusExpired : (days <= 30 ? AppColors.statusExpiring : AppColors.statusActive),
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (customer != null) ...[
                              FilledButton.tonalIcon(
                                onPressed: () => _generatePdf(contract, customer),
                                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                label: const Text('Share PDF Agreement'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _generateDocx(contract, customer),
                                icon: const Icon(Icons.article_outlined, size: 16),
                                label: const Text('Export Word (.docx)'),
                              ),
                              FilledButton.icon(
                                onPressed: () => _openEmailReminderDialog(contract, customer),
                                icon: const Icon(Icons.outgoing_mail, size: 16),
                                label: const Text('Send Renewal Email'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                              ),
                            ],
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceVisitFormScreen(
                                      preselectedContractId: contract.id,
                                      preselectedCustomerId: contract.customerId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_task_outlined, size: 16),
                              label: const Text('Schedule Visit'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Main Info Cards: Details & Client
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isDesktop ? 6 : 1,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CONTRACT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
                              const SizedBox(height: 12),
                              Text(contract.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _buildDetailRow('Contract Number', contract.contractNumber),
                              _buildDetailRow('Period', '${Formatters.formatDate(contract.startDate)} to ${Formatters.formatDate(contract.endDate)}'),
                              _buildDetailRow('Service Frequency', contract.frequency),
                              _buildDetailRow('Contract Value', Formatters.formatCurrency(contract.contractValue, symbol: currency)),
                              _buildDetailRow('Payment Status', contract.paymentStatus),
                              if (contract.termsAndConditions?.isNotEmpty == true) ...[
                                const Divider(height: 24),
                                const Text('Terms & Scope of Work:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(contract.termsAndConditions!, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary, height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isDesktop && customer != null) ...[
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 5,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CUSTOMER & SITE DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
                                const SizedBox(height: 12),
                                Text(customer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                if (customer.company != null) ...[
                                  const SizedBox(height: 2),
                                  Text(customer.company!, style: const TextStyle(fontSize: 13, color: AppColors.primaryLight, fontWeight: FontWeight.w500)),
                                ],
                                const SizedBox(height: 12),
                                _buildDetailRow('Phone', customer.phone),
                                _buildDetailRow('Email', customer.email),
                                _buildDetailRow('Service Address', customer.address),
                                if (customer.notes != null) _buildDetailRow('Customer Notes', customer.notes!),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Covered Equipment Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Covered Equipment (${_equipment.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final res = await showDialog<bool>(
                          context: context,
                          builder: (_) => EquipmentFormDialog(
                            contractId: contract.id,
                            customerId: contract.customerId,
                          ),
                        );
                        if (res == true) _loadEquipment();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Equipment'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoadingEquipment)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (_equipment.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.devices_other, size: 36, color: AppColors.lightTextSecondary),
                            const SizedBox(height: 8),
                            const Text('No equipment registered under this contract yet.', style: TextStyle(color: AppColors.lightTextSecondary)),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final res = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => EquipmentFormDialog(
                                    contractId: contract.id,
                                    customerId: contract.customerId,
                                  ),
                                );
                                if (res == true) _loadEquipment();
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Register First Equipment'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._equipment.map((eq) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.secondary, size: 24),
                          ),
                          title: Text(eq.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('${eq.brand ?? "Brand N/A"} • Model: ${eq.modelNumber ?? "N/A"} • Serial: ${eq.serialNumber ?? "N/A"}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                              if (eq.location != null)
                                Text('Location: ${eq.location}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () async {
                                  final res = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => EquipmentFormDialog(
                                      contractId: contract.id,
                                      customerId: contract.customerId,
                                      equipment: eq,
                                    ),
                                  );
                                  if (res == true) _loadEquipment();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusExpired),
                                onPressed: () async {
                                  await contractProv.deleteEquipment(eq.id);
                                  _loadEquipment();
                                },
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 24),

                // Service Visits Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Service Visits (${visits.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceVisitFormScreen(
                              preselectedContractId: contract.id,
                              preselectedCustomerId: contract.customerId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Visit'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visits.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.calendar_month_outlined, size: 36, color: AppColors.lightTextSecondary),
                            SizedBox(height: 8),
                            Text('No service visits recorded for this contract.', style: TextStyle(color: AppColors.lightTextSecondary)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...visits.map((v) {
                    final visitColor = Formatters.getVisitStatusColor(v.status);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: visitColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.build_circle_outlined, color: visitColor, size: 24),
                        ),
                        title: Row(
                          children: [
                            Text('Tech: ${v.technicianName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: visitColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                v.status.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: visitColor),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Date: ${Formatters.formatDateTime(v.visitDate ?? v.scheduledDate)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                            if (v.checklist.isNotEmpty)
                              Text('Checklist: ${v.completedChecklistCount}/${v.checklist.length} completed',
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceVisitDetailScreen(visitId: v.id),
                            ),
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
