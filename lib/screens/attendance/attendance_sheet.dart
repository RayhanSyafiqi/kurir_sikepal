import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/image_stamp.dart';

class AttendanceSheet extends StatefulWidget {
  const AttendanceSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AttendanceSheet(),
    );
  }

  @override
  State<AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<AttendanceSheet> {
  bool _loading = false;
  bool _isFetchingStatus = true;

  // ✅ State untuk menyimpan data absensi hari ini
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _checkTodayAttendance();
  }

  // ✅ Fungsi cek apakah sudah absen hari ini
  Future<void> _checkTodayAttendance() async {
    try {
      final res = await ApiClient.get('/api/mobile/attendance/today');
      if (res['success'] == true && res['data'] != null) {
        setState(() => _todayAttendance = res['data']);
      }
    } catch (e) {
      // Abaikan error (biasanya 404 jika belum absen atau belum ada API)
      debugPrint("Belum absen atau gagal cek status: $e");
    } finally {
      if (mounted) setState(() => _isFetchingStatus = false);
    }
  }

  Future<void> _doAttendance() async {
    setState(() => _loading = true);
    try {
      // 1. Dapatkan Lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      Position pos = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      // 2. Ambil Foto
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (picked == null) {
        setState(() => _loading = false);
        return;
      }

      // 3. Tempel Timestamp & Lokasi
      final raw = await picked.readAsBytes();
      final stamped = await ImageStamp.addTimestamp(
        raw,
        label: 'ABSENSI KURIR',
        locationText:
            'Lat: ${pos.latitude.toStringAsFixed(6)}, Long: ${pos.longitude.toStringAsFixed(6)}',
      );

      // 4. Kirim ke API
      final b64 = base64Encode(stamped);
      final postRes = await ApiClient.post(
        '/api/mobile/attendance',
        body: {
          'photo': b64,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
      );

      if (!mounted) return;

      // ✅ Setelah sukses, timpa state _todayAttendance agar UI langsung berubah jadi "Menunggu"
      setState(() {
        _todayAttendance = postRes['data'] ?? {'status': 'PENDING'};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Absensi berhasil dikirim!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          if (_isFetchingStatus)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )
          else if (_todayAttendance != null)
            _buildStatusUI() // ✅ Tampilkan UI jika sudah absen
          else
            _buildFormUI(), // ✅ Tampilkan UI kamera jika belum absen

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ==========================================
  // UI JIKA SUDAH ABSEN
  // ==========================================
  Widget _buildStatusUI() {
    final status = _todayAttendance!['status'];

    Color iconColor;
    IconData iconData;
    String title;
    String subtitle;

    if (status == 'APPROVED') {
      iconColor = Colors.green;
      iconData = Icons.check_circle_rounded;
      title = 'Absensi Disetujui';
      subtitle =
          'Terima kasih, absensi Anda hari ini sudah diverifikasi oleh Admin.';
    } else if (status == 'REJECTED') {
      iconColor = Colors.red;
      iconData = Icons.cancel_rounded;
      title = 'Absensi Ditolak';
      subtitle =
          'Maaf, absensi Anda ditolak. Silakan hubungi admin atau lakukan absen ulang.';
    } else {
      // PENDING
      iconColor = const Color(0xFFF57C00);
      iconData = Icons.hourglass_top_rounded;
      title = 'Menunggu Persetujuan';
      subtitle =
          'Absensi Anda sudah terkirim dan sedang menunggu verifikasi dari Admin.';
    }

    return Column(
      children: [
        Icon(iconData, size: 64, color: iconColor),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),

        // Tampilkan tombol absen ulang JIKA DITOLAK
        if (status == 'REJECTED') ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _doAttendance,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              label: Text(_loading ? 'Memproses...' : 'Absen Ulang'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child:
                  const Text('Tutup', style: TextStyle(color: Colors.black87)),
            ),
          )
        ]
      ],
    );
  }

  // ==========================================
  // UI JIKA BELUM ABSEN (FORM KAMERA)
  // ==========================================
  Widget _buildFormUI() {
    return Column(
      children: [
        const Icon(Icons.how_to_reg_rounded,
            size: 64, color: Color(0xFFF57C00)),
        const SizedBox(height: 16),
        const Text(
          'Absensi Masuk',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pastikan Anda berada di lokasi yang benar.\nSistem akan membuka kamera depan untuk mengambil foto beserta titik koordinat GPS Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _loading ? null : _doAttendance,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.camera_front_rounded),
            label: Text(_loading ? 'Memproses...' : 'Buka Kamera & Absen'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF57C00),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
