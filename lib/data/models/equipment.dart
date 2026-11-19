class Equipment {
  final String id;
  final String contractId;
  final String customerId;
  final String name;
  final String? brand;
  final String? modelNumber;
  final String? serialNumber;
  final String? location;
  final DateTime? installationDate;
  final String? notes;

  Equipment({
    required this.id,
    required this.contractId,
    required this.customerId,
    required this.name,
    this.brand,
    this.modelNumber,
    this.serialNumber,
    this.location,
    this.installationDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_id': contractId,
      'customer_id': customerId,
      'name': name,
      'brand': brand,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'location': location,
      'installation_date': installationDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as String,
      contractId: map['contract_id'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String?,
      modelNumber: map['model_number'] as String?,
      serialNumber: map['serial_number'] as String?,
      location: map['location'] as String?,
      installationDate: map['installation_date'] != null
          ? DateTime.tryParse(map['installation_date'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Equipment copyWith({
    String? id,
    String? contractId,
    String? customerId,
    String? name,
    String? brand,
    String? modelNumber,
    String? serialNumber,
    String? location,
    DateTime? installationDate,
    String? notes,
  }) {
    return Equipment(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      location: location ?? this.location,
      installationDate: installationDate ?? this.installationDate,
      notes: notes ?? this.notes,
    );
  }
}
