import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/contract.dart';
import '../models/customer.dart';
import '../models/equipment.dart';
import '../models/service_visit.dart';
import '../models/company_settings.dart';
import '../models/document_record.dart';

class DocxService {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  /// Generate a valid Microsoft Word .docx for AMC Agreement
  static Future<Uint8List> generateContractDocx({
    required Contract contract,
    required Customer customer,
    required List<Equipment> equipmentList,
    required CompanySettings settings,
  }) async {
    final buffer = StringBuffer();
    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr>
        <w:pStyle w:val="Title"/>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="48"/>
          <w:color w:val="1E3A8A"/>
        </w:rPr>
        <w:t>${_xmlEscape(settings.businessName)}</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr><w:sz w:val="20"/><w:color w:val="666666"/></w:rPr>
        <w:t>${_xmlEscape(settings.address)} | Phone: ${_xmlEscape(settings.phone)} | Email: ${_xmlEscape(settings.email)}</w:t>
      </w:r>
    </w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
          <w:color w:val="1E3A8A"/>
        </w:rPr>
        <w:t>ANNUAL MAINTENANCE CONTRACT AGREEMENT</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="24"/></w:rPr>
        <w:t>Contract Reference: ${_xmlEscape(contract.contractNumber)}</w:t>
      </w:r>
    </w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="1E3A8A"/></w:rPr>
        <w:t>1. CLIENT INFORMATION</w:t>
      </w:r>
    </w:p>
    <w:p><w:r><w:t>Client Name: ${_xmlEscape(customer.name)}</w:t></w:r></w:p>
    ${customer.company != null ? '<w:p><w:r><w:t>Company / Organization: ${_xmlEscape(customer.company!)}</w:t></w:r></w:p>' : ''}
    <w:p><w:r><w:t>Address: ${_xmlEscape(customer.address)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Phone: ${_xmlEscape(customer.phone)} | Email: ${_xmlEscape(customer.email)}</w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="1E3A8A"/></w:rPr>
        <w:t>2. AGREEMENT TERMS &amp; SCHEDULE</w:t>
      </w:r>
    </w:p>
    <w:p><w:r><w:t>Agreement Title: ${_xmlEscape(contract.title)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Start Date: ${_dateFormat.format(contract.startDate)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Expiry Date: ${_dateFormat.format(contract.endDate)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Service Frequency: ${_xmlEscape(contract.frequency)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Total Contract Value: ${_xmlEscape(settings.currencySymbol)} ${contract.contractValue.toStringAsFixed(2)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Payment Status: ${_xmlEscape(contract.paymentStatus)}</w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="1E3A8A"/></w:rPr>
        <w:t>3. COVERED EQUIPMENT</w:t>
      </w:r>
    </w:p>''');

    if (equipmentList.isEmpty) {
      buffer.write('<w:p><w:r><w:t>No specific equipment itemized.</w:t></w:r></w:p>');
    } else {
      for (int i = 0; i < equipmentList.length; i++) {
        final eq = equipmentList[i];
        buffer.write('''
    <w:p>
      <w:r>
        <w:t>${i + 1}. ${_xmlEscape(eq.name)} (${_xmlEscape(eq.brand ?? '')} ${_xmlEscape(eq.modelNumber ?? '')}) - Serial: ${_xmlEscape(eq.serialNumber ?? 'N/A')} - Location: ${_xmlEscape(eq.location ?? 'N/A')}</w:t>
      </w:r>
    </w:p>''');
      }
    }

    buffer.write('''
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="1E3A8A"/></w:rPr>
        <w:t>4. TERMS &amp; CONDITIONS</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:t>${_xmlEscape(contract.termsAndConditions?.isNotEmpty == true ? contract.termsAndConditions! : (settings.termsTemplate ?? ''))}</w:t>
      </w:r>
    </w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r>
        <w:rPr><w:b/></w:rPr>
        <w:t>Authorized Signatory (${_xmlEscape(settings.businessName)}): ___________________________</w:t>
      </w:r>
    </w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r>
        <w:rPr><w:b/></w:rPr>
        <w:t>Customer Representative (${_xmlEscape(customer.name)}): ___________________________</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>''');

    return _createDocxArchive(buffer.toString());
  }

  /// Generate a valid Microsoft Word .docx for Service Visit Report
  static Future<Uint8List> generateServiceVisitDocx({
    required ServiceVisit visit,
    required Customer customer,
    required Contract contract,
    required CompanySettings settings,
  }) async {
    final buffer = StringBuffer();
    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="40"/><w:color w:val="0D9488"/></w:rPr>
        <w:t>${_xmlEscape(settings.businessName)} - SERVICE REPORT</w:t>
      </w:r>
    </w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p><w:r><w:t>Contract Reference: ${_xmlEscape(contract.contractNumber)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Customer: ${_xmlEscape(customer.name)} (${_xmlEscape(customer.company ?? '')})</w:t></w:r></w:p>
    <w:p><w:r><w:t>Site Address: ${_xmlEscape(customer.address)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Technician: ${_xmlEscape(visit.technicianName)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Date Scheduled: ${_dateFormat.format(visit.scheduledDate)}</w:t></w:r></w:p>
    <w:p><w:r><w:t>Status: ${_xmlEscape(visit.status.toUpperCase())}</w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>SERVICE CHECKLIST</w:t></w:r>
    </w:p>''');

    for (final item in visit.checklist) {
      buffer.write('''
    <w:p>
      <w:r>
        <w:t>[${item.isDone ? 'X' : ' '}] ${_xmlEscape(item.taskDescription)} (${item.isDone ? 'PASSED' : 'PENDING'})</w:t>
      </w:r>
    </w:p>''');
    }

    buffer.write('''
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>WORK DONE &amp; OBSERVATIONS</w:t></w:r>
    </w:p>
    <w:p><w:r><w:t>${_xmlEscape(visit.workDoneNotes ?? 'Routine service completed.')}</w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>PARTS REPLACED</w:t></w:r>
    </w:p>''');

    for (final part in visit.partsReplaced) {
      buffer.write('''
    <w:p>
      <w:r>
        <w:t>- ${_xmlEscape(part.partName)} (Qty: ${part.quantity}, Cost: ${_xmlEscape(settings.currencySymbol)} ${part.unitCost.toStringAsFixed(2)}, Total: ${_xmlEscape(settings.currencySymbol)} ${part.totalCost.toStringAsFixed(2)})</w:t>
      </w:r>
    </w:p>''');
    }

    buffer.write('''
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p>
      <w:r><w:rPr><w:b/></w:rPr><w:t>Technician Signature: ___________________________</w:t>
    </w:p>
    <w:p>
      <w:r><w:rPr><w:b/></w:rPr><w:t>Customer Sign-off: ___________________________</w:t>
    </w:p>
  </w:body>
</w:document>''');

    return _createDocxArchive(buffer.toString());
  }

  static Uint8List _createDocxArchive(String documentXml) {
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, utf8.encode(contentTypes)));

    // 2. _rels/.rels
    const rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', rels.length, utf8.encode(rels)));

    // 3. word/document.xml
    final docBytes = utf8.encode(documentXml);
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  static String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Save Word docx file to documents directory and return DocumentRecord
  static Future<DocumentRecord> saveDocxToFile({
    required Uint8List bytes,
    required String entityType,
    required String entityId,
    required String title,
    required String filename,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final amcDocsFolder = Directory('${docsDir.path}/AMC_Documents');
    if (!await amcDocsFolder.exists()) {
      await amcDocsFolder.create(recursive: true);
    }

    final safeFilename = filename.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final filePath = '${amcDocsFolder.path}/$safeFilename';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return DocumentRecord(
      id: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      title: title,
      documentType: 'docx',
      filePath: filePath,
      fileSize: bytes.length,
      createdAt: DateTime.now(),
    );
  }
}
