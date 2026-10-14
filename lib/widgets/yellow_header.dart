import 'package:flutter/material.dart';
import '../core/constants/app_sizes.dart';

class YellowHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool showBackButton;
  final Widget? trailing;

  const YellowHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.showBackButton = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.sm,
            AppSizes.sm,
            AppSizes.lg,
            AppSizes.xl,
          ),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.maybePop(context),
                ),
              if (icon != null && !showBackButton)
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSizes.sm, right: AppSizes.sm),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          letterSpacing: 0.3,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
