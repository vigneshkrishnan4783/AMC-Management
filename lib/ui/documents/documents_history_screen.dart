import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/document_record.dart';
import 'package:amc/providers/document_provider.dart';

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

  Future<void> _openOrShareDocument(DocumentRecord doc) async {
    final file = File(doc.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found on device storage.'), backgroundColor: AppColors.statusExpired),
        );
      }
      return;
    }

    final bytes = await file.readAsBytes();

    if (doc.documentType == 'pdf') {
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: doc.title,
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(doc.filePath)],
          subject: doc.title,
          text: 'Document: ${doc.title}',
        ),
      );
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
                          'Retrieve earlier copies of AMC agreements and service reports',
                          style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('All (${docProv.documents.length})'),
                        selected: _filterType == 'all',
                        onSelected: (_) => setState(() => _filterType = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('PDF Documents (${docProv.documents.where((d) => d.documentType == 'pdf').length})'),
                        selected: _filterType == 'pdf',
                        onSelected: (_) => setState(() => _filterType = 'pdf'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Word Documents (.docx) (${docProv.documents.where((d) => d.documentType == 'docx').length})'),
                        selected: _filterType == 'docx',
                        onSelected: (_) => setState(() => _filterType = 'docx'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Content
                if (docProv.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (docs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history_edu_outlined, size: 48, color: AppColors.lightTextSecondary),
                            SizedBox(height: 12),
                            Text('No generated documents found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text(
                              'Generate PDF agreements or export Word copies from any contract or service visit.',
                              style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
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
                              style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doc.filePath,
                              style: const TextStyle(fontSize: 10, color: AppColors.lightTextSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.tonal(
                              onPressed: () => _openOrShareDocument(doc),
                              child: Text(isPdf ? 'View / Print' : 'Open / Share', style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
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
