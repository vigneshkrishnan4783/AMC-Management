import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../models/contract.dart';
import '../models/customer.dart';
import '../models/equipment.dart';
import '../models/service_visit.dart';
import '../models/company_settings.dart';
import '../models/document_record.dart';

class PdfService {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  /// Generate AMC Agreement PDF
  static Future<Uint8List> generateContractPdf({
    required Contract contract,
    required Customer customer,
    required List<Equipment> equipmentList,
    required CompanySettings settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    settings.businessName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(settings.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Text('Phone: ${settings.phone}  |  Email: ${settings.email}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if (settings.taxNumber != null && settings.taxNumber!.isNotEmpty)
                    pw.Text(settings.taxNumber!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('AMC AGREEMENT',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Contract #: ${contract.contractNumber}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    pw.Text('Date: ${_dateFormat.format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey300, height: 24),

          // Customer & Agreement Details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENT DETAILS',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      pw.SizedBox(height: 4),
                      pw.Text(customer.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      if (customer.company != null && customer.company!.isNotEmpty)
                        pw.Text(customer.company!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text(customer.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Email: ${customer.email}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CONTRACT SUMMARY',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      pw.SizedBox(height: 4),
                      pw.Text(contract.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('Period: ${_dateFormat.format(contract.startDate)} - ${_dateFormat.format(contract.endDate)}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Frequency: ${contract.frequency}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Payment Status: ${contract.paymentStatus}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text(
                        'Total Value: ${settings.currencySymbol} ${contract.contractValue.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Covered Equipment
          pw.Text('COVERED EQUIPMENT (${equipmentList.length})',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 6),
          if (equipmentList.isEmpty)
            pw.Text('No specific equipment specified for this contract.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item / Name', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Brand / Model', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Serial Number', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Location', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...equipmentList.map(
                  (eq) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(eq.name, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${eq.brand ?? "-"} / ${eq.modelNumber ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(eq.serialNumber ?? '-', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(eq.location ?? '-', style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                ),
              ],
            ),
          pw.SizedBox(height: 18),

          // Terms and Conditions
          pw.Text('TERMS & CONDITIONS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              contract.termsAndConditions?.isNotEmpty == true
                  ? contract.termsAndConditions!
                  : (settings.termsTemplate ?? 'Standard AMC preventative maintenance terms apply.'),
              style: const pw.TextStyle(fontSize: 9, height: 1.4, color: PdfColors.grey800),
            ),
          ),
          pw.SizedBox(height: 36),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 180, height: 1, color: PdfColors.grey500),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Service Provider Signature',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(settings.businessName, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 180, height: 1, color: PdfColors.grey500),
                  pw.SizedBox(height: 4),
                  pw.Text('Customer Acceptance Signature',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(customer.name, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Service Visit Report PDF
  static Future<Uint8List> generateServiceVisitPdf({
    required ServiceVisit visit,
    required Customer customer,
    required Contract contract,
    required CompanySettings settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(settings.businessName,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text('Service & Maintenance Division', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Text('Phone: ${settings.phone} | ${settings.email}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.teal200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('SERVICE VISIT REPORT',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                    pw.Text('Date: ${_dateFormat.format(visit.visitDate ?? visit.scheduledDate)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                    pw.Text('Status: ${visit.status.toUpperCase()}',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                  ],
                ),
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey300, height: 20),

          // Visit & Customer details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER & SITE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(customer.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      if (customer.company != null)
                        pw.Text(customer.company!, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text(customer.address, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('Tel: ${customer.phone}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SERVICE INFO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('Contract: ${contract.contractNumber}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('Technician: ${visit.technicianName}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Scheduled: ${_dateFormat.format(visit.scheduledDate)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      if (visit.completedAt != null)
                        pw.Text('Completed: ${_dateFormat.format(visit.completedAt!)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Maintenance Checklist
          pw.Text('SERVICE CHECKLIST',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 4),
          if (visit.checklist.isEmpty)
            pw.Text('No checklist items defined for this visit.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Task / Check Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Status', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...visit.checklist.map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.taskDescription, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          item.isDone ? 'COMPLETED [PASS]' : 'PENDING',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: item.isDone ? PdfColors.green800 : PdfColors.amber800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          pw.SizedBox(height: 14),

          // Work Done Notes
          pw.Text('WORK DONE & OBSERVATIONS',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              visit.workDoneNotes?.isNotEmpty == true
                  ? visit.workDoneNotes!
                  : 'Routine maintenance completed satisfactorily according to AMC standard guidelines.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
            ),
          ),
          pw.SizedBox(height: 14),

          // Parts Replaced
          pw.Text('PARTS REPLACED (${visit.partsReplaced.length})',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 4),
          if (visit.partsReplaced.isEmpty)
            pw.Text('No replacement parts recorded during this visit.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
          else ...[
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Part Name / Code', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Unit Cost', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...visit.partsReplaced.map(
                  (p) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${p.partName} ${p.partNumber != null ? "(${p.partNumber})" : ""}', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${p.quantity}', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${settings.currencySymbol} ${p.unitCost.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${settings.currencySymbol} ${p.totalCost.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8))),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Parts Cost: ${settings.currencySymbol} ${visit.totalPartsCost.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
            ),
          ],
          pw.SizedBox(height: 24),

          // Sign-off
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.grey500),
                  pw.SizedBox(height: 4),
                  pw.Text('Technician Signature: ${visit.technicianName}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.grey500),
                  pw.SizedBox(height: 4),
                  pw.Text('Customer Sign-Off: ${customer.name}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Save PDF file to documents directory and return DocumentRecord
  static Future<DocumentRecord> savePdfToFile({
    required Uint8List bytes,
    required String entityType,
    required String entityId,
    required String title,
    required String filename,
  }) async {
    String filePath = filename;
    if (!kIsWeb) {
      final docsDir = await getApplicationDocumentsDirectory();
      final amcDocsFolder = Directory('${docsDir.path}/AMC_Documents');
      if (!await amcDocsFolder.exists()) {
        await amcDocsFolder.create(recursive: true);
      }

      final safeFilename = filename.replaceAll(RegExp(r'[^\w\.-]'), '_');
      filePath = '${amcDocsFolder.path}/$safeFilename';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
    }

    return DocumentRecord(
      id: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      title: title,
      documentType: 'pdf',
      filePath: filePath,
      fileSize: bytes.length,
      createdAt: DateTime.now(),
    );
  }

  /// Print or share PDF using Printing
  static Future<void> shareOrPrintPdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
