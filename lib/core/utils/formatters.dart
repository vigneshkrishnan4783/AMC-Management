import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class Formatters {
  static final DateFormat dateStandard = DateFormat('MMM dd, yyyy');
  static final DateFormat dateTimeStandard = DateFormat('MMM dd, yyyy - hh:mm a');
  static final DateFormat dateIso = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return dateStandard.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return dateTimeStandard.format(date);
  }

  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  static Color getContractStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.statusActive;
      case 'expiring_soon':
      case 'expiring soon':
        return AppColors.statusExpiring;
      case 'expired':
        return AppColors.statusExpired;
      case 'terminated':
        return AppColors.lightTextSecondary;
      default:
        return AppColors.primary;
    }
  }

  static Color getVisitStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.statusCompleted;
      case 'in_progress':
      case 'in progress':
        return AppColors.primaryLight;
      case 'scheduled':
        return AppColors.statusPending;
      case 'cancelled':
        return AppColors.statusExpired;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  static String formatStatusLabel(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }
}
