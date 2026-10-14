import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/store_model.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = store.isActive;

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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name ?? 'Tanpa nama',
                            style: const TextStyle(
                              fontSize: AppSizes.fontLg - 1,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (store.grade != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Grade ${store.grade}',
                              style: const TextStyle(
                                fontSize: AppSizes.fontXs,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: AppSizes.iconSm - 2,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Expanded(
                          child: Text(
                            store.city ?? store.address ?? '-',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSm,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color:
                                isActive ? AppColors.success : AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Formatters.storeStatus(store.status),
                          style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            color:
                                isActive ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        if (store.category != null)
                          Text(
                            Formatters.category(store.category),
                            style: const TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
