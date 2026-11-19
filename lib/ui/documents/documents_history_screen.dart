import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/document_record.dart';
import 'package:amc/data/services/pdf_service.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/document_provider.dart';
import 'package:amc/providers/service_visit_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import 'pdf_viewer_screen.dart';

class DocumentsHistoryScreen extends StatefulWidget {
  const DocumentsHistoryScreen({super.key});

  @override
  State<DocumentsHistoryScreen> createState() => _DocumentsHistoryScreenState();
}

class _DocumentsHistoryScreenState extends State<DocumentsHistoryScreen> {
  String _filterType = 'all'; // 'all', 'pdf', 'docx'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
    });
  }

  Future<Uint8List?> _resolvePdfBytes(DocumentRecord doc) async {
    final settings = context.read<SettingsProvider>().settings;
    final contractProv = context.read<ContractProvider>();
    final customerProv = context.read<CustomerProvider>();
    final visitProv = context.read<ServiceVisitProvider>();

    // 1. Try reading from local file if available
    if (!kIsWeb) {
      final file = File(doc.filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }

    // 2. Re-synthesize from model data
    if (doc.entityType == 'contract') {
      final contract = contractProv.allContracts.firstWhere(
        (c) => c.id == doc.entityId,
        orElse: () => contractProv.allContracts.first,
      );
      final customer = customerProv.customers.firstWhere(
        (c) => c.id == contract.customerId,
        orElse: () => customerProv.customers.first,
      );
      final eqList = await contractProv.getEquipmentForContract(contract.id);
      return await PdfService.generateContractPdf(
        contract: contract,
        customer: customer,
        equipmentList: eqList,
        settings: settings,
      );
    } else if (doc.entityType == 'visit') {
      final visit = visitProv.allVisits.firstWhere(
        (v) => v.id == doc.entityId,
        orElse: () => visitProv.allVisits.first,
      );
      final contract = contractProv.allContracts.firstWhere(
        (c) => c.id == visit.contractId,
        orElse: () => contractProv.allContracts.first,
      );
      final customer = customerProv.customers.firstWhere(
        (c) => c.id == visit.customerId,
        orElse: () => customerProv.customers.first,
      );
      return await PdfService.generateServiceReportPdf(
        visit: visit,
        customer: customer,
        contract: contract,
        settings: settings,
      );
    }
    return null;
  }

  void _viewPdf(DocumentRecord doc) {
    final safeName = '${doc.title.replaceAll(RegExp(r"[^\w\.-]"), "_")}.pdf';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          title: doc.title,
          filename: safeName,
          pdfBytesBuilder: () async {
            final bytes = await _resolvePdfBytes(doc);
            if (bytes == null) {
              throw Exception('Unable to load or synthesize document bytes.');
            }
            return bytes;
          },
        ),
      ),
    );
  }

  Future<void> _downloadOrShareDocument(DocumentRecord doc) async {
    final isPdf = doc.documentType == 'pdf';
    final safeName = '${doc.title.replaceAll(RegExp(r"[^\w\.-]"), "_")}.${doc.documentType}';

    if (isPdf) {
      try {
        final bytes = await _resolvePdfBytes(doc);
        if (bytes != null) {
          await Printing.sharePdf(bytes: bytes, filename: safeName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloaded: $safeName'),
                backgroundColor: AppColors.statusActive,
              ),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error downloading: $e'), backgroundColor: AppColors.statusExpired),
          );
        }
        return;
      }
    }

    if (!kIsWeb) {
      final file = File(doc.filePath);
      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(doc.filePath)],
            subject: doc.title,
            text: 'Document: ${doc.title}',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProv = context.watch<DocumentProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    var docs = docProv.documents;
    if (_filterType != 'all') {
      docs = docs.where((d) => d.documentType == _filterType).toList();
    }

    return Scaffold(
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document Archive & History',
                          style: TextStyle(
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'View, download, and share past agreements & service reports',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All')),
                        ButtonSegment(value: 'pdf', label: Text('PDF')),
                        ButtonSegment(value: 'docx', label: Text('Word')),
                      ],
                      selected: {_filterType},
                      onSelectionChanged: (val) {
                        setState(() => _filterType = val.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (docs.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.folder_open_outlined, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _filterType == 'all'
                                  ? 'No documents generated yet'
                                  : 'No ${_filterType.toUpperCase()} documents found',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Generate PDF agreements or export Word copies from any contract or service visit.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...docs.map((doc) {
                    final isPdf = doc.documentType == 'pdf';
                    final sizeKb = (doc.fileSize / 1024).toStringAsFixed(1);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPdf ? Colors.red.withOpacity(0.12) : Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                            color: isPdf ? Colors.red : Colors.blue,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          doc.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'Type: ${doc.documentType.toUpperCase()} • Size: $sizeKb KB • Created: ${Formatters.formatDateTime(doc.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doc.filePath,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPdf) ...[
                              FilledButton.icon(
                                onPressed: () => _viewPdf(doc),
                                icon: const Icon(Icons.visibility_outlined, size: 14),
                                label: const Text('View PDF', style: TextStyle(fontSize: 12)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            FilledButton.tonalIcon(
                              onPressed: () => _downloadOrShareDocument(doc),
                              icon: const Icon(Icons.download_rounded, size: 14),
                              label: Text(isPdf ? 'Download' : 'Share', style: const TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusExpired),
                              onPressed: () async {
                                await docProv.deleteDocument(doc.id);
                              },
                            ),
                          ],
                        ),
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
}
