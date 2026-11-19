import '../../core/constants/app_constants.dart';

class Contract {
  final String id;
  final String contractNumber;
  final String title;
  final String customerId;
  final DateTime startDate;
  final DateTime endDate;
  final double contractValue;
  final String paymentStatus; // 'Paid', 'Partial', 'Pending'
  final String frequency; // 'Monthly', 'Quarterly', 'Bi-Annual', 'Annual', 'On-Demand'
  final String? termsAndConditions;
  final String status; // 'active', 'expiring_soon', 'expired', 'terminated'
  final DateTime createdAt;

  Contract({
    required this.id,
    required this.contractNumber,
    required this.title,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    required this.contractValue,
    required this.paymentStatus,
    required this.frequency,
    this.termsAndConditions,
    required this.status,
    required this.createdAt,
  });

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(endDate.year, endDate.month, endDate.day);
    return expiry.difference(today).inDays;
  }

  String get computedStatus {
    if (status == AppConstants.statusTerminated) {
      return AppConstants.statusTerminated;
    }
    final days = daysUntilExpiry;
    if (days < 0) {
      return AppConstants.statusExpired;
    } else if (days <= 30) {
      return AppConstants.statusExpiringSoon;
    } else {
      return AppConstants.statusActive;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_number': contractNumber,
      'title': title,
      'customer_id': customerId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'contract_value': contractValue,
      'payment_status': paymentStatus,
      'frequency': frequency,
      'terms_and_conditions': termsAndConditions,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Contract.fromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'] as String,
      contractNumber: map['contract_number'] as String? ?? '',
      title: map['title'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.tryParse(map['end_date'] as String) ?? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 365)),
      contractValue: (map['contract_value'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['payment_status'] as String? ?? 'Pending',
      frequency: map['frequency'] as String? ?? 'Quarterly',
      termsAndConditions: map['terms_and_conditions'] as String?,
      status: map['status'] as String? ?? AppConstants.statusActive,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Contract copyWith({
    String? id,
    String? contractNumber,
    String? title,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    double? contractValue,
    String? paymentStatus,
    String? frequency,
    String? termsAndConditions,
    String? status,
    DateTime? createdAt,
  }) {
    return Contract(
      id: id ?? this.id,
      contractNumber: contractNumber ?? this.contractNumber,
      title: title ?? this.title,
      customerId: customerId ?? this.customerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      contractValue: contractValue ?? this.contractValue,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      frequency: frequency ?? this.frequency,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
