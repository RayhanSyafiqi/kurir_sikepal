import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../services/order_service.dart';
import '../../../services/product_service.dart';

class ProdukTab extends StatefulWidget {
  final String storeId;
  const ProdukTab({super.key, required this.storeId});

  @override
  State<ProdukTab> createState() => _ProdukTabState();
}

class _ProdukTabState extends State<ProdukTab> {
  List<Order> _orders = [];
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

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
      final results = await Future.wait([
        OrderService.getAll(storeId: widget.storeId, limit: 200),
        ProductService.getAll(limit: 200),
      ]);
      if (mounted) {
        setState(() {
          _orders = results[0] as List<Order>;
          _products = results[1] as List<Product>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Hitung total qty per produk dari semua order
  Map<String, int> get _productTotals {
    final map = <String, int>{};
    for (final p in _products) {
      map[p.id] = 0;
    }
    for (final o in _orders) {
      for (final item in o.items) {
        final pid = item.productId;
        if (pid != null) {
          map[pid] = (map[pid] ?? 0) + item.quantity;
        }
      }
    }
    return map;
  }

  int get _grandTotal => _productTotals.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _load,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final totals = _productTotals;
    final hasData = totals.values.any((v) => v > 0);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          _summaryCard(),
          const SizedBox(height: AppSizes.md),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Color(0xFFD1D5DB),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada pengiriman produk',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._products
                .where((p) => (totals[p.id] ?? 0) > 0)
                .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm + 2),
                      child: _productRow(
                        p.name,
                        totals[p.id] ?? 0,
                        _grandTotal,
                      ),
                    )),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final orderCount = _orders.length;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md + 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stat('Total Order', '$orderCount', Colors.white),
          ),
          Container(width: 1, height: 36, color: Colors.white30),
          Expanded(
            child: _stat('Total Item', '$_grandTotal', Colors.white),
          ),
          Container(width: 1, height: 36, color: Colors.white30),
          Expanded(
            child: _stat(
              'Jenis Produk',
              '${_products.where((p) => (_productTotals[p.id] ?? 0) > 0).length}',
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _productRow(String name, int qty, int total) {
    final pct = total == 0 ? 0.0 : qty / total;
    final color = _colorForProduct(name);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(pct * 100).toStringAsFixed(1)}% dari total',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '$qty',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const Text(
                  'pcs',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
