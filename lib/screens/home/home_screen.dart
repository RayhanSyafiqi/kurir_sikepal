import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/extra_order_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/extra_order_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/store_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/date_filter_widget.dart';
import '../../widgets/extra_order_summary_card.dart';
import '../extra_order/extra_order_detail_screen.dart';
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
  DateTime _selectedDate = DateTime.now();
  List<Order> _todayOrders = [];
  List<ExtraOrder> _todayExtraOrders = [];
  List<Product> _products = [];
  List<Store> _stores = [];
  List<Order> _allUnpaidOrders = [];
  List<Order> _weeklyOrders = [];

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
      final startOfDay = DateTime.utc(
          _selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime.utc(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, 23, 59, 59);

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final friday = monday.add(const Duration(days: 4));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek =
          DateTime(friday.year, friday.month, friday.day, 23, 59, 59);

      final results = await Future.wait([
        AuthService.me(),
        OrderService.getAll(
          startDate: startOfDay,
          endDate: endOfDay,
          limit: 200,
        ),
        ProductService.getAll(limit: 200),
        StoreService.getAll(limit: 500, date: _selectedDate),
        ExtraOrderService.getAll(
          startDate: startOfDay,
          endDate: endOfDay,
        ),
        OrderService.getAll(
          paymentStatus: 'UNPAID',
          limit: 500,
        ),
        OrderService.getAll(
          startDate: startOfWeek,
          endDate: endOfWeek,
          limit: 500,
        ),
      ]);

      if (mounted) {
        setState(() {
          _user = results[0] as User;
          _todayOrders = results[1] as List<Order>;
          _products = results[2] as List<Product>;
          _stores = results[3] as List<Store>;
          _todayExtraOrders = results[4] as List<ExtraOrder>;
          _allUnpaidOrders = results[5] as List<Order>;
          _weeklyOrders = results[6] as List<Order>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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

    final oldestOrder =
        storeUnpaid.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
    final daysLate = DateTime.now()
        .difference(DateTime(oldestOrder.date.year, oldestOrder.date.month,
            oldestOrder.date.day))
        .inDays;

    final pm = paymentMethod?.toUpperCase() ?? 'DAILY';

    if (pm == 'DAILY' || pm == 'HARIAN') return daysLate > 2;
    if (pm == 'WEEKLY' || pm == 'MINGGUAN_1') return daysLate > 8;
    if (pm == 'MONTHLY' || pm == 'BULANAN') return daysLate > 15;

    return false;
  }

  Order? _findTodayOrderForStore(String storeId) {
    for (final order in _todayOrders) {
      if (order.store?.id == storeId) return order;
    }
    return null;
  }

  // ✅ Teruskan status warning ke StoreDetailScreen
  // ✅ Ubah method _openStoreDetail menjadi seperti ini:
  Future<void> _openStoreDetail(Store store, bool isWarning) async {
    // if (isWarning) {
    //   showDialog(
    //     context: context,
    //     builder: (ctx) => AlertDialog(
    //       shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
    //       title: const Text('Peringatan'),
    //       content: const Text(
    //           'Toko ini memiliki tagihan yang melewati tenggat pembayaran. Harap lunasi tagihan terlebih dahulu sebelum membuat order baru.'),
    //       actions: [
    //         TextButton(
    //             onPressed: () => Navigator.pop(ctx),
    //             child: const Text('Tutup')),
    //       ],
    //     ),
    //   );
    //   return; // ✅ Hentikan proses, jangan buka halaman detail
    // }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailScreen(store: store),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openExtraOrderDetail(ExtraOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExtraOrderDetailScreen(orderId: order.id),
      ),
    );
    if (mounted) _load();
  }

  // ✅ Cek Warning sebelum membuat order
  Future<void> _onFabPressed() async {
    // if (_warningStoresCount > 0) {
    //   showDialog(
    //     context: context,
    //     builder: (ctx) => AlertDialog(
    //       shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
    //       title: const Text('Peringatan'),
    //       content: const Text(
    //           'Terdapat nota yang melewati masa tenggat pembayaran. Lunasi tagihan terlebih dahulu sebelum membuat order baru.'),
    //       actions: [
    //         TextButton(
    //             onPressed: () => Navigator.pop(ctx),
    //             child: const Text('Tutup')),
    //       ],
    //     ),
    //   );
    //   return;
    // }

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

  Map<String, int> get _productTargets {
    final map = <String, int>{};
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

  int get _paidStores => _todayOrders.where((o) => o.isPaid).length;
  int get _totalShippedProducts =>
      _todayOrders.fold(0, (s, o) => s + o.shippedQuantity);
  int get _totalSisaProducts =>
      _todayOrders.fold(0, (s, o) => s + o.sisaQuantity);

  int get _deliveredStores {
    final doneStoreIds = _todayOrders
        .where((o) => o.status == 'COMPLETED' || o.hasDeliveryProof)
        .map((o) => o.store?.id)
        .whereType<String>()
        .toSet();

    return _stores.where((s) => doneStoreIds.contains(s.id)).length;
  }

  double get _dailyPerformance {
    if (_stores.isEmpty) return 0.0;
    return (_deliveredStores / _stores.length) * 100;
  }

  double get _weeklyPerformance {
    final totalStores = _weeklyOrders
        .map((o) => o.store?.id)
        .whereType<String>()
        .toSet()
        .length;
    if (totalStores == 0) return 0.0;

    final doneStores = _weeklyOrders
        .where((o) => o.status == 'COMPLETED' || o.hasDeliveryProof)
        .map((o) => o.store?.id)
        .whereType<String>()
        .toSet()
        .length;

    return (doneStores / totalStores) * 100;
  }

  List<Order> get _deliveredUnpaidOrders {
    return _allUnpaidOrders
        .where((o) => o.hasDeliveryProof || o.status == 'COMPLETED')
        .toList();
  }

  int get _totalNotaTagihanKemarin {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return _deliveredUnpaidOrders.where((o) {
      final d = o.date.toLocal();
      return d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day;
    }).length;
  }

  int get _totalNotaTagihan => _deliveredUnpaidOrders.length;

  int get _warningStoresCount {
    final warningStoreIds = <String>{};
    for (final o in _deliveredUnpaidOrders) {
      final daysLate = DateTime.now()
          .difference(DateTime(o.date.year, o.date.month, o.date.day))
          .inDays;
      final pm = o.store?.paymentMethod?.toUpperCase() ?? 'DAILY';

      bool isWarning = false;
      if (pm == 'DAILY' || pm == 'HARIAN')
        isWarning = daysLate > 2;
      else if (pm == 'WEEKLY' || pm == 'MINGGUAN_1')
        isWarning = daysLate > 8;
      else if (pm == 'MONTHLY' || pm == 'BULANAN') isWarning = daysLate > 15;

      if (isWarning && o.store?.id != null) warningStoreIds.add(o.store!.id);
    }
    return warningStoreIds.length;
  }

  // ... (Sisa kode UI tetap sama)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeSummaryCard(
                user: _user,
                productSummary: _productSummary,
                totalQty: _totalQty,
                totalRemaining: _totalRemaining,
                totalAmount: _totalAmount,
                totalPiutang: _totalPiutang,
                totalStoresYesterday: _todayOrders.length,
                paidStores: _paidStores,
                totalShippedProducts: _totalShippedProducts,
                totalStoresToday: _stores.length,
                deliveredStores: _deliveredStores,
                totalNotaTagihan: _totalNotaTagihan,
                warningStores: _warningStoresCount,
                dailyPerformance: _dailyPerformance,
                weeklyPerformance: _weeklyPerformance,
                totalSisaProducts: _totalSisaProducts,
                totalNotaTagihanKemarin: _totalNotaTagihanKemarin,
                onProductTap: _showProductDetail,
                onLocationTap: () => _showLocationDetail(isWeekly: false),
                onTagihanTap: () => _showTagihanDetail(isYesterday: false),
                onWarningTap: _showWarningDetail,
                onDailyTap: () => _showLocationDetail(isWeekly: false),
                onWeeklyTap: () => _showLocationDetail(isWeekly: true),
                onSisaTap: _showSisaDetail,
                onTagihanKemarinTap: () =>
                    _showTagihanDetail(isYesterday: true),
              ),
            ),
            SliverToBoxAdapter(
              child: DateFilterWidget(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                  _load();
                },
              ),
            ),
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
            _buildBody(),
            if (_todayExtraOrders.isNotEmpty) ...[
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
                      const Icon(
                        Icons.flash_on_rounded,
                        size: 16,
                        color: Color(0xFF7B1FA2),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'EXTRA ORDER',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: Color(0xFF7B1FA2),
                          ),
                        ),
                      ),
                      Text(
                        '${_todayExtraOrders.length} order',
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                ),
                sliver: SliverList.separated(
                  itemCount: _todayExtraOrders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.md),
                  itemBuilder: (_, i) {
                    final extra = _todayExtraOrders[i];
                    return ExtraOrderSummaryCard(
                      order: extra,
                      onTap: () => _openExtraOrderDetail(extra),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

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

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      sliver: SliverList.separated(
        itemCount: _stores.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
        itemBuilder: (_, i) {
          final store = _stores[i];
          final todayOrder = _findTodayOrderForStore(store.id);

          final int totalNota = _getStoreUnpaidCount(store.id);
          final double piutang = _getStorePiutang(store.id);
          final bool isWarning = _isStoreWarning(store.id, store.paymentMethod);

          return StoreSummaryCard(
            store: store,
            todayOrder: todayOrder,
            totalNota: totalNota,
            totalPiutang: piutang,
            isWarning: isWarning,
            // ✅ Kirim status warning ke detail toko
            onTap: () => _openStoreDetail(store, isWarning),
          );
        },
      ),
    );
  }

  // ... (Sisa method _showKpiDetail dll tetap sama, tidak perlu diubah)
  void _showKpiDetail(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 16, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  void _showProductDetail() {
    final targets = _productTargets;
    final shipped = _productSummary;

    _showKpiDetail(
      'Detail Pengiriman Produk',
      ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: targets.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final name = targets.keys.elementAt(i);
          final target = targets[name] ?? 0;
          final done = shipped[name] ?? 0;
          final isDone = done >= target;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isDone ? Colors.green.shade100 : Colors.orange.shade100,
              child: Icon(
                isDone ? Icons.check : Icons.inventory_2,
                color: isDone ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            title:
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Terkirim: $done / $target pcs'),
            trailing: isDone
                ? const Text('Selesai',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold))
                : Text('Kurang ${target - done}',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  void _showLocationDetail({bool isWeekly = false}) {
    final orders = isWeekly ? _weeklyOrders : _todayOrders;
    final storeIds = orders.map((o) => o.store?.id).whereType<String>().toSet();
    final storeList = _stores.where((s) => storeIds.contains(s.id)).toList();

    _showKpiDetail(
      isWeekly ? 'Detail Performa Mingguan' : 'Detail Lokasi Hari Ini',
      ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: storeList.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final store = storeList[i];
          final order = orders.firstWhere((o) => o.store?.id == store.id,
              orElse: () => null as dynamic);
          final isDone = order != null &&
              (order.status == 'COMPLETED' || order.hasDeliveryProof);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isDone ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                isDone ? Icons.check : Icons.location_off,
                color: isDone ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(store.name ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isDone ? 'Sudah dikunjungi' : 'Belum dikunjungi'),
            trailing: isDone
                ? const Text('Selesai',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold))
                : const Text('Belum',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  void _showSisaDetail() {
    final sisaOrders = _todayOrders.where((o) => o.sisaQuantity > 0).toList();

    _showKpiDetail(
      'Detail Sisa Produk (Tidak Terjual)',
      ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: sisaOrders.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final order = sisaOrders[i];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFF3E0),
              child: Icon(Icons.inventory, color: Colors.orange, size: 20),
            ),
            title: Text(order.store?.name ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Terkirim: ${order.shippedQuantity} pcs'),
            trailing: Text(
              'Sisa: ${order.sisaQuantity} pcs',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          );
        },
      ),
    );
  }

  void _showTagihanDetail({bool isYesterday = false}) {
    var orders = _deliveredUnpaidOrders;

    if (isYesterday) {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      orders = orders.where((o) {
        final d = o.date.toLocal();
        return d.year == yesterday.year &&
            d.month == yesterday.month &&
            d.day == yesterday.day;
      }).toList();
    }

    _showKpiDetail(
      isYesterday ? 'Detail Tagihan Kemarin' : 'Detail Semua Nota Tagihan',
      ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final order = orders[i];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF3E5F5),
              child:
                  Icon(Icons.receipt_long, color: Color(0xFF7B1FA2), size: 20),
            ),
            title: Text(order.store?.name ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${Formatters.date(order.date)} • ${order.totalQuantity} pcs'),
            trailing: Text(
              Formatters.currency(order.totalAmount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
          );
        },
      ),
    );
  }

  void _showWarningDetail() {
    final warningOrders = _deliveredUnpaidOrders.where((o) {
      final daysLate = DateTime.now()
          .difference(DateTime(o.date.year, o.date.month, o.date.day))
          .inDays;
      final pm = o.store?.paymentMethod?.toUpperCase() ?? 'DAILY';
      if (pm == 'DAILY' || pm == 'HARIAN') return daysLate > 2;
      if (pm == 'WEEKLY' || pm == 'MINGGUAN_1') return daysLate > 8;
      if (pm == 'MONTHLY' || pm == 'BULANAN') return daysLate > 15;
      return false;
    }).toList();

    _showKpiDetail(
      'Detail Toko Warning',
      ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: warningOrders.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final order = warningOrders[i];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.warning_rounded,
                  color: Color(0xFFD32F2F), size: 20),
            ),
            title: Text(order.store?.name ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Tenggat: ${Formatters.paymentMethod(order.store?.paymentMethod)}'),
            trailing: Text(
              Formatters.currency(order.totalAmount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
