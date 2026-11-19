import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amc/core/utils/formatters.dart';
import 'package:amc/data/models/contract.dart';
import 'package:amc/data/models/company_settings.dart';
import 'package:amc/providers/subscription_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Contract daysUntilExpiry and status calculation test', () {
    final now = DateTime.now();

    // Active contract (ends in 100 days)
    final activeContract = Contract(
      id: '1',
      contractNumber: 'AMC-001',
      title: 'AC Maintenance',
      customerId: 'cust-1',
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 100)),
      contractValue: 50000,
      paymentStatus: 'Paid',
      frequency: 'Quarterly',
      status: 'active',
      createdAt: now,
    );

    expect(activeContract.daysUntilExpiry, inInclusiveRange(99, 101));
    expect(activeContract.computedStatus, 'active');

    // Expiring soon contract (ends in 15 days)
    final expiringContract = activeContract.copyWith(
      endDate: now.add(const Duration(days: 15)),
    );
    expect(expiringContract.computedStatus, 'expiring_soon');

    // Expired contract (ended 5 days ago)
    final expiredContract = activeContract.copyWith(
      endDate: now.subtract(const Duration(days: 5)),
    );
    expect(expiredContract.computedStatus, 'expired');
  });

  test('CompanySettings has clean defaults with correct user email and branding', () {
    final settings = CompanySettings();
    expect(settings.email, 'vigneshkrishnan4786@gmail.com');
    expect(settings.phone, ''); // No hardcoded fake phone
    expect(settings.address, ''); // No hardcoded fake address
    expect(settings.businessName, ''); // No hardcoded fake business name
    expect(settings.poweredBy, 'ZtoH Software');
  });

  test('Formatters maskPhoneNumber hides digits with XXXXX', () {
    expect(Formatters.maskPhoneNumber('+91 97410 55667'), '+91 97XXX XXXXX');
    expect(Formatters.maskPhoneNumber('9845011223'), '98XXX XXXXX');
    expect(Formatters.maskPhoneNumber(''), '');
  });

  test('SubscriptionProvider initializes 30-day trial and activates plans', () async {
    SharedPreferences.setMockInitialValues({});
    final subProv = SubscriptionProvider();
    await subProv.init();

    expect(subProv.isInitialized, true);
    expect(subProv.isSubscribed, false);
    expect(subProv.daysRemaining, inInclusiveRange(29, 30));
    expect(subProv.canCreateRecords, true);

    // Test subscribing to Monthly Plan (₹300/mo)
    await subProv.subscribeToPlan('Monthly Subscription');
    expect(subProv.isSubscribed, true);
    expect(subProv.canCreateRecords, true);
    expect(subProv.planName, 'Monthly Subscription');
  });
}
