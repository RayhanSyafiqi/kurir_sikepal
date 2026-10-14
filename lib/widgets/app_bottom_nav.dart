import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final String userName;
  final int currentIndex; // 0 = Home, 1 = Menu, 2 = Inbox
  final VoidCallback? onHomeTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onInboxTap;

  const AppBottomNav({
    super.key,
    required this.userName,
    required this.currentIndex,
    this.onHomeTap,
    this.onMenuTap,
    this.onInboxTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(
                icon: Icons.home_rounded,
                label: 'HI ${userName.toUpperCase()}',
                active: currentIndex == 0,
                onTap: onHomeTap ?? () {},
              ),
              _item(
                icon: Icons.grid_view_rounded,
                label: 'MENU',
                active: currentIndex == 1,
                onTap: onMenuTap ?? () {},
              ),
              _item(
                icon: Icons.inbox_rounded,
                label: 'INBOX',
                active: currentIndex == 2,
                onTap: onInboxTap ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    const activeColor = Color(0xFFFF7043);
    final color = active ? activeColor : const Color(0xFF9CA3AF);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color:
                    active ? activeColor.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
