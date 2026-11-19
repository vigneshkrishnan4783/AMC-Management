import '../../core/constants/app_constants.dart';
import 'checklist_item.dart';
import 'part_replaced.dart';

class ServiceVisit {
  final String id;
  final String contractId;
  final String customerId;
  final DateTime scheduledDate;
  final DateTime? visitDate;
  final String technicianName;
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled'
  final String? workDoneNotes;
  final String? customerSignatureBase64;
  final String? technicianSignatureBase64;
  final DateTime? completedAt;
  final List<ChecklistItem> checklist;
  final List<PartReplaced> partsReplaced;

  ServiceVisit({
    required this.id,
    required this.contractId,
    required this.customerId,
    required this.scheduledDate,
    this.visitDate,
    required this.technicianName,
    required this.status,
    this.workDoneNotes,
    this.customerSignatureBase64,
    this.technicianSignatureBase64,
    this.completedAt,
    this.checklist = const [],
    this.partsReplaced = const [],
  });

  double get totalPartsCost =>
      partsReplaced.fold(0.0, (sum, part) => sum + part.totalCost);

  int get completedChecklistCount =>
      checklist.where((item) => item.isDone).length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_id': contractId,
      'customer_id': customerId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'visit_date': visitDate?.toIso8601String(),
      'technician_name': technicianName,
      'status': status,
      'work_done_notes': workDoneNotes,
      'customer_signature_base64': customerSignatureBase64,
      'technician_signature_base64': technicianSignatureBase64,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory ServiceVisit.fromMap(
    Map<String, dynamic> map, {
    List<ChecklistItem> checklist = const [],
    List<PartReplaced> parts = const [],
  }) {
    return ServiceVisit(
      id: map['id'] as String,
      contractId: map['contract_id'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.tryParse(map['scheduled_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      visitDate: map['visit_date'] != null
          ? DateTime.tryParse(map['visit_date'] as String)
          : null,
      technicianName: map['technician_name'] as String? ?? '',
      status: map['status'] as String? ?? AppConstants.visitScheduled,
      workDoneNotes: map['work_done_notes'] as String?,
      customerSignatureBase64: map['customer_signature_base64'] as String?,
      technicianSignatureBase64: map['technician_signature_base64'] as String?,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      checklist: checklist,
      partsReplaced: parts,
    );
  }

  ServiceVisit copyWith({
    String? id,
    String? contractId,
    String? customerId,
    DateTime? scheduledDate,
    DateTime? visitDate,
    String? technicianName,
    String? status,
    String? workDoneNotes,
    String? customerSignatureBase64,
    String? technicianSignatureBase64,
    DateTime? completedAt,
    List<ChecklistItem>? checklist,
    List<PartReplaced>? partsReplaced,
  }) {
    return ServiceVisit(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      customerId: customerId ?? this.customerId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      visitDate: visitDate ?? this.visitDate,
      technicianName: technicianName ?? this.technicianName,
      status: status ?? this.status,
      workDoneNotes: workDoneNotes ?? this.workDoneNotes,
      customerSignatureBase64:
          customerSignatureBase64 ?? this.customerSignatureBase64,
      technicianSignatureBase64:
          technicianSignatureBase64 ?? this.technicianSignatureBase64,
      completedAt: completedAt ?? this.completedAt,
      checklist: checklist ?? this.checklist,
      partsReplaced: partsReplaced ?? this.partsReplaced,
    );
  }
}
