import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';
import '../data/models/service_visit.dart';

class ServiceVisitProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<ServiceVisit> _visits = [];
  bool _isLoading = false;
  String _statusFilter = 'all'; // 'all', 'scheduled', 'in_progress', 'completed'
  String _searchQuery = '';

  List<ServiceVisit> get allVisits => _visits;

  List<ServiceVisit> get filteredVisits {
    var list = _visits;

    if (_statusFilter != 'all') {
      list = list.where((v) => v.status == _statusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((v) {
        return v.technicianName.toLowerCase().contains(q) ||
            (v.workDoneNotes != null && v.workDoneNotes!.toLowerCase().contains(q));
      }).toList();
    }

    return list;
  }

  bool get isLoading => _isLoading;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  // KPIs
  int get scheduledVisitsCount =>
      _visits.where((v) => v.status == 'scheduled').length;
  int get inProgressVisitsCount =>
      _visits.where((v) => v.status == 'in_progress').length;
  int get completedVisitsCount =>
      _visits.where((v) => v.status == 'completed').length;

  List<ServiceVisit> get visitsScheduledToday {
    final now = DateTime.now();
    return _visits.where((v) {
      return v.scheduledDate.year == now.year &&
          v.scheduledDate.month == now.month &&
          v.scheduledDate.day == now.day &&
          v.status != 'completed';
    }).toList();
  }

  List<ServiceVisit> get visitsUpcomingWeek {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _visits.where((v) {
      return v.scheduledDate.isAfter(now.subtract(const Duration(days: 1))) &&
          v.scheduledDate.isBefore(nextWeek) &&
          v.status != 'completed';
    }).toList();
  }

  Future<void> loadVisits() async {
    _isLoading = true;
    notifyListeners();
    try {
      _visits = await _db.getAllServiceVisits();
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

  Future<void> addVisit(ServiceVisit visit) async {
    await _db.insertServiceVisit(visit);
    await loadVisits();
  }

  Future<void> updateVisit(ServiceVisit visit) async {
    await _db.updateServiceVisit(visit);
    await loadVisits();
  }

  Future<void> deleteVisit(String id) async {
    await _db.deleteServiceVisit(id);
    await loadVisits();
  }

  Future<void> toggleChecklistItem(String visitId, String itemId) async {
    final visitIndex = _visits.indexWhere((v) => v.id == visitId);
    if (visitIndex == -1) return;

    final visit = _visits[visitIndex];
    final updatedChecklist = visit.checklist.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isDone: !item.isDone);
      }
      return item;
    }).toList();

    final updatedVisit = visit.copyWith(checklist: updatedChecklist);
    await _db.updateServiceVisit(updatedVisit);
    _visits[visitIndex] = updatedVisit;
    notifyListeners();
  }

  Future<void> markVisitCompleted(String visitId, {String? notes}) async {
    final visitIndex = _visits.indexWhere((v) => v.id == visitId);
    if (visitIndex == -1) return;

    final visit = _visits[visitIndex];
    final updatedVisit = visit.copyWith(
      status: 'completed',
      visitDate: DateTime.now(),
      completedAt: DateTime.now(),
      workDoneNotes: notes ?? visit.workDoneNotes,
    );

    await _db.updateServiceVisit(updatedVisit);
    await loadVisits();
  }
}
