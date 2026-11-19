class AppConstants {
  static const String appName = 'AMC Manager';
  static const String appVersion = '1.0.0';

  // Visit frequencies
  static const List<String> visitFrequencies = [
    'Monthly',
    'Quarterly',
    'Bi-Annual',
    'Annual',
    'On-Demand',
  ];

  // Contract statuses
  static const String statusActive = 'active';
  static const String statusExpiringSoon = 'expiring_soon';
  static const String statusExpired = 'expired';
  static const String statusTerminated = 'terminated';

  // Visit statuses
  static const String visitScheduled = 'scheduled';
  static const String visitInProgress = 'in_progress';
  static const String visitCompleted = 'completed';
  static const String visitCancelled = 'cancelled';

  // Reminder alert thresholds in days
  static const List<int> defaultReminderDays = [30, 7, 1];
}
