import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/service_visit.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/service_visit_provider.dart';
import '../../contracts/contract_detail_screen.dart';
import '../../service_visits/service_visit_detail_screen.dart';

class UrgentActionsList extends StatelessWidget {
  final VoidCallback onNavigateToContracts;
  final VoidCallback onNavigateToVisits;

  const UrgentActionsList({
    super.key,
    required this.onNavigateToContracts,
    required this.onNavigateToVisits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractProv = context.watch<ContractProvider>();
    final visitProv = context.watch<ServiceVisitProvider>();
    final customerProv = context.watch<CustomerProvider>();

    final urgentContracts = contractProv.allContracts
        .where((c) => c.computedStatus == 'expiring_soon' || c.computedStatus == 'expired')
        .toList();

    final todayVisits = visitProv.visitsScheduledToday;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.statusExpiring.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.statusExpiring, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Needs Attention Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${urgentContracts.length + todayVisits.length} items',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (urgentContracts.isEmpty && todayVisits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.statusActive, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'All caught up! No urgent contracts or visits today.',
                        style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Today Visits
              if (todayVisits.isNotEmpty) ...[
                Text(
                  'SCHEDULED VISITS TODAY (${todayVisits.length})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                ...todayVisits.map((v) => _buildVisitItem(context, v, customerProv)),
                const SizedBox(height: 14),
              ],

              // Expiring & Expired Contracts
              if (urgentContracts.isNotEmpty) ...[
                Text(
                  'CONTRACTS NEEDING RENEWAL (${urgentContracts.length})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusExpiring, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                ...urgentContracts.take(4).map((c) => _buildContractItem(context, c, customerProv)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisitItem(BuildContext context, ServiceVisit visit, CustomerProvider customerProv) {
    final customer = customerProv.customers.cast<dynamic>().firstWhere(
          (c) => c.id == visit.customerId,
          orElse: () => null,
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.build_circle_outlined, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer?.name ?? 'Customer Site Visit',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Tech: ${visit.technicianName} • ${Formatters.formatDateTime(visit.scheduledDate)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceVisitDetailScreen(visitId: visit.id),
                ),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Open Visit', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildContractItem(BuildContext context, Contract contract, CustomerProvider customerProv) {
    final customer = customerProv.customers.cast<dynamic>().firstWhere(
          (c) => c.id == contract.customerId,
          orElse: () => null,
        );

    final days = contract.daysUntilExpiry;
    final isExpired = days < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isExpired ? AppColors.statusExpired : AppColors.statusExpiring).withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isExpired ? AppColors.statusExpired : AppColors.statusExpiring).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isExpired ? AppColors.statusExpired : AppColors.statusExpiring).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpired ? Icons.cancel_outlined : Icons.timer_outlined,
              color: isExpired ? AppColors.statusExpired : AppColors.statusExpiring,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${contract.contractNumber} • ${customer?.name ?? ""} • ${isExpired ? "Expired ${-days} days ago" : "Expires in $days days"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isExpired ? AppColors.statusExpired : AppColors.statusExpiring,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContractDetailScreen(contractId: contract.id),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Review', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
