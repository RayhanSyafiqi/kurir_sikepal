import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/image_stamp.dart';
import '../../core/utils/image_picker_helper.dart';
// import '../../core/config/api_config.dart';

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
      final picked = await ImagePickerHelper.pickImage(context);
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
      await ApiClient.post(
        '/api/mobile/attendance',
        body: {
          'photo': b64,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
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
            'Pastikan Anda berada di lokasi yang benar.\nSistem akan mengambil foto beserta titik koordinat GPS Anda.',
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
                  : const Icon(Icons.camera_alt_rounded),
              label: Text(_loading ? 'Memproses...' : 'Ambil Foto & Absen'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
