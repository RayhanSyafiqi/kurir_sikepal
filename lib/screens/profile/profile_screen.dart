import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/yellow_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final u = await AuthService.me();
      if (mounted) setState(() => _user = u);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const YellowHeader(title: 'Profil'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    children: [
                      Center(child: _avatar()),
                      const SizedBox(height: AppSizes.lg),
                      _card([
                        _row('Nama', _user?.name ?? '-'),
                        _row('Email', _user?.email ?? '-'),
                        _row('Role', 'Kurir'),
                      ]),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 96,
      height: 96,
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
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
