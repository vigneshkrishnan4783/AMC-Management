import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/customer.dart';
import 'package:amc/data/models/equipment.dart';
import 'package:amc/data/models/company_settings.dart';
import 'package:amc/data/services/reminder_service.dart';
import 'package:amc/providers/reminder_provider.dart';

class ReminderEmailPreviewDialog extends StatefulWidget {
  final Contract contract;
  final Customer customer;
  final List<Equipment> equipmentList;
  final CompanySettings settings;
  final String? reminderId;

  const ReminderEmailPreviewDialog({
    super.key,
    required this.contract,
    required this.customer,
    required this.equipmentList,
    required this.settings,
    this.reminderId,
  });

  @override
  State<ReminderEmailPreviewDialog> createState() => _ReminderEmailPreviewDialogState();
}

class _ReminderEmailPreviewDialogState extends State<ReminderEmailPreviewDialog> {
  late TextEditingController _toController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.customer.email);
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
    _generateDraft();
  }

  Future<void> _generateDraft() async {
    final draft = await ReminderService.generateRenewalEmailContent(
      contract: widget.contract,
      customer: widget.customer,
      equipmentList: widget.equipmentList,
      settings: widget.settings,
      daysRemaining: widget.contract.daysUntilExpiry,
    );

    setState(() {
      _subjectController.text = draft['subject'] ?? '';
      _bodyController.text = draft['body'] ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final success = await ReminderService.sendEmailViaClient(
      recipientEmail: _toController.text.trim(),
      subject: _subjectController.text.trim(),
      body: _bodyController.text.trim(),
    );

    if (widget.reminderId != null && mounted) {
      await context.read<ReminderProvider>().markAsSent(widget.reminderId!);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Email client opened with renewal draft!' : 'Could not launch email client automatically.'),
          backgroundColor: success ? AppColors.statusActive : AppColors.statusExpiring,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.outgoing_mail, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Renewal Email Draft',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    TextField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Email (To)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Line',
                        prefixIcon: Icon(Icons.subject),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: _bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText: 'Email Body (Customizable)',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _sendEmail,
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send via Mail Client'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
