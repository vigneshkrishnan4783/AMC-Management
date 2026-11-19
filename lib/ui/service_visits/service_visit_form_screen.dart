import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:amc/core/constants/app_constants.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/data/models/checklist_item.dart';
import 'package:amc/data/models/service_visit.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/service_visit_provider.dart';
import 'package:amc/providers/subscription_provider.dart';
import '../subscription/subscription_screen.dart';

class ServiceVisitFormScreen extends StatefulWidget {
  final String? preselectedContractId;
  final String? preselectedCustomerId;

  const ServiceVisitFormScreen({
    super.key,
    this.preselectedContractId,
    this.preselectedCustomerId,
  });

  @override
  State<ServiceVisitFormScreen> createState() => _ServiceVisitFormScreenState();
}

class _ServiceVisitFormScreenState extends State<ServiceVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  String? _selectedContractId;
  late TextEditingController _techNameCtrl;
  late TextEditingController _notesCtrl;

  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 10, minute: 0);

  final List<String> _checklistTasks = [
    'Comprehensive equipment functional check',
    'Clean air filters, strains, and fans',
    'Inspect electrical wiring and terminal torque',
    'Check operating temperature and pressure levels',
  ];
  final _customTaskCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.preselectedCustomerId;
    _selectedContractId = widget.preselectedContractId;
    _techNameCtrl = TextEditingController(text: 'Suresh Kumar');
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _techNameCtrl.dispose();
    _notesCtrl.dispose();
    _customTaskCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null || _selectedContractId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a Customer and an AMC Contract')),
      );
      return;
    }

    final subProv = context.read<SubscriptionProvider>();
    if (!subProv.canCreateRecords) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.primary),
              SizedBox(width: 8),
              Text('30-Day Trial Expired'),
            ],
          ),
          content: const Text(
            'Your 30-day evaluation trial has ended. To schedule new service visits, please subscribe to a plan (starting at ₹300/mo).\n\nAll existing records and past service visit reports remain permanently safe and accessible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
              child: const Text('Subscribe Now'),
            ),
          ],
        ),
      );
      return;
    }

    final visitId = const Uuid().v4();
    final combinedDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final checklistItems = _checklistTasks.map((task) {
      return ChecklistItem(
        id: const Uuid().v4(),
        visitId: visitId,
        taskDescription: task,
        isDone: false,
      );
    }).toList();

    final visit = ServiceVisit(
      id: visitId,
      contractId: _selectedContractId!,
      customerId: _selectedCustomerId!,
      scheduledDate: combinedDateTime,
      technicianName: _techNameCtrl.text.trim(),
      status: AppConstants.visitScheduled,
      workDoneNotes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      checklist: checklistItems,
    );

    await context.read<ServiceVisitProvider>().addVisit(visit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service visit scheduled successfully!'),
          backgroundColor: AppColors.statusActive,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProv = context.watch<CustomerProvider>();
    final contractProv = context.watch<ContractProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    final customers = customerProv.customers;
    final contracts = _selectedCustomerId != null
        ? contractProv.allContracts.where((c) => c.customerId == _selectedCustomerId).toList()
        : contractProv.allContracts;

    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Service Visit'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Schedule'),
            ),
          ),
        ],
      ),
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
                  // Client & Contract Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('1. SELECT CUSTOMER & CONTRACT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: const InputDecoration(
                              labelText: 'Customer *',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: customers.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.name} ${c.company != null ? "(${c.company})" : ""}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCustomerId = val;
                                _selectedContractId = null;
                              });
                            },
                            validator: (v) => v == null ? 'Please select a customer' : null,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedContractId,
                            decoration: const InputDecoration(
                              labelText: 'Associated AMC Contract *',
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                            items: contracts.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.contractNumber} — ${c.title}'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedContractId = val),
                            validator: (v) => v == null ? 'Please select an AMC contract' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Technician & Schedule Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('2. TECHNICIAN & VISIT SCHEDULE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _techNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Technician Name *',
                              prefixIcon: Icon(Icons.engineering_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: _pickDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Visit Date',
                                      prefixIcon: Icon(Icons.calendar_today_outlined),
                                    ),
                                    child: Text(dateFormat.format(_scheduledDate)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: _pickTime,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Time Slot',
                                      prefixIcon: Icon(Icons.access_time),
                                    ),
                                    child: Text(_scheduledTime.format(context)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Visit Instructions / Objectives (Optional)',
                              hintText: 'e.g. Bring replacement compressor capacitor and oil filter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Service Checklist Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('3. SERVICE CHECKLIST ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 12),
                          ..._checklistTasks.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final task = entry.value;
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.check_box_outline_blank, size: 20),
                              title: Text(task, style: const TextStyle(fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () => setState(() => _checklistTasks.removeAt(idx)),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customTaskCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Add custom inspection / check item...',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (_customTaskCtrl.text.trim().isNotEmpty) {
                                    setState(() {
                                      _checklistTasks.add(_customTaskCtrl.text.trim());
                                      _customTaskCtrl.clear();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Task'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Schedule Service Visit'),
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
}
