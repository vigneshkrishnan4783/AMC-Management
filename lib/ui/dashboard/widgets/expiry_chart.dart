import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:amc/core/theme/app_colors.dart';

class ExpiryChart extends StatelessWidget {
  final int activeCount;
  final int expiringSoonCount;
  final int expiredCount;

  const ExpiryChart({
    super.key,
    required this.activeCount,
    required this.expiringSoonCount,
    required this.expiredCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = activeCount + expiringSoonCount + expiredCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contract Health Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$total Contracts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (total == 0)
              const SizedBox(
                height: 160,
                child: Center(child: Text('No contract records found')),
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections: [
                            if (activeCount > 0)
                              PieChartSectionData(
                                color: AppColors.statusActive,
                                value: activeCount.toDouble(),
                                title: '$activeCount',
                                radius: 45,
                                titleStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            if (expiringSoonCount > 0)
                              PieChartSectionData(
                                color: AppColors.statusExpiring,
                                value: expiringSoonCount.toDouble(),
                                title: '$expiringSoonCount',
                                radius: 45,
                                titleStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            if (expiredCount > 0)
                              PieChartSectionData(
                                color: AppColors.statusExpired,
                                value: expiredCount.toDouble(),
                                title: '$expiredCount',
                                radius: 45,
                                titleStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend(
                          color: AppColors.statusActive,
                          label: 'Active',
                          count: activeCount,
                          percent: total > 0 ? (activeCount / total * 100).round() : 0,
                        ),
                        const SizedBox(height: 10),
                        _buildLegend(
                          color: AppColors.statusExpiring,
                          label: 'Expiring Soon',
                          count: expiringSoonCount,
                          percent: total > 0 ? (expiringSoonCount / total * 100).round() : 0,
                        ),
                        const SizedBox(height: 10),
                        _buildLegend(
                          color: AppColors.statusExpired,
                          label: 'Overdue / Expired',
                          count: expiredCount,
                          percent: total > 0 ? (expiredCount / total * 100).round() : 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend({
    required Color color,
    required String label,
    required int count,
    required int percent,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count ($percent%)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
