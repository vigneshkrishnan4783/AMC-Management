import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/service_visit_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import 'widgets/kpi_card.dart';
import 'widgets/expiry_chart.dart';
import 'widgets/urgent_actions_list.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int tabIndex) onTabSelected;

  const DashboardScreen({super.key, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final contractProv = context.watch<ContractProvider>();
    final visitProv = context.watch<ServiceVisitProvider>();
    final customerProv = context.watch<CustomerProvider>();
    final settingsProv = context.watch<SettingsProvider>();

    final currency = settingsProv.settings.currencySymbol;
    final isDesktop = Breakpoints.isDesktop(context);
    final isTablet = Breakpoints.isTablet(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            contractProv.loadContracts(),
            visitProv.loadVisits(),
            customerProv.loadCustomers(),
          ]);
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Breakpoints.contentMaxWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settingsProv.settings.businessName,
                            style: TextStyle(
                              fontSize: isDesktop ? 24 : 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Annual Maintenance Contract Operations Dashboard',
                            style: TextStyle(
                              fontSize: isDesktop ? 13 : 11,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.statusActive.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.statusActive.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.offline_bolt_rounded, size: 14, color: AppColors.statusActive),
                            SizedBox(width: 6),
                            Text(
                              'SQLite Offline Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusActive,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // KPI Cards Grid (Responsive 1, 2, or 4 columns)
                  _buildKpiGrid(context, contractProv, visitProv, currency),
                  const SizedBox(height: 24),

                  // Middle Section: Chart & Urgent Action Feed
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ExpiryChart(
                            activeCount: contractProv.activeContractsCount,
                            expiringSoonCount: contractProv.expiringSoonCount,
                            expiredCount: contractProv.expiredCount,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 6,
                          child: UrgentActionsList(
                            onNavigateToContracts: () => onTabSelected(2),
                            onNavigateToVisits: () => onTabSelected(3),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        ExpiryChart(
                          activeCount: contractProv.activeContractsCount,
                          expiringSoonCount: contractProv.expiringSoonCount,
                          expiredCount: contractProv.expiredCount,
                        ),
                        const SizedBox(height: 20),
                        UrgentActionsList(
                          onNavigateToContracts: () => onTabSelected(2),
                          onNavigateToVisits: () => onTabSelected(3),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    ContractProvider contractProv,
    ServiceVisitProvider visitProv,
    String currency,
  ) {
    final columns = Breakpoints.gridColumns(context, min: 1, max: 4);

    final kpis = [
      KpiCard(
        title: 'Active Contracts',
        value: '${contractProv.activeContractsCount}',
        subtitle: 'Value: ${Formatters.formatCurrency(contractProv.totalContractValue, symbol: currency)}',
        icon: Icons.verified_user_rounded,
        color: AppColors.statusActive,
        onTap: () {
          contractProv.setStatusFilter('active');
          onTabSelected(2);
        },
      ),
      KpiCard(
        title: 'Expiring Soon (≤30d)',
        value: '${contractProv.expiringSoonCount}',
        subtitle: 'Requires follow-up',
        icon: Icons.schedule_rounded,
        color: AppColors.statusExpiring,
        onTap: () {
          contractProv.setStatusFilter('expiring_soon');
          onTabSelected(2);
        },
      ),
      KpiCard(
        title: 'Overdue / Expired',
        value: '${contractProv.expiredCount}',
        subtitle: 'Immediate renewal',
        icon: Icons.cancel_outlined,
        color: AppColors.statusExpired,
        onTap: () {
          contractProv.setStatusFilter('expired');
          onTabSelected(2);
        },
      ),
      KpiCard(
        title: 'Scheduled Visits',
        value: '${visitProv.scheduledVisitsCount}',
        subtitle: '${visitProv.visitsScheduledToday.length} due today',
        icon: Icons.engineering_rounded,
        color: AppColors.primary,
        onTap: () => onTabSelected(3),
      ),
    ];

    if (columns == 1) {
      return Column(
        children: kpis
            .map((kpi) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: kpi,
                ))
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: kpis
              .map(
                (kpi) => SizedBox(
                  width: itemWidth,
                  child: kpi,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
