import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';
import '../data/models/reminder.dart';

class ReminderProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<Reminder> _reminders = [];
  bool _isLoading = false;

  List<Reminder> get allReminders => _reminders;
  List<Reminder> get pendingReminders =>
      _reminders.where((r) => !r.isSent).toList();
  List<Reminder> get sentReminders =>
      _reminders.where((r) => r.isSent).toList();

  bool get isLoading => _isLoading;

  Future<void> loadReminders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _reminders = await _db.getAllReminders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsSent(String reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index == -1) return;

    final updated = _reminders[index].copyWith(
      isSent: true,
      sentAt: DateTime.now(),
    );

    await _db.updateReminder(updated);
    _reminders[index] = updated;
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    await _db.deleteReminder(id);
    await loadReminders();
  }
}
