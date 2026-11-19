import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/customer.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/reminder_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import 'reminder_email_preview_dialog.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reminderProv = context.watch<ReminderProvider>();
    final contractProv = context.watch<ContractProvider>();
    final customerProv = context.watch<CustomerProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    final reminders = reminderProv.allReminders;
    final pendingCount = reminderProv.pendingReminders.length;
    final sentCount = reminderProv.sentReminders.length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoints.contentMaxWidth(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contract Renewal Reminders',
                          style: TextStyle(
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automated notification schedule ($pendingCount pending, $sentCount sent)',
                          style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Content
                if (reminderProv.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (reminders.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: AppColors.lightTextSecondary),
                            SizedBox(height: 12),
                            Text('No renewal reminders scheduled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text(
                              'Reminders are automatically created when new AMC contracts are added.',
                              style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...reminders.map((r) {
                    final contract = contractProv.allContracts.cast<Contract?>().firstWhere(
                          (c) => c?.id == r.contractId,
                          orElse: () => null,
                        );

                    final customer = customerProv.customers.cast<Customer?>().firstWhere(
                          (c) => c?.id == r.customerId,
                          orElse: () => null,
                        );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: r.isSent
                                    ? AppColors.statusActive.withOpacity(0.12)
                                    : AppColors.statusExpiring.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                r.isSent ? Icons.check_circle_outline : Icons.outgoing_mail,
                                color: r.isSent ? AppColors.statusActive : AppColors.statusExpiring,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        customer?.name ?? 'Customer',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (customer?.company != null) ...[
                                        const SizedBox(width: 6),
                                        Text('(${customer!.company})', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                                      ],
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: r.isSent ? AppColors.statusActive.withOpacity(0.15) : AppColors.statusExpiring.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          r.isSent ? 'SENT' : 'DUE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: r.isSent ? AppColors.statusActive : AppColors.statusExpiring,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contract: ${contract?.contractNumber ?? "N/A"} (${contract?.title ?? ""})',
                                    style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Alert: ${r.triggerDaysBefore} days before expiry • Send to: ${r.recipientEmail}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (!r.isSent && contract != null && customer != null)
                              FilledButton.icon(
                                onPressed: () async {
                                  final eqList = await contractProv.getEquipmentForContract(contract.id);
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (_) => ReminderEmailPreviewDialog(
                                        contract: contract,
                                        customer: customer,
                                        equipmentList: eqList,
                                        settings: settingsProv.settings,
                                        reminderId: r.id,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.send_rounded, size: 14),
                                label: const Text('Send Email', style: TextStyle(fontSize: 12)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                            else if (r.isSent)
                              Text(
                                'Sent: ${Formatters.formatDate(r.sentAt)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.statusActive, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
