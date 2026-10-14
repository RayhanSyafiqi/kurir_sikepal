import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/yellow_header.dart';
import '../../routes/app_routes.dart';
import '../returns/returns_screen.dart';
import '../transactions/transactions_screen.dart';
import '../profile/profile_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final u = await AuthService.me();
      if (mounted) setState(() => _user = u);
    } catch (_) {}
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.logout();
    if (!mounted) return;
    AppRoutes.toLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          YellowHeader(
            title: 'Menu',
            subtitle: _user?.email ?? '',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _profileCard(),
                  const SizedBox(height: AppSizes.lg),
                  const Text(
                    'MENU KURIR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  _menuGrid(),
                  const SizedBox(height: AppSizes.xl),
                  _logoutButton(),
                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        userName: _user?.firstName ?? '',
        currentIndex: 1,
        onHomeTap: () {
          // Kembali ke Home
          Navigator.pop(context);
        },
        onMenuTap: () {},
        onInboxTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Segera hadir')),
          );
        },
      ),
    );
  }

  // ============ PROFILE CARD ============
  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              (_user?.firstName.isNotEmpty ?? false)
                  ? _user!.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.name ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _user?.email ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'KURIR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE65100),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ MENU GRID ============
  Widget _menuGrid() {
    final items = [
      _MenuItem(
        icon: Icons.receipt_long_rounded,
        label: 'Transaksi',
        color: const Color(0xFF1976D2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionsScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.assignment_return_rounded,
        label: 'Retur',
        color: const Color(0xFFD32F2F),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReturnsScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.store_rounded,
        label: 'Daftar Toko',
        color: const Color(0xFFF57C00),
        onTap: () {
          Navigator.pop(context);
        },
      ),
      _MenuItem(
        icon: Icons.person_rounded,
        label: 'Profil',
        color: const Color(0xFF7B1FA2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.history_rounded,
        label: 'Riwayat',
        color: const Color(0xFF388E3C),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Segera hadir')),
          );
        },
      ),
      _MenuItem(
        icon: Icons.info_outline_rounded,
        label: 'Tentang',
        color: const Color(0xFF616161),
        onTap: () {
          showAboutDialog(
            context: context,
            applicationName: 'Sikepal Kurir',
            applicationVersion: '1.0.0',
            children: const [
              Text('Aplikasi kurir untuk manajemen order dan pengiriman.'),
            ],
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.md,
        mainAxisSpacing: AppSizes.md,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _menuTile(items[i]),
    );
  }

  Widget _menuTile(_MenuItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: item.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ LOGOUT BUTTON ============
  Widget _logoutButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: const Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSizes.md,
            horizontal: AppSizes.lg,
          ),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 22),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ HELPER CLASS ============
class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
