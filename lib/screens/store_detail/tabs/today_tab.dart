import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../../services/order_service.dart';
import '../../order/order_detail_screen.dart';
import '../widgets/order_card.dart';

class TodayTab extends StatefulWidget {
  final String storeId;
  const TodayTab({super.key, required this.storeId});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  List<Order> _orders = [];
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
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final all = await OrderService.getAll(
        storeId: widget.storeId,
        startDate: start,
        endDate: end,
        limit: 100,
      );
      if (mounted) setState(() => _orders = all);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _errorView(_error!);
    }
    if (_orders.isEmpty) {
      return _emptyView(
        Icons.today_outlined,
        'Belum ada pengiriman hari ini',
        'Order yang dibuat hari ini akan muncul di sini',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          _summaryCard(),
          const SizedBox(height: AppSizes.md),
          ..._orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm + 2),
              child: OrderCard(
                order: o,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: o.id),
                    ),
                  );
                  _load();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final totalQty = _orders.fold<int>(0, (s, o) => s + o.totalQuantity);
    final totalAmount = _orders.fold<double>(0, (s, o) => s + o.totalAmount);

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
            child: _stat('Order', '${_orders.length}', Colors.white),
          ),
          Container(width: 1, height: 36, color: Colors.white30),
          Expanded(
            child: _stat('Qty', '$totalQty', Colors.white),
          ),
          Container(width: 1, height: 36, color: Colors.white30),
          Expanded(
            child: _stat(
              'Total',
              Formatters.currency(totalAmount),
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
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _errorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center),
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

  Widget _emptyView(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
