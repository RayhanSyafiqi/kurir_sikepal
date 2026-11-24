import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/order_model.dart';
import '../../models/store_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/store_service.dart';
import '../store_detail/store_detail_screen.dart';
import '../home/widgets/transaksi_summary_card.dart';
import '../home/widgets/store_summary_card.dart';
import '../../widgets/yellow_header.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  bool _loading = true;
  User? _user;
  List<Order> _allUnpaidOrders = [];
  List<Store> _stores = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AuthService.me(),
        OrderService.getAll(paymentStatus: 'UNPAID', limit: 500),
        StoreService.getAll(limit: 500),
      ]);

      if (mounted) {
        setState(() {
          _user = results[0] as User;
          _allUnpaidOrders = results[1] as List<Order>;
          _stores = results[2] as List<Store>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _getStoreUnpaidCount(String storeId) {
    return _allUnpaidOrders
        .where((o) =>
            o.store?.id == storeId &&
            (o.hasDeliveryProof || o.status == 'COMPLETED'))
        .length;
  }

  double _getStorePiutang(String storeId) {
    return _allUnpaidOrders
        .where((o) =>
            o.store?.id == storeId &&
            (o.hasDeliveryProof || o.status == 'COMPLETED'))
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  bool _isStoreWarning(String storeId, String? paymentMethod) {
    final storeUnpaid = _allUnpaidOrders
        .where((o) =>
            o.store?.id == storeId &&
            (o.hasDeliveryProof || o.status == 'COMPLETED'))
        .toList();
    if (storeUnpaid.isEmpty) return false;
    final oldest =
        storeUnpaid.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
    final daysLate = DateTime.now()
        .difference(
            DateTime(oldest.date.year, oldest.date.month, oldest.date.day))
        .inDays;
    final pm = paymentMethod ?? 'DAILY';
    if (pm == 'DAILY' && daysLate > 2) return true;
    if (pm == 'WEEKLY' && daysLate > 8) return true;
    if (pm == 'MONTHLY' && daysLate > 15) return true;
    return false;
  }

  List<Order> get _deliveredUnpaidOrders => _allUnpaidOrders
      .where((o) => o.hasDeliveryProof || o.status == 'COMPLETED')
      .toList();

  int get _totalNotaTagihan => _deliveredUnpaidOrders.length;

  int get _totalNotaTagihanKemarin {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _deliveredUnpaidOrders.where((o) {
      final d = o.date.toLocal();
      return d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day;
    }).length;
  }

  int get _warningStoresCount {
    final warningIds = <String>{};
    for (final o in _deliveredUnpaidOrders) {
      if (_isStoreWarning(o.store?.id ?? '', o.store?.paymentMethod)) {
        if (o.store?.id != null) warningIds.add(o.store!.id);
      }
    }
    return warningIds.length;
  }

  int get _totalSisaProducts =>
      _deliveredUnpaidOrders.fold(0, (s, o) => s + o.sisaQuantity);
  double get _weeklyPerformance => 0.0;
  double get _totalAmount =>
      _deliveredUnpaidOrders.fold(0.0, (s, o) => s + o.totalAmount);
  double get _totalPiutang => _totalAmount;

  /// Toko yang punya tagihan, diurutkan: warning dulu, lalu piutang terbesar.
  List<Store> get _sortedStoresWithBill {
    final list = _stores.where((s) => _getStoreUnpaidCount(s.id) > 0).toList();
    list.sort((a, b) {
      final aw = _isStoreWarning(a.id, a.paymentMethod);
      final bw = _isStoreWarning(b.id, b.paymentMethod);
      if (aw != bw) return aw ? -1 : 1;
      return _getStorePiutang(b.id).compareTo(_getStorePiutang(a.id));
    });
    return list;
  }

  List<Store> get _storesWithoutBill =>
      _stores.where((s) => _getStoreUnpaidCount(s.id) == 0).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: YellowHeader(
            title: 'Transaksi', subtitle: 'Penagihan & Pembayaran'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSizes.xl),
                children: [
                  TransaksiSummaryCard(
                    user: _user,
                    totalNotaTagihan: _totalNotaTagihan,
                    totalNotaTagihanKemarin: _totalNotaTagihanKemarin,
                    warningStores: _warningStoresCount,
                    totalSisaProducts: _totalSisaProducts,
                    weeklyPerformance: _weeklyPerformance,
                    totalAmount: _totalAmount,
                    totalPiutang: _totalPiutang,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _sectionHeader(
                    title: 'DAFTAR TOKO',
                    subtitle: _warningStoresCount > 0
                        ? '$_warningStoresCount toko perlu ditagih segera'
                        : 'Semua tagihan masih dalam batas waktu',
                    icon: Icons.receipt_long_rounded,
                    trailing: _BillingPill(
                      count: _totalNotaTagihan,
                      isWarning: _warningStoresCount > 0,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (_stores.isEmpty)
                    const _EmptyState(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'Belum ada toko',
                      message: 'Data toko belum tersedia.',
                    )
                  else ...[
                    ..._sortedStoresWithBill.map((store) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSizes.lg, 0, AppSizes.lg, AppSizes.md),
                          child: _StoreTileWrapper(
                            isWarning:
                                _isStoreWarning(store.id, store.paymentMethod),
                            child: StoreSummaryCard(
                              store: store,
                              todayOrder: null,
                              totalNota: _getStoreUnpaidCount(store.id),
                              totalPiutang: _getStorePiutang(store.id),
                              isWarning: _isStoreWarning(
                                  store.id, store.paymentMethod),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StoreDetailScreen(
                                        store: store, mode: 'TRANSACTION'),
                                  ),
                                );
                                _load();
                              },
                            ),
                          ),
                        )),
                    if (_storesWithoutBill.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.lg, vertical: AppSizes.sm),
                        child: Text(
                          'TOKO TANPA TAGIHAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      ..._storesWithoutBill.map((store) => Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSizes.lg, 0, AppSizes.lg, AppSizes.md),
                            child: Opacity(
                              opacity: 0.75,
                              child: StoreSummaryCard(
                                store: store,
                                todayOrder: null,
                                totalNota: 0,
                                totalPiutang: 0,
                                isWarning: false,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoreDetailScreen(
                                          store: store, mode: 'TRANSACTION'),
                                    ),
                                  );
                                  _load();
                                },
                              ),
                            ),
                          )),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFB78600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: _warningStoresCount > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6B7280),
                    fontWeight: _warningStoresCount > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

/// Wrapper status tagihan (warning / normal) per toko.
class _StoreTileWrapper extends StatelessWidget {
  final bool isWarning;
  final Widget child;

  const _StoreTileWrapper({required this.isWarning, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isWarning)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Jatuh Tempo',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BillingPill extends StatelessWidget {
  final int count;
  final bool isWarning;

  const _BillingPill({required this.count, required this.isWarning});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isWarning ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWarning
                ? Icons.notifications_active_rounded
                : Icons.check_circle_rounded,
            size: 14,
            color:
                isWarning ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 6),
          Text(
            '$count nota',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color:
                  isWarning ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg, vertical: AppSizes.xxl),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
