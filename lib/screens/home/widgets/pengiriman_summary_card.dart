import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/user_model.dart';

class PengirimanSummaryCard extends StatelessWidget {
  final User? user;
  final Map<String, int> productSummary;
  final int totalQty; // Target Total
  final int totalRemaining;
  final int totalShippedProducts; // Real Terkirim
  final int totalStoresToday;
  final int deliveredStores;
  final double dailyPerformance;

  const PengirimanSummaryCard({
    super.key,
    required this.user,
    required this.productSummary,
    required this.totalQty,
    required this.totalRemaining,
    required this.totalShippedProducts,
    required this.totalStoresToday,
    required this.deliveredStores,
    required this.dailyPerformance,
  });

  int _getProductPriority(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('tuna pedas') || lowerName.contains('tuna pedes'))
      return 1;
    if (lowerName.contains('tuna mayo')) return 2;
    if (lowerName.contains('ayam mayo')) return 3;
    if (lowerName.contains('ayam pedas') || lowerName.contains('ayam pedes'))
      return 4;
    return 99;
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = productSummary.entries.toList()
      ..sort((a, b) {
        final priorityA = _getProductPriority(a.key);
        final priorityB = _getProductPriority(b.key);

        if (priorityA == priorityB) {
          return a.key.compareTo(b.key);
        }
        return priorityA.compareTo(priorityB);
      });

    // Hitung selisih real vs target
    final selisih = totalQty - totalShippedProducts;

    return Container(
      color: const Color(0xFFFFC107),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _kpiCard('PRODUK', totalShippedProducts, totalQty,
                      'Pcs', const Color(0xFF1976D2))),
              const SizedBox(width: AppSizes.md),
              Expanded(
                  child: _kpiCard('LOKASI', deliveredStores, totalStoresToday,
                      'Toko', const Color(0xFFE65100))),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _kpiPerformance('PERFORMA HARIAN', dailyPerformance),
          const SizedBox(height: AppSizes.md),

          // --- BAGIAN RINGKASAN PRODUK ---
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_rounded,
                          size: 16, color: Color(0xFFB78600)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'RINGKASAN PRODUK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                if (sortedEntries.isEmpty)
                  const Text('Belum ada orderan',
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedEntries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                ),

                // ==========================================
                // KOTAK BAWAH (TARGET, REAL, SISA)
                // ==========================================
                Row(
                  children: [
                    Expanded(
                      child: _buildBottomStat(
                        title: 'TARGET',
                        value: '$totalQty',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF6B7280), // Abu-abu
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBottomStat(
                        title: 'REAL KIRIM',
                        value: '$totalShippedProducts',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF16A34A), // Hijau
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBottomStat(
                        title: 'SISA',
                        value: '$selisih',
                        icon: Icons.remove_shopping_cart_outlined,
                        color: selisih > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF9CA3AF), // Merah jika ada selisih
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
      String title, int current, int total, String suffix, Color color) {
    final pct = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Text('$current / $total $suffix',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: pct,
              color: color,
              backgroundColor: color.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _kpiPerformance(String title, double percentage) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Text('${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00BCD4))),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: percentage / 100,
              color: const Color(0xFF00BCD4),
              backgroundColor: const Color(0xFF00BCD4).withOpacity(0.1)),
        ],
      ),
    );
  }

  // --- WIDGET KOTAK BAWAH ---
  Widget _buildBottomStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.8),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
