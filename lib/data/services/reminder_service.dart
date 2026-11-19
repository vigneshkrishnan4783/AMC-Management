import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/contract.dart';
import '../models/customer.dart';
import '../models/equipment.dart';
import '../models/reminder.dart';
import '../models/company_settings.dart';

class ReminderService {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  /// Generate or sync reminders for a contract based on company settings
  static Future<void> syncContractReminders({
    required Contract contract,
    required Customer customer,
    required CompanySettings settings,
  }) async {
    final db = AppDatabase.instance;
    final reminderDays = settings.reminderDays;

    for (final days in reminderDays) {
      final scheduledDate = contract.endDate.subtract(Duration(days: days));

      final reminder = Reminder(
        id: const Uuid().v4(),
        contractId: contract.id,
        customerId: customer.id,
        triggerDaysBefore: days,
        scheduledDate: scheduledDate,
        isSent: false,
        reminderType: 'email',
        recipientEmail: customer.email,
        notes: 'Renewal notice scheduled for $days day(s) before expiry (${_dateFormat.format(contract.endDate)})',
      );

      await db.insertReminder(reminder);
    }
  }

  /// Generate personalized renewal email subject and body
  static Future<Map<String, String>> generateRenewalEmailContent({
    required Contract contract,
    required Customer customer,
    required List<Equipment> equipmentList,
    required CompanySettings settings,
    required int daysRemaining,
  }) async {
    final urgency = daysRemaining <= 0
        ? 'EXPIRATION NOTICE'
        : (daysRemaining <= 7 ? 'URGENT RENEWAL REMINDER' : 'RENEWAL REMINDER');

    final subject = '$urgency: Annual Maintenance Contract [${contract.contractNumber}] - ${customer.company ?? customer.name}';

    final equipmentLines = equipmentList.isNotEmpty
        ? equipmentList.map((e) => '  • ${e.name} (${e.brand ?? ""} ${e.modelNumber ?? ""}) - Serial: ${e.serialNumber ?? "N/A"}').join('\n')
        : '  • All equipment registered under contract ${contract.contractNumber}';

    final body = '''Dear ${customer.name},

Greetings from ${settings.businessName}.

This is a courtesy reminder regarding your Annual Maintenance Contract (${contract.title}), Contract Reference #${contract.contractNumber}.

Contract Details:
• Expiry Date: ${_dateFormat.format(contract.endDate)} (${daysRemaining <= 0 ? "EXPIRED" : "$daysRemaining days remaining"})
• Annual Value: ${settings.currencySymbol} ${contract.contractValue.toStringAsFixed(2)}
• Service Frequency: ${contract.frequency}

Covered Equipment:
$equipmentLines

To ensure uninterrupted service visits, priority breakdown response, and genuine parts coverage, we recommend renewing your contract before expiry.

Please reply to this email or reach us directly at ${settings.phone} / ${settings.email} to confirm your renewal or request an updated quotation.

Thank you for trusting ${settings.businessName}.

Warm regards,

Service Coordination Team
${settings.businessName}
Phone: ${settings.phone}
Email: ${settings.email}
${settings.website ?? ""}
''';

    return {
      'subject': subject,
      'body': body,
    };
  }

  /// Send email by opening the native default mail client with pre-filled content
  static Future<bool> sendEmailViaClient({
    required String recipientEmail,
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: recipientEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}
