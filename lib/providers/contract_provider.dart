import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';
import '../data/models/contract.dart';
import '../data/models/equipment.dart';

class ContractProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<Contract> _contracts = [];
  bool _isLoading = false;
  String _statusFilter = 'all'; // 'all', 'active', 'expiring_soon', 'expired'
  String _searchQuery = '';

  List<Contract> get allContracts => _contracts;

  List<Contract> get filteredContracts {
    var list = _contracts;

    // Filter by status
    if (_statusFilter != 'all') {
      list = list.where((c) {
        final comp = c.computedStatus;
        if (_statusFilter == 'expiring_soon') {
          return comp == 'expiring_soon';
        } else if (_statusFilter == 'expired') {
          return comp == 'expired';
        } else if (_statusFilter == 'active') {
          return comp == 'active';
        }
        return true;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.contractNumber.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  bool get isLoading => _isLoading;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  // KPI calculations
  int get totalContractsCount => _contracts.length;
  int get activeContractsCount =>
      _contracts.where((c) => c.computedStatus == 'active').length;
  int get expiringSoonCount =>
      _contracts.where((c) => c.computedStatus == 'expiring_soon').length;
  int get expiredCount =>
      _contracts.where((c) => c.computedStatus == 'expired').length;
  double get totalContractValue =>
      _contracts.fold(0.0, (sum, c) => sum + c.contractValue);

  Future<void> loadContracts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _contracts = await _db.getAllContracts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addContract(Contract contract, [List<Equipment>? equipmentList]) async {
    await _db.insertContract(contract);
    if (equipmentList != null) {
      for (final eq in equipmentList) {
        await _db.insertEquipment(eq);
      }
    }
    await loadContracts();
  }

  Future<void> updateContract(Contract contract) async {
    await _db.updateContract(contract);
    await loadContracts();
  }

  Future<void> deleteContract(String id) async {
    await _db.deleteContract(id);
    await loadContracts();
  }

  Future<List<Equipment>> getEquipmentForContract(String contractId) async {
    return await _db.getEquipmentByContractId(contractId);
  }

  Future<void> addEquipment(Equipment equipment) async {
    await _db.insertEquipment(equipment);
    notifyListeners();
  }

  Future<void> updateEquipment(Equipment equipment) async {
    await _db.updateEquipment(equipment);
    notifyListeners();
  }

  Future<void> deleteEquipment(String id) async {
    await _db.deleteEquipment(id);
    notifyListeners();
  }
}
