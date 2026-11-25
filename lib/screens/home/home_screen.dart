import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../pengiriman/pengiriman_screen.dart';
import '../transaksi/transaksi_screen.dart';
// import '../setoran/setoran_screen.dart';
// import '../performa/performa_screen.dart';
import '../menu/menu_screen.dart';
import '../attendance/attendance_screen.dart'; // ✅ Hanya butuh ini sekarang

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${_user?.name ?? 'Kurir'}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih kegiatan Anda hari ini',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // MENU GRID
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _menuCard(
                                'ABSENSI',
                                Icons.how_to_reg_rounded,
                                const Color(0xFF2E7D32), () {
                          // ✅ PERUBAHAN: Gunakan Navigator.push ke halaman baru
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AttendanceScreen()),
                          );
                        })),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                            child: _menuCard(
                                'PENGIRIMAN',
                                Icons.local_shipping_rounded,
                                const Color(0xFF1976D2), () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PengirimanScreen()));
                        })),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                            child: _menuCard(
                                'TRANSAKSI',
                                Icons.receipt_long_rounded,
                                const Color(0xFF7B1FA2), () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TransaksiScreen()));
                        })),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                            child: _menuCard(
                                'SETORAN',
                                Icons.account_balance_wallet_rounded,
                                const Color(0xFFF57C00), () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Segera Hadir')));
                        })),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    _menuCardFull('PERFORMA', Icons.bar_chart_rounded,
                        const Color(0xFFD32F2F), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Segera Hadir')));
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        userName: _user?.firstName ?? '',
        currentIndex: 0,
        onHomeTap: () {},
        onMenuTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MenuScreen())),
        onInboxTap: () {},
      ),
    );
  }

  Widget _menuCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCardFull(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color))),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
