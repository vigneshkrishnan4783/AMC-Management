import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';
import '../data/models/document_record.dart';
import '../data/models/contract.dart';
import '../data/models/customer.dart';
import '../data/models/equipment.dart';
import '../data/models/service_visit.dart';
import '../data/models/company_settings.dart';
import '../data/services/pdf_service.dart';
import '../data/services/docx_service.dart';

class DocumentProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<DocumentRecord> _documents = [];
  bool _isLoading = false;

  List<DocumentRecord> get documents => _documents;
  bool get isLoading => _isLoading;

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();
    try {
      _documents = await _db.getAllDocuments();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DocumentRecord>> getDocumentsForEntity(String entityId) async {
    return await _db.getDocumentsForEntity(entityId);
  }

  Future<DocumentRecord> generateAndSaveContractPdf({
    required Contract contract,
    required Customer customer,
    required List<Equipment> equipmentList,
    required CompanySettings settings,
  }) async {
    final bytes = await PdfService.generateContractPdf(
      contract: contract,
      customer: customer,
      equipmentList: equipmentList,
      settings: settings,
    );

    final record = await PdfService.savePdfToFile(
      bytes: bytes,
      entityType: 'contract',
      entityId: contract.id,
      title: 'AMC Agreement - ${contract.contractNumber}',
      filename: '${contract.contractNumber}_Agreement.pdf',
    );

    await _db.insertDocument(record);
    await loadDocuments();
    return record;
  }

  Future<DocumentRecord> generateAndSaveContractDocx({
    required Contract contract,
    required Customer customer,
    required List<Equipment> equipmentList,
    required CompanySettings settings,
  }) async {
    final bytes = await DocxService.generateContractDocx(
      contract: contract,
      customer: customer,
      equipmentList: equipmentList,
      settings: settings,
    );

    final record = await DocxService.saveDocxToFile(
      bytes: bytes,
      entityType: 'contract',
      entityId: contract.id,
      title: 'Editable AMC Agreement - ${contract.contractNumber}',
      filename: '${contract.contractNumber}_Agreement.docx',
    );

    await _db.insertDocument(record);
    await loadDocuments();
    return record;
  }

  Future<DocumentRecord> generateAndSaveVisitPdf({
    required ServiceVisit visit,
    required Customer customer,
    required Contract contract,
    required CompanySettings settings,
  }) async {
    final bytes = await PdfService.generateServiceVisitPdf(
      visit: visit,
      customer: customer,
      contract: contract,
      settings: settings,
    );

    final record = await PdfService.savePdfToFile(
      bytes: bytes,
      entityType: 'service_visit',
      entityId: visit.id,
      title: 'Service Visit Report - ${contract.contractNumber}',
      filename: 'ServiceReport_${visit.id.substring(0, 8)}.pdf',
    );

    await _db.insertDocument(record);
    await loadDocuments();
    return record;
  }

  Future<DocumentRecord> generateAndSaveVisitDocx({
    required ServiceVisit visit,
    required Customer customer,
    required Contract contract,
    required CompanySettings settings,
  }) async {
    final bytes = await DocxService.generateServiceVisitDocx(
      visit: visit,
      customer: customer,
      contract: contract,
      settings: settings,
    );

    final record = await DocxService.saveDocxToFile(
      bytes: bytes,
      entityType: 'service_visit',
      entityId: visit.id,
      title: 'Editable Service Report - ${contract.contractNumber}',
      filename: 'ServiceReport_${visit.id.substring(0, 8)}.docx',
    );

    await _db.insertDocument(record);
    await loadDocuments();
    return record;
  }

  Future<void> deleteDocument(String id) async {
    await _db.deleteDocument(id);
    await loadDocuments();
  }
}
