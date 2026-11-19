import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/customer.dart';
import '../../providers/contract_provider.dart';
import '../../providers/customer_provider.dart';
import '../contracts/contract_detail_screen.dart';
import '../contracts/contract_form_screen.dart';
import 'customer_form_dialog.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerProv = context.watch<CustomerProvider>();
    final contractProv = context.watch<ContractProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    final customer = customerProv.customers.cast<Customer?>().firstWhere(
          (c) => c?.id == customerId,
          orElse: () => null,
        );

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: Text('Customer not found.')),
      );
    }

    final contracts = contractProv.allContracts.where((c) => c.customerId == customer.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CustomerFormDialog(customer: customer),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.statusExpired),
            tooltip: 'Delete Customer',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Customer?'),
                  content: Text('Are you sure you want to delete ${customer.name}? All associated contracts and visits will also be removed.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.statusExpired),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await customerProv.deleteCustomer(customer.id);
                await contractProv.loadContracts();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoints.contentMaxWidth(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Text(
                                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  if (customer.company != null && customer.company!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      customer.company!,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.primary),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.lightTextSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          customer.address,
                                          style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        // Action buttons: Call, Email, Add AMC
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _makePhoneCall(customer.phone),
                              icon: const Icon(Icons.phone, size: 16, color: AppColors.statusActive),
                              label: Text(Formatters.maskPhoneNumber(customer.phone)),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _sendEmail(customer.email),
                              icon: const Icon(Icons.email, size: 16, color: AppColors.primaryLight),
                              label: Text(customer.email),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ContractFormScreen(preselectedCustomerId: customer.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('New AMC Contract'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // AMC Contracts Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AMC Contracts (${contracts.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContractFormScreen(preselectedCustomerId: customer.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Contract'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (contracts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.description_outlined, size: 36, color: AppColors.lightTextSecondary),
                            const SizedBox(height: 8),
                            const Text('No contracts created for this customer yet.', style: TextStyle(color: AppColors.lightTextSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ContractFormScreen(preselectedCustomerId: customer.id),
                                  ),
                                );
                              },
                              child: const Text('Create First AMC'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...contracts.map((contract) {
                    final statusColor = Formatters.getContractStatusColor(contract.computedStatus);
                    final days = contract.daysUntilExpiry;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
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
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(contract.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                              'Valid: ${Formatters.formatDate(contract.startDate)} - ${Formatters.formatDate(contract.endDate)} (${days < 0 ? "Expired" : "$days days left"})',
                              style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContractDetailScreen(contractId: contract.id),
                            ),
                          );
                        },
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
