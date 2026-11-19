import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/customer.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import 'contract_detail_screen.dart';
import 'contract_form_screen.dart';

class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contractProv = context.watch<ContractProvider>();
    final customerProv = context.watch<CustomerProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    final contracts = contractProv.filteredContracts;
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
                          'AMC Contracts Management',
                          style: TextStyle(
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Track active agreements, upcoming expiries, and renewals',
                          style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContractFormScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New AMC Contract'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search & Filter Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: contractProv.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search by contract number, title...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: contractProv.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => contractProv.setSearchQuery(''),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(context, 'All (${contractProv.totalContractsCount})', 'all', contractProv),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'Active (${contractProv.activeContractsCount})', 'active', contractProv),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'Expiring Soon (${contractProv.expiringSoonCount})', 'expiring_soon', contractProv),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'Expired (${contractProv.expiredCount})', 'expired', contractProv),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Contracts Content
                if (contractProv.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (contracts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.description_outlined, size: 48, color: AppColors.lightTextSecondary),
                            SizedBox(height: 12),
                            Text('No contracts match your filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text(
                              'Try selecting a different status filter or clear the search query.',
                              style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _buildContractsLayout(context, contracts, customerProv, currency),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, ContractProvider prov) {
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

  Widget _buildContractsLayout(
    BuildContext context,
    List<Contract> contracts,
    CustomerProvider customerProv,
    String currency,
  ) {
    final columns = Breakpoints.gridColumns(context, min: 1, max: 2);

    if (columns == 1) {
      return Column(
        children: contracts.map((c) => _buildContractCard(context, c, customerProv, currency)).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: contracts
              .map(
                (c) => SizedBox(
                  width: itemWidth,
                  child: _buildContractCard(context, c, customerProv, currency),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildContractCard(
    BuildContext context,
    Contract contract,
    CustomerProvider customerProv,
    String currency,
  ) {
    final customer = customerProv.customers.cast<Customer?>().firstWhere(
          (c) => c?.id == contract.customerId,
          orElse: () => null,
        );

    final statusColor = Formatters.getContractStatusColor(contract.computedStatus);
    final days = contract.daysUntilExpiry;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContractDetailScreen(contractId: contract.id),
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
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          contract.contractNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            Formatters.formatStatusLabel(contract.computedStatus),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(contract.contractValue, symbol: currency),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                contract.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.lightTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${customer?.name ?? "Customer"} ${customer?.company != null ? "• ${customer!.company}" : ""}',
                    style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frequency: ${contract.frequency}',
                    style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                  ),
                  Text(
                    days < 0 ? 'Expired ${-days} days ago' : '$days days left',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: days < 0 ? AppColors.statusExpired : (days <= 30 ? AppColors.statusExpiring : AppColors.statusActive),
                    ),
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
