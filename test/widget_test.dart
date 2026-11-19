import 'package:flutter_test/flutter_test.dart';
import 'package:amc/data/models/contract.dart';

void main() {
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
}
