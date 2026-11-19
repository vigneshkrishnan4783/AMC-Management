import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/constants/app_constants.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/customer.dart';
import 'package:amc/data/models/service_visit.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/service_visit_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import 'service_visit_detail_screen.dart';
import 'service_visit_form_screen.dart';

class ServiceVisitsScreen extends StatelessWidget {
  const ServiceVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final visitProv = context.watch<ServiceVisitProvider>();
    final customerProv = context.watch<CustomerProvider>();
    final contractProv = context.watch<ContractProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    final visits = visitProv.filteredVisits;
    final currency = settingsProv.settings.currencySymbol;

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
                          'Service Visits & Field Maintenance',
                          style: TextStyle(
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Execute checklists, record parts replaced, and capture signatures',
                          style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ServiceVisitFormScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_task_outlined, size: 18),
                      label: const Text('Schedule Visit'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  onChanged: visitProv.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search by technician name, work notes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: visitProv.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => visitProv.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All (${visitProv.allVisits.length})', 'all', visitProv),
                      const SizedBox(width: 8),
                      _buildFilterChip('Scheduled (${visitProv.scheduledVisitsCount})', AppConstants.visitScheduled, visitProv),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Progress (${visitProv.inProgressVisitsCount})', AppConstants.visitInProgress, visitProv),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed (${visitProv.completedVisitsCount})', AppConstants.visitCompleted, visitProv),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Visits Content
                if (visitProv.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (visits.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.build_circle_outlined, size: 48, color: AppColors.lightTextSecondary),
                            SizedBox(height: 12),
                            Text('No service visits found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text(
                              'Schedule a new routine or breakdown visit to track work done.',
                              style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _buildVisitsLayout(context, visits, customerProv, contractProv, currency),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ServiceVisitProvider prov) {
    final isSelected = prov.statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => prov.setStatusFilter(value),
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : null,
      ),
    );
  }

  Widget _buildVisitsLayout(
    BuildContext context,
    List<ServiceVisit> visits,
    CustomerProvider customerProv,
    ContractProvider contractProv,
    String currency,
  ) {
    final columns = Breakpoints.gridColumns(context, min: 1, max: 2);

    if (columns == 1) {
      return Column(
        children: visits.map((v) => _buildVisitCard(context, v, customerProv, contractProv, currency)).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: visits
              .map(
                (v) => SizedBox(
                  width: itemWidth,
                  child: _buildVisitCard(context, v, customerProv, contractProv, currency),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildVisitCard(
    BuildContext context,
    ServiceVisit visit,
    CustomerProvider customerProv,
    ContractProvider contractProv,
    String currency,
  ) {
    final customer = customerProv.customers.cast<Customer?>().firstWhere(
          (c) => c?.id == visit.customerId,
          orElse: () => null,
        );

    final contract = contractProv.allContracts.cast<Contract?>().firstWhere(
          (c) => c?.id == visit.contractId,
          orElse: () => null,
        );

    final statusColor = Formatters.getVisitStatusColor(visit.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceVisitDetailScreen(visitId: visit.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.build_circle_outlined, color: statusColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tech: ${visit.technicianName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      visit.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${customer?.name ?? "Customer"} ${customer?.company != null ? "(${customer!.company})" : ""}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Contract: ${contract?.contractNumber ?? "N/A"} — ${contract?.title ?? ""}',
                style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatDateTime(visit.visitDate ?? visit.scheduledDate),
                    style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                  ),
                  Row(
                    children: [
                      if (visit.checklist.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Checklist: ${visit.completedChecklistCount}/${visit.checklist.length}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      if (visit.partsReplaced.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Parts: ${Formatters.formatCurrency(visit.totalPartsCost, symbol: currency)}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ],
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
