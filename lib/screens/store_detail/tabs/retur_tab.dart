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
      // ✅ Filter inklusif
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
    // ✅ Siapkan Controller
    final qtyCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController();
    final sisaCtrl = TextEditingController(text: '${order.sisaQuantity}');

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
          content: SingleChildScrollView(
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
                  'Total terkirim: ${order.shippedQuantity} pcs',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.md),

                // ✅ Input Jumlah Retur
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah diretur (pcs)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Input Alasan Retur
                TextFormField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alasan Retur (Rusak, dll)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Input Sisa
                TextFormField(
                  controller: sisaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sisa (Tidak terjual)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
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
                      setDialogState(() => submitting = true);
                      try {
                        final qty = int.tryParse(qtyCtrl.text) ?? 0;
                        final sisa = int.tryParse(sisaCtrl.text) ?? 0;

                        await ReturService.process(
                          orderId: order.id,
                          qty: qty,
                          sisaQuantity: sisa,
                          reason: reasonCtrl.text.trim(),
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
                  : const Text('Simpan'),
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
