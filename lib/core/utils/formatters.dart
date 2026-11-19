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

  static String maskPhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    final trimmed = phone.trim();
    if (trimmed.startsWith('+91')) {
      final clean = trimmed.substring(3).replaceAll(RegExp(r'\s+'), '');
      if (clean.length >= 5) {
        return '+91 ${clean.substring(0, 2)}XXX XXXXX';
      }
      return '+91 XXXXX XXXXX';
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return '${digits.substring(0, 2)}XXX XXXXX';
    } else if (digits.length >= 4) {
      return '${digits.substring(0, 2)}XX XXXX';
    }
    return 'XXXXX XXXXX';
  }
}
