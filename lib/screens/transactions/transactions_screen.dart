import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/yellow_header.dart';
import '../order/order_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL'; // ALL, UNPAID, PAID

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
      final list = await OrderService.getAll(limit: 200);
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _filtered {
    switch (_filter) {
      case 'UNPAID':
        return _orders.where((o) => !o.isPaid).toList();
      case 'PAID':
        return _orders.where((o) => o.isPaid).toList();
      default:
        return _orders;
    }
  }

  double get _totalAll => _orders.fold(0.0, (s, o) => s + o.totalAmount);
  double get _totalPaid =>
      _orders.where((o) => o.isPaid).fold(0.0, (s, o) => s + o.totalAmount);
  double get _totalUnpaid => _totalAll - _totalPaid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          YellowHeader(
            title: 'Transaksi',
            subtitle: '${_orders.length} order',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.lg),
                children: [
                  _summaryRow(),
                  const SizedBox(height: AppSizes.lg),
                  _filterChips(),
                  const SizedBox(height: AppSizes.md),
                  ..._buildList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Total',
            Formatters.currency(_totalAll),
            const Color(0xFF1976D2),
            Icons.receipt_long,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _summaryCard(
            'Lunas',
            Formatters.currency(_totalPaid),
            const Color(0xFF2E7D32),
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _summaryCard(
            'Piutang',
            Formatters.currency(_totalUnpaid),
            const Color(0xFFD32F2F),
            Icons.access_time,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    final chips = [
      ('ALL', 'Semua'),
      ('UNPAID', 'Belum Bayar'),
      ('PAID', 'Lunas'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final active = _filter == c.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: ChoiceChip(
              label: Text(c.$2),
              selected: active,
              onSelected: (_) => setState(() => _filter = c.$1),
              selectedColor: const Color(0xFFFFC107),
              labelStyle: TextStyle(
                color: active ? Colors.white : const Color(0xFF374151),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildList() {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text(_error!)),
        ),
      ];
    }
    final list = _filtered;
    if (list.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada transaksi',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return list
        .map((o) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: _txCard(o),
            ))
        .toList();
  }

  Widget _txCard(Order o) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: o.id),
            ),
          );
          _load();
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: o.isPaid
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  o.isPaid ? Icons.check_circle : Icons.access_time,
                  color: o.isPaid
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (o.store?.name ?? '-').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.date(o.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(o.totalAmount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    o.isPaid ? 'LUNAS' : 'BELUM BAYAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: o.isPaid
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
