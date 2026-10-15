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
import '../../widgets/app_bottom_nav.dart';
import '../menu/menu_screen.dart';
import '../order/create_order_sheet.dart';
import '../order/extra_order_sheet.dart';
import '../store_detail/store_detail_screen.dart';
import 'widgets/home_summary_card.dart';
import 'widgets/store_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final results = await Future.wait([
        AuthService.me(),
        OrderService.getAll(
          startDate: startOfDay,
          endDate: endOfDay,
          limit: 200,
        ),
        ProductService.getAll(limit: 200),
        StoreService.getAll(limit: 500),
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
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Cari order hari ini untuk toko tertentu
  Order? _findTodayOrderForStore(String storeId) {
    for (final order in _todayOrders) {
      if (order.store?.id == storeId) return order;
    }
    return null;
  }

  Future<void> _openStoreDetail(Store store) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailScreen(store: store),
      ),
    );
    if (mounted) _load();
  }

  // ============ FAB: PILIH JENIS ORDER ============
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
      // Order biasa — pilih toko dari rute
      final result = await CreateOrderSheet.show(context);
      if (result == true && mounted) _load();
    } else {
      // Extra order — ketik nama toko manual
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

  // ============ SUMMARY CALCULATIONS ============
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

  double get _totalAmount =>
      _todayOrders.fold(0.0, (s, o) => s + o.totalAmount);

  double get _totalPiutang => _todayOrders
      .where((o) => !o.isPaid)
      .fold(0.0, (s, o) => s + o.totalAmount);

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ============ HEADER KUNING ============
            SliverToBoxAdapter(
              child: HomeSummaryCard(
                user: _user,
                productSummary: _productSummary,
                totalQty: _totalQty,
                totalRemaining: _totalRemaining,
                totalAmount: _totalAmount,
                totalPiutang: _totalPiutang,
              ),
            ),

            // ============ TITLE ============
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  AppSizes.xl,
                  AppSizes.lg,
                  AppSizes.md,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'DAFTAR TOKO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    if (_stores.isNotEmpty)
                      Text(
                        '${_stores.length} toko',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ============ LIST TOKO ============
            _buildBody(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // ============ FAB ============
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

      // ============ BOTTOM NAV ============
      bottomNavigationBar: AppBottomNav(
        userName: _user?.firstName ?? '',
        currentIndex: 0,
        onHomeTap: () {},
        onMenuTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuScreen()),
          );
        },
        onInboxTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Segera hadir')),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    // Loading
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _load,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Kosong
    if (_stores.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 72,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Belum ada toko di rute Anda',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  'Hubungi admin untuk assign toko ke rute Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // List toko
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      sliver: SliverList.separated(
        itemCount: _stores.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
        itemBuilder: (_, i) {
          final store = _stores[i];
          final todayOrder = _findTodayOrderForStore(store.id);
          return StoreSummaryCard(
            store: store,
            todayOrder: todayOrder,
            onTap: () => _openStoreDetail(store),
          );
        },
      ),
    );
  }
}
