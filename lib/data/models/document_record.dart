class DocumentRecord {
  final String id;
  final String entityType; // 'contract', 'service_visit'
  final String entityId;
  final String title;
  final String documentType; // 'pdf', 'docx'
  final String filePath;
  final int fileSize;
  final DateTime createdAt;

  DocumentRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.documentType,
    required this.filePath,
    this.fileSize = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'title': title,
      'document_type': documentType,
      'file_path': filePath,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DocumentRecord.fromMap(Map<String, dynamic> map) {
    return DocumentRecord(
      id: map['id'] as String,
      entityType: map['entity_type'] as String? ?? 'contract',
      entityId: map['entity_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      documentType: map['document_type'] as String? ?? 'pdf',
      filePath: map['file_path'] as String? ?? '',
      fileSize: (map['file_size'] as int?) ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
