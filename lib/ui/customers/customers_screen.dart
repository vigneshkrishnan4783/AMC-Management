import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/customer.dart';
import 'package:amc/providers/customer_provider.dart';
import 'customer_detail_screen.dart';
import 'customer_form_dialog.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerProv = context.watch<CustomerProvider>();
    final isDesktop = Breakpoints.isDesktop(context);
    final customers = customerProv.customers;

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
                // Header with Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customers Directory',
                          style: TextStyle(
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${customers.length} total customer accounts',
                          style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CustomerFormDialog(),
                        );
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Add Customer'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  onChanged: customerProv.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name, company, phone, email, or address...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: customerProv.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => customerProv.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Customer List / Grid
                if (customerProv.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (customers.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: AppColors.lightTextSecondary),
                            const SizedBox(height: 12),
                            const Text('No customers found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text(
                              'Try adjusting your search or add a new customer to get started.',
                              style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const CustomerFormDialog(),
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Customer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _buildCustomerLayout(context, customers),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerLayout(BuildContext context, List<Customer> customers) {
    final columns = Breakpoints.gridColumns(context, min: 1, max: 3);

    if (columns == 1) {
      return Column(
        children: customers.map((c) => _buildCustomerCard(context, c)).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: customers
              .map(
                (c) => SizedBox(
                  width: itemWidth,
                  child: _buildCustomerCard(context, c),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customerId: customer.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customer.company != null && customer.company!.isNotEmpty)
                          Text(
                            customer.company!,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.lightTextSecondary),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.lightTextSecondary),
                  const SizedBox(width: 6),
                  Text(Formatters.maskPhoneNumber(customer.phone), style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14, color: AppColors.lightTextSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer.email,
                      style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.lightTextSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer.address,
                      style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                      overflow: TextOverflow.ellipsis,
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
