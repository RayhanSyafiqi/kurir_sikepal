import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart'; // ✅ TAMBAH INI
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/utils/image_stamp.dart';
import '../../../core/utils/invoice_generator.dart';
import '../../../models/order_model.dart';
import '../../../services/order_service.dart';
import '../../order/order_detail_screen.dart';

class TransaksiTab extends StatefulWidget {
  final String storeId;
  const TransaksiTab({super.key, required this.storeId});

  @override
  State<TransaksiTab> createState() => _TransaksiTabState();
}

class _TransaksiTabState extends State<TransaksiTab> {
  List<Order> _all = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL';

  final Set<String> _selectedIds = {};
  bool _bulkProcessing = false;

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
      final list = await OrderService.getAll(
        storeId: widget.storeId,
        limit: 200,
      );
      if (mounted) {
        setState(() {
          _all = list;
          _selectedIds.removeWhere((id) => !list.any((o) => o.id == id));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _filtered {
    switch (_filter) {
      case 'PAID':
        return _all.where((o) => o.isPaid).toList();
      case 'UNPAID':
        return _all.where((o) => !o.isPaid).toList();
      default:
        return _all;
    }
  }

  double get _totalAll => _all.fold(0, (s, o) => s + o.totalAmount);
  double get _totalPaid =>
      _all.where((o) => o.isPaid).fold(0, (s, o) => s + o.totalAmount);
  double get _totalUnpaid => _totalAll - _totalPaid;

  double get _selectedTotal {
    return _all
        .where((o) => _selectedIds.contains(o.id))
        .fold(0, (s, o) => s + o.totalAmount);
  }

  int get _selectedCount => _selectedIds.length;

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAllUnpaid() {
    final unpaid = _filtered.where((o) => !o.isPaid).toList();
    setState(() {
      final allSelected = unpaid.every((o) => _selectedIds.contains(o.id));
      if (allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(unpaid.map((o) => o.id));
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _processBulkPayment() async {
    if (_selectedIds.isEmpty) return;

    final method = await showModalBottomSheet<String>(
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
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_selectedCount order • ${Formatters.currency(_selectedTotal)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: _methodButton(
                    icon: Icons.payments_rounded,
                    label: 'CASH',
                    subtitle: 'Bayar tunai',
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.pop(ctx, 'CASH'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _methodButton(
                    icon: Icons.account_balance_rounded,
                    label: 'TRANSFER',
                    subtitle: 'Upload bukti',
                    color: const Color(0xFF1976D2),
                    onTap: () => Navigator.pop(ctx, 'TRANSFER'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (method == null) return;

    if (method == 'CASH') {
      await _executeBulkPayment('CASH', null);
    } else {
      await _pickProofAndPay();
    }
  }

  Future<void> _pickProofAndPay() async {
    final picked = await ImagePickerHelper.pickImage(context);
    if (picked == null) return;

    try {
      final raw = await picked.readAsBytes();
      final stamped = await ImageStamp.addTimestamp(
        raw,
        label: 'BUKTI TRANSFER (${_selectedCount} ORDER)',
      );

      if (stamped.length > 2 * 1024 * 1024) {
        _snack('Gambar terlalu besar, coba lagi');
        return;
      }

      final b64 = base64Encode(stamped);
      await _executeBulkPayment('TRANSFER', b64);
    } catch (e) {
      _snack('Gagal: $e');
    }
  }

  Future<void> _executeBulkPayment(String method, String? proof) async {
    setState(() => _bulkProcessing = true);

    final count = _selectedIds.length;
    final total = _selectedTotal;
    final orderIds = _selectedIds.toList();

    try {
      // ✅ HAPUS VARIABEL 'result' YANG TIDAK TERPAKAI
      await OrderService.bulkPayment(
        orderIds: orderIds,
        paymentMethod: method,
        paymentProof: proof,
      );

      if (!mounted) return;
      _clearSelection();
      await _load();

      final paidOrders = _all.where((o) => orderIds.contains(o.id)).toList();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran Berhasil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count order senilai ${Formatters.currency(total)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          final pdfBytes =
                              await InvoiceGenerator.generate(paidOrders);
                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async => pdfBytes,
                            name:
                                'Invoice_Gabungan_${DateTime.now().millisecondsSinceEpoch}',
                          );
                        } catch (e) {
                          _snack('Gagal mencetak invoice: $e');
                        }
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Cetak Invoice'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _bulkProcessing = false);
    }
  }

  Widget _methodButton({
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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
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

    final list = _filtered;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.only(
              left: AppSizes.lg,
              right: AppSizes.lg,
              top: AppSizes.lg,
              bottom: _selectedCount > 0 ? 120 : AppSizes.lg,
            ),
            children: [
              _summaryRow(),
              const SizedBox(height: AppSizes.md),
              _filterChips(),
              const SizedBox(height: AppSizes.md),
              if (_filter != 'PAID' && list.any((o) => !o.isPaid))
                _selectAllButton(list),
              if (list.isEmpty)
                _emptyFiltered()
              else
                ...list.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm + 2),
                    child: _txCard(o),
                  ),
                ),
            ],
          ),
        ),
        if (_selectedCount > 0) _bulkBottomBar(),
      ],
    );
  }

  Widget _summaryRow() {
    return Row(
      children: [
        Expanded(
          child: _summary('Total', Formatters.currency(_totalAll),
              const Color(0xFF1976D2), Icons.receipt_long),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _summary('Lunas', Formatters.currency(_totalPaid),
              const Color(0xFF2E7D32), Icons.check_circle),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _summary('Piutang', Formatters.currency(_totalUnpaid),
              const Color(0xFFD32F2F), Icons.access_time),
        ),
      ],
    );
  }

  Widget _summary(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
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
      ('ALL', 'Semua', Icons.list_alt),
      ('PAID', 'Lunas', Icons.check_circle),
      ('UNPAID', 'Belum Bayar', Icons.access_time),
    ];
    return Row(
      children: chips.map((c) {
        final active = _filter == c.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: c.$1 == 'UNPAID' ? 0 : AppSizes.sm),
            child: Material(
              color: active ? const Color(0xFFFFC107) : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: InkWell(
                onTap: () => setState(() => _filter = c.$1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Icon(
                        c.$3,
                        size: 18,
                        color: active ? Colors.white : const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              active ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _selectAllButton(List<Order> list) {
    final unpaid = list.where((o) => !o.isPaid).toList();
    final allSelected =
        unpaid.isNotEmpty && unpaid.every((o) => _selectedIds.contains(o.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          onTap: _selectAllUnpaid,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: 10),
            child: Row(
              children: [
                Icon(
                  allSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: allSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    allSelected
                        ? 'Batalkan pilih semua'
                        : 'Pilih semua belum bayar (${unpaid.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyFiltered() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            _filter == 'PAID'
                ? Icons.check_circle_outline
                : _filter == 'UNPAID'
                    ? Icons.access_time
                    : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            _filter == 'PAID'
                ? 'Belum ada transaksi lunas'
                : _filter == 'UNPAID'
                    ? 'Tidak ada piutang'
                    : 'Belum ada transaksi',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _txCard(Order o) {
    final isSelected = _selectedIds.contains(o.id);
    final canSelect = !o.isPaid;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: canSelect
            ? () => _toggleSelect(o.id)
            : () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(orderId: o.id),
                  ),
                );
                _load();
              },
        onLongPress: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: o.id),
            ),
          );
          _load();
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                if (canSelect)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.md),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD1D5DB),
                      size: 26,
                    ),
                  ),
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
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.date(o.date),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${o.totalQuantity} pcs · ${Formatters.orderStatus(o.status)}',
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: o.isPaid
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        o.isPaid ? 'LUNAS' : 'BELUM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: o.isPaid
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFD32F2F),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bulkBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                IconButton(
                  onPressed: _bulkProcessing ? null : _clearSelection,
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  tooltip: 'Batalkan',
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_selectedCount order dipilih',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Formatters.currency(_selectedTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _bulkProcessing ? null : _processBulkPayment,
                  icon: _bulkProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payments, size: 18),
                  label: Text(
                    _bulkProcessing ? 'Proses...' : 'Bayar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
