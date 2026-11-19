import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';
import '../data/models/customer.dart';
import '../data/models/equipment.dart';

class CustomerProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Customer> get customers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.company != null && c.company!.toLowerCase().contains(query)) ||
          c.phone.contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.address.toLowerCase().contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customers = await _db.getAllCustomers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    await _db.insertCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _db.deleteCustomer(id);
    await loadCustomers();
  }

  Future<Customer?> getCustomerById(String id) async {
    return await _db.getCustomerById(id);
  }

  Future<List<Equipment>> getEquipmentForCustomer(String customerId) async {
    return await _db.getEquipmentByCustomerId(customerId);
  }
}
