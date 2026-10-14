import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_strings.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.xl),
      children: [
        const SizedBox(height: AppSizes.xxl),
        const Icon(Icons.cloud_off,
            size: AppSizes.iconXxl, color: AppColors.textHint),
        const SizedBox(height: AppSizes.lg),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.lg),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ),
      ],
    );
  }
}
