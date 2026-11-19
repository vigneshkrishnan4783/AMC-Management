import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionProvider extends ChangeNotifier {
  static const String _keyTrialStart = 'amc_trial_start_date';
  static const String _keyIsSubscribed = 'amc_is_subscribed';
  static const String _keyPlanName = 'amc_subscription_plan';
  static const String _keyLicenseKey = 'amc_license_key';

  static const int trialDurationDays = 30;

  DateTime? _trialStartDate;
  bool _isSubscribed = false;
  String _planName = 'Free Trial (30 Days)';
  String? _licenseKey;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isSubscribed => _isSubscribed;
  String get planName => _planName;
  String? get licenseKey => _licenseKey;
  DateTime? get trialStartDate => _trialStartDate;

  int get daysRemaining {
    if (_isSubscribed) return 9999;
    if (_trialStartDate == null) return trialDurationDays;
    final now = DateTime.now();
    final elapsed = now.difference(_trialStartDate!).inDays;
    final remaining = trialDurationDays - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isTrialActive => _isSubscribed || daysRemaining > 0;

  bool get canCreateRecords => isTrialActive;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTrialStart = prefs.getString(_keyTrialStart);
    if (savedTrialStart == null) {
      _trialStartDate = DateTime.now();
      await prefs.setString(_keyTrialStart, _trialStartDate!.toIso8601String());
    } else {
      _trialStartDate = DateTime.tryParse(savedTrialStart) ?? DateTime.now();
    }

    _isSubscribed = prefs.getBool(_keyIsSubscribed) ?? false;
    _planName = prefs.getString(_keyPlanName) ?? (_isSubscribed ? 'Pro Plan' : 'Free Trial (30 Days)');
    _licenseKey = prefs.getString(_keyLicenseKey);

    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> activateLicenseKey(String key) async {
    final trimmed = key.trim().toUpperCase();
    if (trimmed.isEmpty) return false;

    // Accepts format: AMC-PRO-*, ZTOH-*, or any 8+ character valid key
    if (trimmed.startsWith('AMC-') || trimmed.startsWith('ZTOH-') || trimmed.length >= 8) {
      final prefs = await SharedPreferences.getInstance();
      _isSubscribed = true;
      _planName = 'Enterprise License (Active)';
      _licenseKey = trimmed;

      await prefs.setBool(_keyIsSubscribed, true);
      await prefs.setString(_keyPlanName, _planName);
      await prefs.setString(_keyLicenseKey, trimmed);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> subscribeToPlan(String planTitle) async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = true;
    _planName = planTitle;

    await prefs.setBool(_keyIsSubscribed, true);
    await prefs.setString(_keyPlanName, _planName);

    notifyListeners();
  }

  Future<void> cancelSubscriptionForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = false;
    _planName = 'Free Trial (30 Days)';
    _licenseKey = null;

    await prefs.setBool(_keyIsSubscribed, false);
    await prefs.setString(_keyPlanName, _planName);
    await prefs.remove(_keyLicenseKey);

    notifyListeners();
  }
}
