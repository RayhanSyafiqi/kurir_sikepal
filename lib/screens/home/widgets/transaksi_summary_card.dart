import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart'; // ✅ TAMBAHKAN INI
import '../../../models/user_model.dart';

class TransaksiSummaryCard extends StatelessWidget {
  final User? user;
  final int totalNotaTagihan;
  final int totalNotaTagihanKemarin;
  final int warningStores;
  final int totalSisaProducts;
  final double weeklyPerformance;
  final double totalAmount;
  final double totalPiutang;

  const TransaksiSummaryCard({
    super.key,
    required this.user,
    required this.totalNotaTagihan,
    required this.totalNotaTagihanKemarin,
    required this.warningStores,
    required this.totalSisaProducts,
    required this.weeklyPerformance,
    required this.totalAmount,
    required this.totalPiutang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFC107),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _kpiCardCount('TAGIHAN', totalNotaTagihan, 'Nota',
                      const Color(0xFF7B1FA2))),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                  child: _kpiCardCount('TGK KEMARIN', totalNotaTagihanKemarin,
                      'Nota', const Color(0xFFC2185B))),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                  child: _kpiCardCount('WARNING', warningStores, 'Toko',
                      const Color(0xFFD32F2F))),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                  child: _kpiCardCount('SISA PRODUK', totalSisaProducts, 'Pcs',
                      const Color(0xFFF57C00))),
              const SizedBox(width: AppSizes.md),
              Expanded(child: _kpiPerformance('MINGGUAN', weeklyPerformance)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('METODE BAYAR',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ Dibungkus Expanded agar tidak overflow
                    Expanded(
                        child: _paymentItem('TOTAL UANG', totalAmount,
                            const Color(0xFF1F2937))),
                    Expanded(
                        child: _paymentItem(
                            'PIUTANG', totalPiutang, Colors.red.shade700)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCardCount(String title, int count, String suffix, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 2),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '$count $suffix',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _kpiPerformance(String title, double percentage) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 2),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Text('${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF673AB7))),
        ],
      ),
    );
  }

  Widget _paymentItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        // ✅ Dibungkus FittedBox agar angka yang panjang mengecil otomatis
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Formatters.currency(value), // ✅ Ini sekarang sudah dikenali
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
