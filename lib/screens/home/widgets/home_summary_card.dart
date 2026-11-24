import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/user_model.dart';
import '../../attendance/attendance_sheet.dart';

class HomeSummaryCard extends StatelessWidget {
  final User? user;
  final Map<String, int> productSummary;
  final int totalQty;
  final int totalInitQty;
  final int totalRemaining;
  final double totalAmount;
  final double totalPiutang;

  // KPI Data
  final int totalStoresYesterday;
  final int paidStores;
  final int totalShippedProducts;
  final int totalStoresToday;
  final int deliveredStores;
  final int totalNotaTagihan;
  final int warningStores;
  final double dailyPerformance;
  final double weeklyPerformance;
  final int totalSisaProducts;
  final int totalNotaTagihanKemarin;

  // Callback
  final VoidCallback? onProductTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onTagihanTap;
  final VoidCallback? onWarningTap;
  final VoidCallback? onDailyTap;
  final VoidCallback? onWeeklyTap;
  final VoidCallback? onSisaTap;
  final VoidCallback? onTagihanKemarinTap;

  const HomeSummaryCard({
    super.key,
    required this.user,
    required this.productSummary,
    required this.totalQty,
    required this.totalInitQty,
    required this.totalRemaining,
    required this.totalAmount,
    required this.totalPiutang,
    required this.totalStoresYesterday,
    required this.paidStores,
    required this.totalShippedProducts,
    required this.totalStoresToday,
    required this.deliveredStores,
    required this.totalNotaTagihan,
    required this.warningStores,
    required this.dailyPerformance,
    required this.weeklyPerformance,
    required this.totalSisaProducts,
    required this.totalNotaTagihanKemarin,
    this.onProductTap,
    this.onLocationTap,
    this.onTagihanTap,
    this.onWarningTap,
    this.onDailyTap,
    this.onWeeklyTap,
    this.onSisaTap,
    this.onTagihanKemarinTap,
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
            AppSizes.lg,
            AppSizes.md,
            AppSizes.lg,
            AppSizes.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ACTION BUTTON: ABSENSI
              _absensiCard(context),
              const SizedBox(height: AppSizes.md),

              // 2. KPI GRID 3 KOLOM (Baris 1)
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      title: 'PRODUK',
                      current: totalShippedProducts,
                      total: totalQty,
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF1976D2),
                      suffix: 'Pcs',
                      onTap: onProductTap,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _kpiCardCount(
                      title: 'SISA',
                      count: totalSisaProducts,
                      icon: Icons.inventory,
                      color: const Color(0xFFF57C00),
                      suffix: 'Pcs',
                      onTap: onSisaTap,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _kpiCard(
                      title: 'LOKASI',
                      current: deliveredStores,
                      total: totalStoresToday,
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFFE65100),
                      suffix: 'Toko',
                      onTap: onLocationTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // 3. KPI GRID 3 KOLOM (Baris 2)
              Row(
                children: [
                  Expanded(
                    child: _kpiCardCount(
                      title: 'TAGIHAN',
                      count: totalNotaTagihan,
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF7B1FA2),
                      suffix: 'Nota',
                      onTap: onTagihanTap,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _kpiCardCount(
                      title: 'WARNING',
                      count: warningStores,
                      icon: Icons.warning_rounded,
                      color: const Color(0xFFD32F2F),
                      suffix: 'Toko',
                      onTap: onWarningTap,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _kpiCardCount(
                      title: 'TGK KMRN',
                      count: totalNotaTagihanKemarin,
                      icon: Icons.history_rounded,
                      color: const Color(0xFFC2185B),
                      suffix: 'Nota',
                      onTap: onTagihanKemarinTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // 4. KPI PERFORMANCE 2 KOLOM
              Row(
                children: [
                  Expanded(
                    child: _kpiPerformanceCard(
                      title: 'HARIAN',
                      percentage: dailyPerformance,
                      icon: Icons.speed_rounded,
                      color: const Color(0xFF00BCD4),
                      onTap: onDailyTap,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: _kpiPerformanceCard(
                      title: 'MINGGUAN',
                      percentage: weeklyPerformance,
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFF673AB7),
                      onTap: onWeeklyTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // ============ METODE BAYAR ============
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 22,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'METODE BAYAR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2937),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'TOTAL HARI INI',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9CA3AF),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child: _paymentItem(
                            'CASH',
                            _formatNumber(0),
                            const Color(0xFF1F2937),
                          ),
                        ),
                        Expanded(
                          child: _paymentItem(
                            'TRANSFER',
                            _formatNumber(0),
                            Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _paymentItem(
                            'TOTAL',
                            _formatNumber(totalAmount),
                            const Color(0xFF1F2937),
                          ),
                        ),
                        Expanded(
                          child: _paymentItem(
                            'PIUTANG',
                            _formatNumber(totalPiutang),
                            Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // ============ INFORMASI RINGKASAN ============
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMASI RINGKASAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    if (productSummary.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Belum ada orderan',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      _productGrid(),
                    const SizedBox(height: AppSizes.md),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _totals('TOTAL PENGIRIMAN AWAL', '$totalInitQty'),
                        ),
                        Expanded(
                          child: _totals('TOTAL PENGIRIMAN REAL', '$totalQty'),
                        ),
                        Expanded(
                          child:
                              _totals('SELISIH', '${totalInitQty - totalQty}'),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ WIDGET KPI ============
  Widget _absensiCard(BuildContext context) {
    return Material(
      color: const Color(0xFF1B5E20),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: () async {
          final success = await AttendanceSheet.show(context);
          if (success == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Absensi berhasil terkirim!')),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg, vertical: AppSizes.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.how_to_reg_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ABSENSI MASUK',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Klik di sini untuk absen hari ini',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required int current,
    required int total,
    required IconData icon,
    required Color color,
    required String suffix,
    VoidCallback? onTap,
  }) {
    final percentage = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$current',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '/ $total $suffix',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 4,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCardCount({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String suffix,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      suffix,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiPerformanceCard({
    required String title,
    required double percentage,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final safePct = percentage.clamp(0.0, 100.0);
    final displayPct = safePct.toStringAsFixed(1);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayPct,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: safePct / 100,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productGrid() {
    final entries = productSummary.entries.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries.map((e) {
          final c = _colorForProduct(e.key);
          return Container(
            margin: const EdgeInsets.only(right: AppSizes.sm),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                Text(
                  _shortName(e.key),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: c,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${e.value}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _totals(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _paymentItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  String _shortName(String name) {
    final words = name.toUpperCase().split(' ');
    if (words.length >= 2) {
      final second = words[1].length >= 3 ? words[1].substring(0, 3) : words[1];
      return '${words[0]} $second';
    }
    return name.toUpperCase();
  }

  Color _colorForProduct(String name) {
    final n = name.toLowerCase();
    if (n.contains('tuna') && n.contains('ped')) return const Color(0xFFD81B60);
    if (n.contains('tuna') && n.contains('may')) return const Color(0xFF1976D2);
    if (n.contains('ayam') && n.contains('may')) return const Color(0xFFF57C00);
    if (n.contains('ayam') && n.contains('ped')) return const Color(0xFFD32F2F);
    if (n.contains('menu') || n.contains('bulan')) {
      return const Color(0xFF388E3C);
    }
    return const Color(0xFF616161);
  }
}
