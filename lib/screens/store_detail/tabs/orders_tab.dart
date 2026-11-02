import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/order_model.dart';
import '../../../services/order_service.dart';
import '../../../widgets/date_filter_widget.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/loading_state.dart';
import '../../order/order_detail_screen.dart';
import '../widgets/order_card.dart';

class OrdersTab extends StatefulWidget {
  final String storeId;
  const OrdersTab({super.key, required this.storeId});
  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now(); // ✅ Filter Tanggal

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
      final start =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final end = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, 23, 59, 59);
      final o = await OrderService.getAll(
          storeId: widget.storeId, startDate: start, endDate: end);
      if (mounted) setState(() => _orders = o);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DateFilterWidget(
          selectedDate: _selectedDate,
          onDateChanged: (date) {
            setState(() => _selectedDate = date);
            _load();
          },
        ),
        Expanded(
          child: _loading
              ? const LoadingState()
              : _error != null
                  ? ErrorState(message: _error!, onRetry: _load)
                  : _orders.isEmpty
                      ? const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          message: 'Belum ada pesanan di tanggal ini')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSizes.lg),
                            itemCount: _orders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSizes.md - 2),
                            itemBuilder: (_, i) => OrderCard(
                              order: _orders[i],
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => OrderDetailScreen(
                                            orderId: _orders[i].id)));
                                _load();
                              },
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}
