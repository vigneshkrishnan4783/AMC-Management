import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _licenseController = TextEditingController();
  bool _isActivating = false;
  String? _activationError;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _handleActivateLicense() async {
    final subProv = context.read<SubscriptionProvider>();
    final key = _licenseController.text.trim();

    if (key.isEmpty) {
      setState(() => _activationError = 'Please enter a valid license key.');
      return;
    }

    setState(() {
      _isActivating = true;
      _activationError = null;
    });

    final success = await subProv.activateLicenseKey(key);

    setState(() => _isActivating = false);

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.success, size: 28),
                SizedBox(width: 8),
                Text('License Activated!'),
              ],
            ),
            content: Text(
              'Thank you! Your license ($key) has been successfully activated. You have full unlimited access to AMC Manager.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Awesome'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _activationError = 'Invalid license key. Keys must start with AMC- or CITRUS-.');
      }
    }
  }

  void _handleSelectPlan(String planTitle, String price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Subscribe to $planTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: $price'),
            const SizedBox(height: 12),
            const Text(
              'Confirm activating this plan for your business? All features will be enabled immediately.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final subProv = context.read<SubscriptionProvider>();
              await subProv.subscribeToPlan(planTitle);
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully subscribed to $planTitle!'),
                  backgroundColor: AppColors.statusActive,
                ),
              );
            },
            child: const Text('Confirm & Activate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subProv = context.watch<SubscriptionProvider>();
    final theme = Theme.of(context);
    final isSubscribed = subProv.isSubscribed;
    final daysRemaining = subProv.daysRemaining;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & Trial'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSubscribed
                      ? [AppColors.success, const Color(0xFF047857)]
                      : daysRemaining > 5
                          ? [AppColors.primary, const Color(0xFF1E3A8A)]
                          : [AppColors.warning, const Color(0xFFB45309)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSubscribed ? 'ACTIVE LICENSE' : '30-DAY FREE TRIAL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        isSubscribed ? Icons.verified : Icons.timer,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSubscribed ? subProv.planName : '$daysRemaining Days Remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSubscribed
                        ? 'Your AMC Manager license is fully active with unlimited records.'
                        : subProv.trialStartDate != null
                            ? 'Trial started: ${DateFormat.yMMMd().format(subProv.trialStartDate!)}. Ends in $daysRemaining days.'
                            : '30-day evaluation trial active.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Data Safety Guarantee Callout
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Data is 100% Safe & Permanent',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Even after the 30-day trial expires, all your previously created customers, contracts, service visit history, and documents remain accessible. No existing data is ever deleted.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Subscription Plans Section
            Text(
              'Choose a Plan',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a suitable tier to continue creating unlimited new contracts and service visits.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Plan 1: Starter Monthly
            _buildPlanCard(
              title: 'Starter Monthly',
              price: '₹499',
              period: '/ month',
              description: 'Ideal for independent technicians and small service setups.',
              features: const [
                'Up to 50 active contracts',
                'Mobile customer e-signature capture',
                'PDF & Word contract generation',
                'Automated renewal reminder emails',
                'Local SQLite offline storage',
              ],
              isPopular: false,
              onSelect: () => _handleSelectPlan('Starter Monthly', '₹499 / month'),
            ),

            const SizedBox(height: 16),

            // Plan 2: Professional Annual (Popular)
            _buildPlanCard(
              title: 'Professional Annual',
              price: '₹3,999',
              period: '/ year (Save 33%)',
              description: 'Best for growing AMC and facility maintenance businesses.',
              features: const [
                'Unlimited contracts & customers',
                'Comprehensive equipment tracking',
                'Full preventative maintenance checklists',
                'Priority automated email notifications',
                'Branded PDF agreements & service reports',
                'Priority customer support',
              ],
              isPopular: true,
              onSelect: () => _handleSelectPlan('Professional Annual', '₹3,999 / year'),
            ),

            const SizedBox(height: 16),

            // Plan 3: Lifetime Enterprise
            _buildPlanCard(
              title: 'Lifetime Enterprise',
              price: '₹9,999',
              period: 'one-time',
              description: 'Perpetual license with no monthly or annual renewal fees.',
              features: const [
                'Unlimited lifetime contracts & visits',
                'No recurring subscription fees ever',
                'Complete database backup & restore',
                'Multi-technician work assignment',
                'All future software updates included',
              ],
              isPopular: false,
              onSelect: () => _handleSelectPlan('Lifetime Enterprise', '₹9,999 one-time'),
            ),

            const SizedBox(height: 32),

            // License Key Activation Section
            Text(
              'Activate with License Key',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'If you received a key from Citrus Informatics or an authorized distributor, enter it here:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _licenseController,
                    decoration: InputDecoration(
                      hintText: 'e.g. CITRUS-2026-PRO or AMC-XXXX',
                      errorText: _activationError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isActivating ? null : _handleActivateLicense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isActivating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Activate', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPopular ? AppColors.primary : AppColors.border,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                'MOST POPULAR / RECOMMENDED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          ' $period',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const Divider(height: 24),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? AppColors.primary : Colors.grey[100],
                      foregroundColor: isPopular ? Colors.white : AppColors.primary,
                      elevation: isPopular ? 1 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Select $title',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
