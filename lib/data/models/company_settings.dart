class CompanySettings {
  final String businessName;
  final String phone;
  final String email;
  final String address;
  final String? website;
  final String? taxNumber; // GST / VAT / Tax ID
  final String currencySymbol;
  final String? termsTemplate;
  final bool emailNotificationsEnabled;
  final String reminderDaysConfig; // Comma separated, e.g. "30,7,1"
  final String poweredBy;

  CompanySettings({
    this.businessName = 'AMC Management',
    this.phone = '',
    this.email = 'vignesh.krishnan@citrusinfomatics.com',
    this.address = '',
    this.website = '',
    this.taxNumber = '',
    this.currencySymbol = '₹',
    this.termsTemplate = '1. Regular preventative maintenance as per agreed schedule.\n2. Replacement of consumable parts will be charged separately unless covered.\n3. Emergency breakdown calls attended within 24 business hours.',
    this.emailNotificationsEnabled = true,
    this.reminderDaysConfig = '30,7,1',
    this.poweredBy = 'Citrus Informatics',
  });

  List<int> get reminderDays {
    return reminderDaysConfig
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((d) => d > 0)
        .toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'business_name': businessName,
      'phone': phone,
      'email': email,
      'address': address,
      'website': website,
      'tax_number': taxNumber,
      'currency_symbol': currencySymbol,
      'terms_template': termsTemplate,
      'email_notifications_enabled': emailNotificationsEnabled ? 1 : 0,
      'reminder_days_config': reminderDaysConfig,
      'powered_by': poweredBy,
    };
  }

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    return CompanySettings(
      businessName: map['business_name'] as String? ?? 'AMC Management',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? 'vignesh.krishnan@citrusinfomatics.com',
      address: map['address'] as String? ?? '',
      website: map['website'] as String? ?? '',
      taxNumber: map['tax_number'] as String? ?? '',
      currencySymbol: map['currency_symbol'] as String? ?? '₹',
      termsTemplate: map['terms_template'] as String? ??
          '1. Regular preventative maintenance as per agreed schedule.\n2. Replacement of consumable parts will be charged separately.\n3. Emergency breakdown calls attended within 24 hours.',
      emailNotificationsEnabled:
          (map['email_notifications_enabled'] as int? ?? 1) == 1,
      reminderDaysConfig:
          map['reminder_days_config'] as String? ?? '30,7,1',
      poweredBy: map['powered_by'] as String? ?? 'Citrus Informatics',
    );
  }

  CompanySettings copyWith({
    String? businessName,
    String? phone,
    String? email,
    String? address,
    String? website,
    String? taxNumber,
    String? currencySymbol,
    String? termsTemplate,
    bool? emailNotificationsEnabled,
    String? reminderDaysConfig,
    String? poweredBy,
  }) {
    return CompanySettings(
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      website: website ?? this.website,
      taxNumber: taxNumber ?? this.taxNumber,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      termsTemplate: termsTemplate ?? this.termsTemplate,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      reminderDaysConfig: reminderDaysConfig ?? this.reminderDaysConfig,
      poweredBy: poweredBy ?? this.poweredBy,
    );
  }
}
