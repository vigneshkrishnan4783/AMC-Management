class PartReplaced {
  final String id;
  final String visitId;
  final String partName;
  final String? partNumber;
  final int quantity;
  final double unitCost;
  final String? notes;

  PartReplaced({
    required this.id,
    required this.visitId,
    required this.partName,
    this.partNumber,
    this.quantity = 1,
    this.unitCost = 0.0,
    this.notes,
  });

  double get totalCost => quantity * unitCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_id': visitId,
      'part_name': partName,
      'part_number': partNumber,
      'quantity': quantity,
      'unit_cost': unitCost,
      'notes': notes,
    };
  }

  factory PartReplaced.fromMap(Map<String, dynamic> map) {
    return PartReplaced(
      id: map['id'] as String,
      visitId: map['visit_id'] as String? ?? '',
      partName: map['part_name'] as String? ?? '',
      partNumber: map['part_number'] as String?,
      quantity: (map['quantity'] as int?) ?? 1,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
    );
  }

  PartReplaced copyWith({
    String? id,
    String? visitId,
    String? partName,
    String? partNumber,
    int? quantity,
    double? unitCost,
    String? notes,
  }) {
    return PartReplaced(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      partName: partName ?? this.partName,
      partNumber: partNumber ?? this.partNumber,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      notes: notes ?? this.notes,
    );
  }
}
