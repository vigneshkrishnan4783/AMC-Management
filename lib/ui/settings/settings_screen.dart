import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/data/models/company_settings.dart';
import 'package:amc/data/services/backup_service.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/document_provider.dart';
import 'package:amc/providers/reminder_provider.dart';
import 'package:amc/providers/service_visit_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import 'package:amc/providers/subscription_provider.dart';
import '../chatbot/amc_assistant_sheet.dart';
import '../onboarding/onboarding_screen.dart';
import '../subscription/subscription_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _termsCtrl;
  late TextEditingController _reminderDaysCtrl;

  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>().settings;
    _nameCtrl = TextEditingController(text: s.businessName);
    _phoneCtrl = TextEditingController(text: s.phone);
    _emailCtrl = TextEditingController(text: s.email);
    _addressCtrl = TextEditingController(text: s.address);
    _websiteCtrl = TextEditingController(text: s.website ?? '');
    _taxCtrl = TextEditingController(text: s.taxNumber ?? '');
    _currencyCtrl = TextEditingController(text: s.currencySymbol);
    _termsCtrl = TextEditingController(text: s.termsTemplate ?? '');
    _reminderDaysCtrl = TextEditingController(text: s.reminderDaysConfig);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _taxCtrl.dispose();
    _currencyCtrl.dispose();
    _termsCtrl.dispose();
    _reminderDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final newSettings = CompanySettings(
      businessName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isNotEmpty ? _websiteCtrl.text.trim() : null,
      taxNumber: _taxCtrl.text.trim().isNotEmpty ? _taxCtrl.text.trim() : null,
      currencySymbol: _currencyCtrl.text.trim(),
      termsTemplate: _termsCtrl.text.trim().isNotEmpty ? _termsCtrl.text.trim() : null,
      reminderDaysConfig: _reminderDaysCtrl.text.trim(),
    );

    await context.read<SettingsProvider>().updateSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: AppColors.statusActive),
      );
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final backupPath = await BackupService.createBackupArchive();
      await BackupService.shareBackupFile(backupPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup bundle created successfully: $backupPath'),
            backgroundColor: AppColors.statusActive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup error: $e'), backgroundColor: AppColors.statusExpired),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isRestoring = true);
    try {
      final success = await BackupService.restoreFromBackup();
      if (success && mounted) {
        // Reload all data
        await Future.wait([
          context.read<CustomerProvider>().loadCustomers(),
          context.read<ContractProvider>().loadContracts(),
          context.read<ServiceVisitProvider>().loadVisits(),
          context.read<ReminderProvider>().loadReminders(),
          context.read<DocumentProvider>().loadDocuments(),
          context.read<SettingsProvider>().loadSettings(),
        ]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline database and documents restored successfully!'),
              backgroundColor: AppColors.statusActive,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore error: $e'), backgroundColor: AppColors.statusExpired),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoints.contentMaxWidth(context)),
            child: Form(
              key: _formKey,
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
                            'Business Profile & Settings',
                            style: TextStyle(
                              fontSize: isDesktop ? 22 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Configure company headers, renewal alerts, and offline backups',
                            style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save Settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Subscription & 30-Day Evaluation Card
                  Consumer<SubscriptionProvider>(
                    builder: (context, subProv, _) {
                      final isSub = subProv.isSubscribed;
                      final days = subProv.daysRemaining;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSub ? AppColors.success.withOpacity(0.5) : AppColors.primary.withOpacity(0.4),
                          ),
                        ),
                        color: isSub ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSub ? AppColors.success.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSub ? Icons.verified : Icons.workspace_premium_outlined,
                                  color: isSub ? AppColors.success : AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          isSub ? 'Subscription: ${subProv.planName}' : 'Trial Status: $days Days Remaining',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSub ? AppColors.success : AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isSub ? 'ACTIVE' : '30-DAY TRIAL',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Existing records are always safe & permanently preserved. Subscribe or enter license key for new records.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSub ? AppColors.success : AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(isSub ? 'Manage License' : 'Upgrade Plan'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // User Guidelines Walkthrough & Assistant Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.school_outlined, color: AppColors.secondary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('App Guidelines & Walkthrough', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                SizedBox(height: 2),
                                Text(
                                  'Review the onboarding guide slides explaining contract tracking, e-signatures, and PDF export.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const OnboardingScreen(isFromSettings: true),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.slideshow_outlined, size: 16),
                                label: const Text('Guidelines'),
                              ),
                              FilledButton.icon(
                                onPressed: () => AmcAssistantSheet.show(context),
                                icon: const Icon(Icons.smart_toy_outlined, size: 16),
                                label: const Text('Ask Assistant'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Offline Backup & Restore Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('OFFLINE SQLITE BACKUP & RESTORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  SizedBox(height: 2),
                                  Text(
                                    'Save or restore customer, contract, visit records, and document attachments',
                                    style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Wrap(
                            spacing: 14,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isBackingUp ? null : _createBackup,
                                icon: _isBackingUp
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.file_download_outlined, size: 18),
                                label: const Text('Export Backup Bundle (.amcbak)'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isRestoring ? null : _restoreBackup,
                                icon: _isRestoring
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.file_upload_outlined, size: 18),
                                label: const Text('Restore from Backup File'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Appearance Theme Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.palette_outlined, color: AppColors.secondary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Color Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Current theme: ${settingsProv.themeMode == ThemeMode.dark ? "Dark" : "Light"}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: settingsProv.themeMode == ThemeMode.dark,
                            onChanged: (_) => settingsProv.toggleTheme(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Company Profile Form Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('COMPANY PROFILE (FOR PDF & WORD HEADERS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(labelText: 'Company / Business Name *'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _currencyCtrl,
                                  decoration: const InputDecoration(labelText: 'Currency Symbol *'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(labelText: 'Business Phone Number'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  decoration: const InputDecoration(labelText: 'Business Support Email'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _taxCtrl,
                                  decoration: const InputDecoration(labelText: 'GSTIN / VAT / Tax ID'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _websiteCtrl,
                                  decoration: const InputDecoration(labelText: 'Website'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _addressCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: 'Business Physical Address'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Renewal Alert Milestones & Default Terms
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RENEWAL REMINDER MILESTONES & STANDARD TERMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _reminderDaysCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reminder Alert Days (Comma separated, e.g. 30,7,1)',
                              hintText: '30, 7, 1',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _termsCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Default AMC Terms & Scope Template',
                              hintText: 'Enter standard terms included in agreements...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save Settings'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Powered by Citrus Informatics Branding Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'AMC Manager v1.0.0 (Release Build)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'App Powered by Citrus Informatics',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Developer Email: vignesh.krishnan@citrusinfomatics.com',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
