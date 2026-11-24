import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/store_service.dart';
import '../store_detail/store_detail_screen.dart';
import '../home/widgets/pengiriman_summary_card.dart';
import '../home/widgets/store_summary_card.dart';
import '../../widgets/yellow_header.dart';
import '../order/create_order_sheet.dart';
import '../order/extra_order_sheet.dart';

class PengirimanScreen extends StatefulWidget {
  const PengirimanScreen({super.key});

  @override
  State<PengirimanScreen> createState() => _PengirimanScreenState();
}

class _PengirimanScreenState extends State<PengirimanScreen> {
  bool _loading = true;
  User? _user;
  List<Order> _todayOrders = [];
  List<Product> _products = [];
  List<Store> _stores = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final start = DateTime.utc(now.year, now.month, now.day);
      final end = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);

      final results = await Future.wait([
        AuthService.me(),
        OrderService.getAll(startDate: start, endDate: end, limit: 200),
        ProductService.getAll(limit: 200),
        StoreService.getAll(limit: 500, date: now),
      ]);

      if (mounted) {
        setState(() {
          _user = results[0] as User;
          _todayOrders = results[1] as List<Order>;
          _products = results[2] as List<Product>;
          _stores = results[3] as List<Store>;
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

  Order? _findTodayOrderForStore(String storeId) {
    for (final order in _todayOrders) {
      if (order.store?.id == storeId) return order;
    }
    return null;
  }

  // ============ GETTER DATA PENGIRIMAN REAL ============
  int get _totalShippedReal =>
      _todayOrders.fold(0, (s, o) => s + o.shippedQuantity);

  Map<String, int> get _productSummary {
    final map = <String, int>{};
    for (final p in _products) {
      map[p.name] = 0;
    }
    for (final o in _todayOrders) {
      for (final item in o.items) {
        final name = item.productName ?? 'Unknown';
        map[name] = (map[name] ?? 0) + item.quantity;
      }
    }
    return map;
  }

  int get _totalQty => _productSummary.values.fold(0, (a, b) => a + b);
  int get _totalRemaining => _todayOrders.fold(0, (s, o) => s + o.remaining);

  int get _deliveredStores {
    final doneStoreIds = _todayOrders
        .where((o) => o.status == 'COMPLETED' || o.hasDeliveryProof)
        .map((o) => o.store?.id)
        .whereType<String>()
        .toSet();
    return _stores.where((s) => doneStoreIds.contains(s.id)).length;
  }

  double get _dailyPerformance =>
      _stores.isEmpty ? 0.0 : (_deliveredStores / _stores.length) * 100;

  List<Store> get _sortedStores {
    final list = [..._stores];
    list.sort((a, b) {
      final oa = _findTodayOrderForStore(a.id);
      final ob = _findTodayOrderForStore(b.id);
      final aDone =
          oa != null && (oa.status == 'COMPLETED' || oa.hasDeliveryProof);
      final bDone =
          ob != null && (ob.status == 'COMPLETED' || ob.hasDeliveryProof);
      if (aDone == bDone) {
        return (a.name ?? '').compareTo(b.name ?? '');
      }
      return aDone ? 1 : -1;
    });
    return list;
  }

  Future<void> _onFabPressed() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(AppSizes.lg),
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
            const Text(
              'Pilih Jenis Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih jenis order yang mau dibuat',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: _typeCard(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Order Biasa',
                    subtitle: 'Pilih toko dari rute',
                    color: const Color(0xFFF57C00),
                    onTap: () => Navigator.pop(ctx, 'REGULAR'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _typeCard(
                    icon: Icons.flash_on_rounded,
                    label: 'Extra Order',
                    subtitle: 'Order di luar rute',
                    color: const Color(0xFF7B1FA2),
                    onTap: () => Navigator.pop(ctx, 'EXTRA'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'REGULAR') {
      final result = await CreateOrderSheet.show(context);
      if (result == true && mounted) _load();
    } else {
      final todayStoreNames = _todayOrders
          .map((o) => o.store?.name ?? '')
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      final result = await ExtraOrderSheet.show(
        context,
        todayStoreNames: todayStoreNames,
      );
      if (result == true && mounted) _load();
    }
  }

  Widget _typeCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(80),
        child:
            YellowHeader(title: 'Pengiriman', subtitle: 'Daftar Toko & Order'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  PengirimanSummaryCard(
                    user: _user,
                    productSummary: _productSummary,
                    totalQty: _totalQty, // Target total
                    totalRemaining: _totalRemaining,
                    totalShippedProducts: _totalShippedReal, // Real terkirim
                    totalStoresToday: _stores.length,
                    deliveredStores: _deliveredStores,
                    dailyPerformance: _dailyPerformance,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _sectionHeader(
                    title: 'DAFTAR TOKO',
                    subtitle:
                        '${_deliveredStores}/${_stores.length} toko selesai hari ini',
                    icon: Icons.storefront_rounded,
                    trailing: _ProgressPill(
                      current: _deliveredStores,
                      total: _stores.length,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (_stores.isEmpty)
                    const _EmptyState(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'Belum ada toko',
                      message: 'Tidak ada toko yang dijadwalkan hari ini.',
                    )
                  else
                    ..._sortedStores.map((store) {
                      final order = _findTodayOrderForStore(store.id);
                      final isDone = order != null &&
                          (order.status == 'COMPLETED' ||
                              order.hasDeliveryProof);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.lg, 0, AppSizes.lg, AppSizes.md),
                        child: _StoreTileWrapper(
                          isDone: isDone,
                          child: StoreSummaryCard(
                            store: store,
                            todayOrder: order,
                            totalNota: 0,
                            totalPiutang: 0,
                            isWarning: false,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoreDetailScreen(
                                      store: store, mode: 'DELIVERY'),
                                ),
                              );
                              _load();
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabPressed,
        backgroundColor: const Color(0xFFFF7043),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Buat Order',
          style: TextStyle(fontWeight: FontWeight.w700),
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
              color: const Color(0xFFFFC107).withOpacity(0.15),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
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

// (Sisa widget _StoreTileWrapper, _ProgressPill, dan _EmptyState tetap sama seperti sebelumnya)
class _StoreTileWrapper extends StatelessWidget {
  final bool isDone;
  final Widget child;

  const _StoreTileWrapper({required this.isDone, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isDone
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFF59E0B))
                      .withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone ? Icons.check_circle : Icons.local_shipping_rounded,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isDone ? 'Selesai' : 'Pending',
                  style: const TextStyle(
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

class _ProgressPill extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressPill({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : current / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 2.5,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(ratio * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
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
