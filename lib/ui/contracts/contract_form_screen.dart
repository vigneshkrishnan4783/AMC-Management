import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:amc/core/constants/app_constants.dart';
import 'package:amc/core/theme/app_colors.dart';
import 'package:amc/core/utils/breakpoints.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/equipment.dart';
import 'package:amc/data/services/reminder_service.dart';
import 'package:amc/providers/contract_provider.dart';
import 'package:amc/providers/customer_provider.dart';
import 'package:amc/providers/settings_provider.dart';
import 'package:amc/providers/subscription_provider.dart';
import '../subscription/subscription_screen.dart';

class ContractFormScreen extends StatefulWidget {
  final Contract? contract;
  final String? preselectedCustomerId;

  const ContractFormScreen({super.key, this.contract, this.preselectedCustomerId});

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  late TextEditingController _numberController;
  late TextEditingController _titleController;
  late TextEditingController _valueController;
  late TextEditingController _termsController;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  String _paymentStatus = 'Pending';
  String _frequency = 'Quarterly';

  // In-form equipment list
  final List<Equipment> _initialEquipment = [];
  final _eqNameCtrl = TextEditingController();
  final _eqBrandCtrl = TextEditingController();
  final _eqSerialCtrl = TextEditingController();
  final _eqLocationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    _selectedCustomerId = c?.customerId ?? widget.preselectedCustomerId;

    final defaultNumber = 'AMC-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _numberController = TextEditingController(text: c?.contractNumber ?? defaultNumber);
    _titleController = TextEditingController(text: c?.title ?? 'Comprehensive Annual Maintenance Agreement');
    _valueController = TextEditingController(text: c?.contractValue.toStringAsFixed(2) ?? '50000.00');

    final settingsTerms = context.read<SettingsProvider>().settings.termsTemplate;
    _termsController = TextEditingController(text: c?.termsAndConditions ?? settingsTerms ?? '');

    if (c != null) {
      _startDate = c.startDate;
      _endDate = c.endDate;
      _paymentStatus = c.paymentStatus;
      _frequency = c.frequency;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _valueController.dispose();
    _termsController.dispose();
    _eqNameCtrl.dispose();
    _eqBrandCtrl.dispose();
    _eqSerialCtrl.dispose();
    _eqLocationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 365));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addInitialEquipment() {
    if (_eqNameCtrl.text.trim().isEmpty) return;

    setState(() {
      _initialEquipment.add(Equipment(
        id: const Uuid().v4(),
        contractId: widget.contract?.id ?? '',
        customerId: _selectedCustomerId ?? '',
        name: _eqNameCtrl.text.trim(),
        brand: _eqBrandCtrl.text.trim().isNotEmpty ? _eqBrandCtrl.text.trim() : null,
        serialNumber: _eqSerialCtrl.text.trim().isNotEmpty ? _eqSerialCtrl.text.trim() : null,
        location: _eqLocationCtrl.text.trim().isNotEmpty ? _eqLocationCtrl.text.trim() : null,
      ));
      _eqNameCtrl.clear();
      _eqBrandCtrl.clear();
      _eqSerialCtrl.clear();
      _eqLocationCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer for this contract')),
      );
      return;
    }

    final contractProv = context.read<ContractProvider>();
    final customerProv = context.read<CustomerProvider>();
    final settingsProv = context.read<SettingsProvider>();
    final subProv = context.read<SubscriptionProvider>();

    final isEditing = widget.contract != null;

    if (!isEditing && !subProv.canCreateRecords) {
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
            'Your 30-day evaluation trial has ended. To create new AMC contracts, please subscribe to a plan or enter an activation license key.\n\nAll existing contracts, customer data, and documents remain permanently safe and accessible.',
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

    final contractId = widget.contract?.id ?? const Uuid().v4();

    final contract = Contract(
      id: contractId,
      contractNumber: _numberController.text.trim(),
      title: _titleController.text.trim(),
      customerId: _selectedCustomerId!,
      startDate: _startDate,
      endDate: _endDate,
      contractValue: double.tryParse(_valueController.text.trim()) ?? 0.0,
      paymentStatus: _paymentStatus,
      frequency: _frequency,
      termsAndConditions: _termsController.text.trim().isNotEmpty ? _termsController.text.trim() : null,
      status: widget.contract?.status ?? AppConstants.statusActive,
      createdAt: widget.contract?.createdAt ?? DateTime.now(),
    );

    // Update equipment foreign keys if added in form
    final equipmentToInsert = _initialEquipment.map((eq) {
      return eq.copyWith(contractId: contractId, customerId: _selectedCustomerId);
    }).toList();

    if (isEditing) {
      await contractProv.updateContract(contract);
    } else {
      await contractProv.addContract(contract, equipmentToInsert);

      // Auto-schedule reminders
      final customer = await customerProv.getCustomerById(_selectedCustomerId!);
      if (customer != null) {
        await ReminderService.syncContractReminders(
          contract: contract,
          customer: customer,
          settings: settingsProv.settings,
        );
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProv = context.watch<CustomerProvider>();
    final customers = customerProv.customers;
    final isEditing = widget.contract != null;
    final isDesktop = Breakpoints.isDesktop(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Contract' : 'Create New AMC Contract'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(isEditing ? 'Save Changes' : 'Save Contract'),
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
                  // Client & Core Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('1. CLIENT & AGREEMENT DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: const InputDecoration(
                              labelText: 'Select Customer *',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: customers.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.name} ${c.company != null ? "(${c.company})" : ""}'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCustomerId = val),
                            validator: (v) => v == null ? 'Please select a customer' : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _numberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contract Reference # *',
                                    prefixIcon: Icon(Icons.tag),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Agreement Title *',
                                    prefixIcon: Icon(Icons.title),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contract Duration & Value Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('2. DURATION, FREQUENCY & PAYMENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickDate(true),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Date',
                                      prefixIcon: Icon(Icons.calendar_today_outlined),
                                    ),
                                    child: Text(dateFormat.format(_startDate)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickDate(false),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Date (Expiry)',
                                      prefixIcon: Icon(Icons.event_busy_outlined),
                                    ),
                                    child: Text(dateFormat.format(_endDate)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _valueController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Contract Value *',
                                    prefixIcon: Icon(Icons.currency_rupee),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _paymentStatus,
                                  decoration: const InputDecoration(labelText: 'Payment Status'),
                                  items: ['Paid', 'Partial', 'Pending'].map((p) {
                                    return DropdownMenuItem(value: p, child: Text(p));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _paymentStatus = val!),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _frequency,
                                  decoration: const InputDecoration(labelText: 'Service Visit Frequency'),
                                  items: AppConstants.visitFrequencies.map((f) {
                                    return DropdownMenuItem(value: f, child: Text(f));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _frequency = val!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Initial Equipment (if adding new contract)
                  if (!isEditing) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('3. REGISTER COVERED EQUIPMENT (OPTIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: _eqNameCtrl, decoration: const InputDecoration(labelText: 'Equipment Name'))),
                                const SizedBox(width: 10),
                                Expanded(child: TextField(controller: _eqBrandCtrl, decoration: const InputDecoration(labelText: 'Brand / Make'))),
                                const SizedBox(width: 10),
                                Expanded(child: TextField(controller: _eqSerialCtrl, decoration: const InputDecoration(labelText: 'Serial Number'))),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: _addInitialEquipment,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Item'),
                                ),
                              ],
                            ),
                            if (_initialEquipment.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ..._initialEquipment.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final eq = entry.value;
                                return ListTile(
                                  dense: true,
                                  title: Text('${eq.name} (${eq.brand ?? ""})'),
                                  subtitle: Text('Serial: ${eq.serialNumber ?? "N/A"}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () => setState(() => _initialEquipment.removeAt(idx)),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Terms & Conditions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('4. TERMS & CONDITIONS / SCOPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _termsController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Enter specific terms, SLA, or parts exclusions for this contract...',
                            ),
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
                        label: Text(isEditing ? 'Save Changes' : 'Create Contract'),
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
