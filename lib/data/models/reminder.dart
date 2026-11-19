class Reminder {
  final String id;
  final String contractId;
  final String customerId;
  final int triggerDaysBefore;
  final DateTime scheduledDate;
  final bool isSent;
  final DateTime? sentAt;
  final String reminderType; // 'email', 'notification'
  final String recipientEmail;
  final String? notes;

  Reminder({
    required this.id,
    required this.contractId,
    required this.customerId,
    required this.triggerDaysBefore,
    required this.scheduledDate,
    this.isSent = false,
    this.sentAt,
    this.reminderType = 'email',
    required this.recipientEmail,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_id': contractId,
      'customer_id': customerId,
      'trigger_days_before': triggerDaysBefore,
      'scheduled_date': scheduledDate.toIso8601String(),
      'is_sent': isSent ? 1 : 0,
      'sent_at': sentAt?.toIso8601String(),
      'reminder_type': reminderType,
      'recipient_email': recipientEmail,
      'notes': notes,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      contractId: map['contract_id'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      triggerDaysBefore: (map['trigger_days_before'] as int?) ?? 30,
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.tryParse(map['scheduled_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSent: (map['is_sent'] as int? ?? 0) == 1,
      sentAt: map['sent_at'] != null
          ? DateTime.tryParse(map['sent_at'] as String)
          : null,
      reminderType: map['reminder_type'] as String? ?? 'email',
      recipientEmail: map['recipient_email'] as String? ?? '',
      notes: map['notes'] as String?,
    );
  }

  Reminder copyWith({
    String? id,
    String? contractId,
    String? customerId,
    int? triggerDaysBefore,
    DateTime? scheduledDate,
    bool? isSent,
    DateTime? sentAt,
    String? reminderType,
    String? recipientEmail,
    String? notes,
  }) {
    return Reminder(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      customerId: customerId ?? this.customerId,
      triggerDaysBefore: triggerDaysBefore ?? this.triggerDaysBefore,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isSent: isSent ?? this.isSent,
      sentAt: sentAt ?? this.sentAt,
      reminderType: reminderType ?? this.reminderType,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      notes: notes ?? this.notes,
    );
  }
}
