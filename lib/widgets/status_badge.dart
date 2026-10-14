import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/utils/formatters.dart';

enum BadgeType { order, payment, store }

class StatusBadge extends StatelessWidget {
  final String status;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.status,
    this.type = BadgeType.order,
  });

  Color get _color {
    switch (status) {
      case 'DELIVERED':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.danger;
      case 'PAID':
      case 'VERIFIED':
        return AppColors.success;
      case 'UNPAID':
        return AppColors.warning;
      case 'ACTIVE':
        return AppColors.success;
      case 'INACTIVE':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (type) {
      case BadgeType.order:
        return Formatters.orderStatus(status);
      case BadgeType.payment:
        return Formatters.paymentStatus(status);
      case BadgeType.store:
        return Formatters.storeStatus(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: AppSizes.fontXs,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
