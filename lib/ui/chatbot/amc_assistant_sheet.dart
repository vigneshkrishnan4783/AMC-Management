import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../contracts/contracts_screen.dart';
import '../documents/documents_history_screen.dart';
import '../settings/settings_screen.dart';
import '../subscription/subscription_screen.dart';

class AmcAssistantSheet extends StatefulWidget {
  const AmcAssistantSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AmcAssistantSheet(),
    );
  }

  @override
  State<AmcAssistantSheet> createState() => _AmcAssistantSheetState();
}

class _AmcAssistantSheetState extends State<AmcAssistantSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          '👋 Hello! I am your AMC Smart Assistant.\n\nI can help you navigate AMC Manager, manage customer contracts, handle service visit checklists, view/download PDFs, or configure your 30-day trial and company settings.\n\nHow can I help you today?',
      isBot: true,
    ),
  ];

  static const List<String> _suggestedQuestions = [
    'How do I view and download PDFs?',
    'How does the 30-day trial & subscription work?',
    'How to capture customer digital E-Signatures?',
    'How to send contract renewal reminders?',
    'How to update company email and branding?',
    'Will my data be lost after the trial?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage([String? presetText]) {
    final query = presetText ?? _inputController.text.trim();
    if (query.isEmpty) return;

    if (presetText == null) {
      _inputController.clear();
    }

    setState(() {
      _messages.add(_ChatMessage(text: query, isBot: false));
    });
    _scrollToBottom();

    // Generate intelligent response based on keywords
    final response = _findAnswer(query);

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _messages.add(response);
        });
        _scrollToBottom();
      }
    });
  }

  _ChatMessage _findAnswer(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('pdf') || lower.contains('download') || lower.contains('view') || lower.contains('print')) {
      return const _ChatMessage(
        text:
            '📄 **Viewing & Downloading PDFs:**\n\n'
            '1. Go to any **Contract Details** or **Service Visit Details** screen.\n'
            '2. Tap the blue **"View PDF"** button to open the high-resolution interactive in-app previewer.\n'
            '3. Tap **"Download PDF"** to save the agreement or service report directly to your device or browser.\n'
            '4. You can also view past generated documents from the **Documents History** tab.',
        isBot: true,
        actionLabel: 'View Documents History',
        actionType: 'documents',
      );
    }

    if (lower.contains('trial') || lower.contains('30 day') || lower.contains('subscribe') || lower.contains('license') || lower.contains('payment')) {
      return const _ChatMessage(
        text:
            '⭐ **30-Day Free Trial & Subscription:**\n\n'
            '• AMC Manager includes a full-featured **30-Day Free Trial**.\n'
            '• **Data Safety Guarantee:** All customer data, contracts, and documents created during your trial will **NEVER be deleted** or locked out.\n'
            '• After 30 days, to create new contracts or visits, simply subscribe to Starter (₹499/mo), Pro (₹3,999/yr), or enter your Citrus Informatics license key.',
        isBot: true,
        actionLabel: 'Check Subscription & Trial',
        actionType: 'subscription',
      );
    }

    if (lower.contains('lost') || lower.contains('delete') || lower.contains('safe') || lower.contains('after 30')) {
      return const _ChatMessage(
        text:
            '🛡️ **Zero Data Loss Guarantee:**\n\n'
            'Your data is stored locally in your SQLite database. Even when the 30-day evaluation trial ends, all existing customer records, contracts, equipment, service history, and PDF documents remain 100% accessible to view, search, and export.',
        isBot: true,
      );
    }

    if (lower.contains('sign') || lower.contains('e-sign') || lower.contains('signature')) {
      return const _ChatMessage(
        text:
            '✍️ **Digital E-Signature Sign-off:**\n\n'
            '• Open any scheduled Service Visit and tap **"Edit Visit & Sign-off"**.\n'
            '• After marking tasks complete and logging parts replaced, scroll to the **Customer Signature** or **Technician Signature** pad.\n'
            '• Sign directly with your finger or stylus on mobile, and tap "Save".\n'
            '• The captured signature is automatically embedded into the generated PDF Service Report.',
        isBot: true,
      );
    }

    if (lower.contains('renew') || lower.contains('reminder') || lower.contains('expiry') || lower.contains('alert') || lower.contains('email')) {
      return const _ChatMessage(
        text:
            '⏰ **Renewal Alerts & Automated Emails:**\n\n'
            '• Contracts expiring in 30 days, 7 days, or 1 day automatically show up in the **Reminders** tab and Dashboard.\n'
            '• You can tap **"Send Renewal Email"** on any contract to preview and send a customized notification directly to the customer\'s email address.',
        isBot: true,
      );
    }

    if (lower.contains('company') || lower.contains('branding') || lower.contains('name') || lower.contains('phone') || lower.contains('citrus')) {
      return const _ChatMessage(
        text:
            '🏢 **Company Settings & Branding:**\n\n'
            '• Open the **Settings** tab to update your business name, phone number, address, and GST/Tax ID.\n'
            '• The default system email is configured to `vignesh.krishnan@citrusinfomatics.com`.\n'
            '• Powered by Citrus Informatics branding is proudly displayed in the footer.',
        isBot: true,
        actionLabel: 'Open Settings',
        actionType: 'settings',
      );
    }

    if (lower.contains('contract') || lower.contains('add') || lower.contains('create') || lower.contains('new')) {
      return const _ChatMessage(
        text:
            '📋 **Adding New Contracts:**\n\n'
            '1. Navigate to the **Contracts** screen.\n'
            '2. Tap the floating **"+" button**.\n'
            '3. Select the customer, contract title, start and end dates, payment status, and contract value.\n'
            '4. Tap Save. You can then attach covered equipment and schedule periodic visits.',
        isBot: true,
        actionLabel: 'Go to Contracts',
        actionType: 'contracts',
      );
    }

    return _ChatMessage(
      text:
          '💡 **AMC Assistant:**\n\n'
          'I understood you are asking about: "$query".\n\n'
          'Key quick actions you can take:\n'
          '• View and download contract PDFs from any Contract screen.\n'
          '• Check your 30-Day Free Trial status from Settings > Subscription.\n'
          '• Back up your offline SQLite database from Settings > Backup & Restore.\n'
          '• Feel free to tap one of the suggested chips below for step-by-step guidance!',
      isBot: true,
    );
  }

  void _handleAction(String type) {
    Navigator.of(context).pop();
    if (type == 'documents') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DocumentsHistoryScreen()),
      );
    } else if (type == 'subscription') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    } else if (type == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    } else if (type == 'contracts') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ContractsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AMC Help Assistant',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Always online • Powered by Citrus Informatics',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Suggested Questions Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final q = _suggestedQuestions[index];
                return ActionChip(
                  label: Text(
                    q,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _handleSendMessage(q),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Chat Messages Feed
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Row(
                    mainAxisAlignment:
                        msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.isBot) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: msg.isBot ? const Color(0xFFF3F4F6) : AppColors.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(msg.isBot ? 4 : 16),
                              bottomRight: Radius.circular(msg.isBot ? 16 : 4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: msg.isBot ? AppColors.textPrimary : Colors.white,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                              if (msg.actionLabel != null && msg.actionType != null) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _handleAction(msg.actionType!),
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                    label: Text(
                                      msg.actionLabel!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (!msg.isBot) ...[
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, size: 18, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Input Field
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: mediaQuery.viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Ask AMC Assistant anything...',
                      hintStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _handleSendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  final String? actionLabel;
  final String? actionType;

  const _ChatMessage({
    required this.text,
    required this.isBot,
    this.actionLabel,
    this.actionType,
  });
}
