import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/image_stamp.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _loading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  // ✅ Ambil data absensi hari ini
  Future<void> _fetchAttendance() async {
    try {
      final res = await ApiClient.get('/api/mobile/attendance/today');
      if (res['success'] == true && res['data'] != null) {
        setState(() => _todayAttendance = res['data']);
      } else {
        setState(() => _todayAttendance = null);
      }
    } catch (e) {
      debugPrint("Belum absen atau gagal cek status: $e");
      setState(() => _todayAttendance = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ Logika Absen
  Future<void> _doAttendance() async {
    setState(() => _isSubmitting = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      Position pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (picked == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final raw = await picked.readAsBytes();
      final stamped = await ImageStamp.addTimestamp(
        raw,
        label: 'ABSENSI KURIR',
        locationText:
            'Lat: ${pos.latitude.toStringAsFixed(6)}, Long: ${pos.longitude.toStringAsFixed(6)}',
      );

      final b64 = base64Encode(stamped);

      // ✅ FIX WARNING: Tangkap response dari API
      final postRes = await ApiClient.post(
        '/api/mobile/attendance',
        body: {
          'photo': b64,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
      );

      if (!mounted) return;

      // ✅ FIX WARNING: Cek apakah response sukses
      if (postRes['success'] == true) {
        // Refresh data setelah absen sukses
        _fetchAttendance();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Absensi berhasil dikirim!'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception(postRes['error'] ?? 'Gagal mengirim absensi ke server');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Helper format tanggal
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      const days = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu'
      ];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];

      final dayName = days[date.weekday - 1];
      final monthName = months[date.month - 1];
      final time =
          "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

      return '$dayName, ${date.day} $monthName ${date.year} • $time';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Absensi Kurir',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: _todayAttendance != null
                  ? _buildAttendanceDetail()
                  : _buildBelumAbsen(),
            ),
    );
  }

  // ==========================================
  // UI: JIKA SUDAH ABSEN (FOTO & TANGGAL)
  // ==========================================
  Widget _buildAttendanceDetail() {
    final status = _todayAttendance!['status'];
    final photoBase64 = _todayAttendance!['photo'];
    final dateStr = _todayAttendance!['date'];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'APPROVED') {
      statusColor = Colors.green;
      statusText = 'Disetujui';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'REJECTED') {
      statusColor = Colors.red;
      statusText = 'Ditolak';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.orange;
      statusText = 'Menunggu Persetujuan';
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kartu Status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusText,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: statusColor)),
                    const SizedBox(height: 2),
                    Text(_formatDate(dateStr),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text('Bukti Foto Absensi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        // Foto
        if (photoBase64 != null && photoBase64.toString().isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              base64Decode(photoBase64),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          const Center(child: Text('Foto tidak tersedia')),

        // Tombol Absen Ulang (Jika Ditolak)
        if (status == 'REJECTED') ...[
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _doAttendance,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: Text(_isSubmitting ? 'Memproses...' : 'Absen Ulang'),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // UI: JIKA BELUM ABSEN
  // ==========================================
  Widget _buildBelumAbsen() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.how_to_reg_rounded,
            size: 80, color: Color(0xFFF57C00)),
        const SizedBox(height: 24),
        const Text(
          'Anda Belum Absen Hari Ini',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Pastikan Anda berada di lokasi yang benar.\nSistem akan membuka kamera depan untuk mengambil foto beserta titik koordinat GPS Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _doAttendance,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.camera_front_rounded),
            label: Text(_isSubmitting ? 'Memproses...' : 'Buka Kamera & Absen'),
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
