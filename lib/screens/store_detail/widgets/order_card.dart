import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../../widgets/status_badge.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final Widget? trailing;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Formatters.date(order.date),
                      style: const TextStyle(
                        fontSize: AppSizes.fontMd - 1,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  _MiniStat(label: 'Total', value: '${order.totalQuantity}'),
                  const SizedBox(width: AppSizes.lg),
                  _MiniStat(
                      label: 'Terkirim', value: '${order.shippedQuantity}'),
                  const SizedBox(width: AppSizes.lg),
                  _MiniStat(label: 'Sisa', value: '${order.remaining}'),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Formatters.currency(order.totalAmount),
                      style: const TextStyle(
                        fontSize: AppSizes.fontLg - 1,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  StatusBadge(
                    status: order.paymentStatus,
                    type: BadgeType.payment,
                  ),
                ],
              ),
              if (order.note != null && order.note!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notes,
                        size: AppSizes.iconSm - 2,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.note!,
                          style: const TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(height: AppSizes.md),
                Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.textHint,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppSizes.fontMd - 1,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
