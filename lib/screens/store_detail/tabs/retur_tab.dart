import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../../services/retur_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/date_filter_widget.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/loading_state.dart';
import '../widgets/order_card.dart';

class ReturTab extends StatefulWidget {
  final String storeId;
  const ReturTab({super.key, required this.storeId});

  @override
  State<ReturTab> createState() => _ReturTabState();
}

class _ReturTabState extends State<ReturTab> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

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

      final all = await ReturService.getList();
      // ✅ Filter inklusif (order 00:00:00 & 23:59:59 tetap masuk)
      final filtered = all.where((x) {
        return x.store?.id == widget.storeId &&
            x.totalQuantity > 0 &&
            !x.date.isBefore(start) &&
            !x.date.isAfter(end);
      }).toList();

      if (mounted) setState(() => _orders = filtered);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showReturDialog(Order order) async {
    final qtyCtrl = TextEditingController(text: '${order.totalQuantity}');
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: const Text('Ajukan Retur'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Order ${Formatters.date(order.date)}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total order: ${order.totalQuantity} pcs',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah diretur (pcs)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Masukkan angka > 0';
                    if (n > order.totalQuantity) {
                      return 'Maksimal ${order.totalQuantity}';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        // ✅ Sesuai signature ReturService.process()
                        await ReturService.process(
                          orderId: order.id,
                          qty: int.parse(qtyCtrl.text),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack('Retur berhasil diajukan');
                        _load();
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() => submitting = false);
                        }
                        _snack('Gagal: $e');
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Ajukan'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
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
                          icon: Icons.assignment_return_outlined,
                          message: 'Belum ada retur di tanggal ini',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSizes.lg),
                            itemCount: _orders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSizes.md - 2),
                            itemBuilder: (_, i) {
                              final o = _orders[i];
                              return OrderCard(
                                order: o,
                                trailing: AppButton(
                                  label: 'Retur',
                                  icon: Icons.assignment_return,
                                  outlined: true,
                                  onPressed: () => _showReturDialog(o),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
