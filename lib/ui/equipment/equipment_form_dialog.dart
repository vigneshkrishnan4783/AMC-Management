import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:amc/data/models/equipment.dart';
import 'package:amc/providers/contract_provider.dart';

class EquipmentFormDialog extends StatefulWidget {
  final String contractId;
  final String customerId;
  final Equipment? equipment;

  const EquipmentFormDialog({
    super.key,
    required this.contractId,
    required this.customerId,
    this.equipment,
  });

  @override
  State<EquipmentFormDialog> createState() => _EquipmentFormDialogState();
}

class _EquipmentFormDialogState extends State<EquipmentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _serialController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment?.name ?? '');
    _brandController = TextEditingController(text: widget.equipment?.brand ?? '');
    _modelController = TextEditingController(text: widget.equipment?.modelNumber ?? '');
    _serialController = TextEditingController(text: widget.equipment?.serialNumber ?? '');
    _locationController = TextEditingController(text: widget.equipment?.location ?? '');
    _notesController = TextEditingController(text: widget.equipment?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final contractProv = context.read<ContractProvider>();
    final isEditing = widget.equipment != null;

    final eq = Equipment(
      id: widget.equipment?.id ?? const Uuid().v4(),
      contractId: widget.contractId,
      customerId: widget.customerId,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
      modelNumber: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
      serialNumber: _serialController.text.trim().isNotEmpty ? _serialController.text.trim() : null,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      installationDate: widget.equipment?.installationDate ?? DateTime.now(),
    );

    if (isEditing) {
      await contractProv.updateEquipment(eq);
    } else {
      await contractProv.addEquipment(eq);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.equipment != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Equipment' : 'Add Covered Equipment',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Equipment / Machine Name *',
                      hintText: 'e.g. Air Handling Unit, 125 kVA DG Set',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter equipment name' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(labelText: 'Brand / Make (e.g. Daikin)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(labelText: 'Model Number'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _serialController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number / Asset Tag',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Physical Location on Site',
                      hintText: 'e.g. Rooftop Plant Room, Basement Yard',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Maintenance Notes / Specs (Optional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _save,
                        child: Text(isEditing ? 'Save Equipment' : 'Add Equipment'),
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
