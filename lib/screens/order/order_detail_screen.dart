import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_stamp.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/yellow_header.dart';
import '../../core/utils/image_picker_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;
  bool _saving = false;

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
      final o = await OrderService.getDetail(widget.orderId);
      if (mounted) setState(() => _order = o);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============ PENGIRIMAN ============
  Future<void> _editDelivery() async {
    if (_order == null) return;
    final ctrl = TextEditingController(text: '${_order!.shippedQuantity}');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text('Update Pengiriman'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Total qty: ${_order!.totalQuantity}'),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah terkirim'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Angka tidak valid';
                  if (n > _order!.totalQuantity) {
                    return 'Maksimal ${_order!.totalQuantity}';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7043),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await OrderService.updateDelivery(
        _order!.id,
        shippedQuantity: int.parse(ctrl.text),
      );
      await _load();
      _snack('Pengiriman diperbarui');
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Foto bukti KIRIM dengan timestamp
  Future<void> _captureDeliveryProof() async {
    final picked = await ImagePickerHelper.pickImage(context);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final raw = await picked.readAsBytes();
      final stamped = await ImageStamp.addTimestamp(
        raw,
        label: 'BUKTI PENGIRIMAN',
      );

      // Batas 2MB (base64 akan ~1.33x ukuran asli, jadi masih < 2.8MB)
      if (stamped.length > 2 * 1024 * 1024) {
        _snack(
            'Gambar masih terlalu besar. Coba foto dengan resolusi lebih rendah.');
        return;
      }

      final b64 = base64Encode(stamped);

      await OrderService.updateDelivery(
        _order!.id,
        deliveryProof: b64,
      );
      await _load();
      _snack('Bukti pengiriman terkirim');
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _completeOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text('Selesaikan Order'),
        content: const Text('Yakin tandai order ini sebagai COMPLETED?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await OrderService.updateDelivery(_order!.id, status: 'COMPLETED');
      await _load();
      _snack('Order diselesaikan');
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============ PEMBAYARAN ============
  /// Dialog pilih metode bayar
  Future<void> _choosePaymentMethod() async {
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
              'Pilih Metode Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
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
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );

    if (method == null) return;

    if (method == 'CASH') {
      await _setPaidCash();
    } else {
      await _pickAndUploadProofTransfer();
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
                  letterSpacing: 0.5,
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

  /// CASH: langsung tandai lunas
  Future<void> _setPaidCash() async {
    setState(() => _saving = true);
    try {
      await OrderService.updatePayment(
        _order!.id,
        paymentStatus: 'PAID',
        paymentMethod: 'CASH',
      );
      await _load();
      _snack('Ditandai lunas (CASH)');
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// TRANSFER: foto bukti + timestamp, lalu set PAID
  Future<void> _pickAndUploadProofTransfer() async {
    final picked = await ImagePickerHelper.pickImage(context);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final raw = await picked.readAsBytes();
      final stamped = await ImageStamp.addTimestamp(
        raw,
        label: 'BUKTI PEMBAYARAN',
      );

      if (stamped.length > 2 * 1024 * 1024) {
        _snack(
            'Gambar masih terlalu besar. Coba lagi dengan resolusi lebih rendah.');
        return;
      }

      final b64 = base64Encode(stamped);

      await OrderService.updatePayment(
        _order!.id,
        paymentStatus: 'PAID',
        paymentMethod: 'TRANSFER',
        paymentProof: b64,
      );
      await _load();
      _snack('Bukti transfer terkirim');
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          YellowHeader(
            title: 'Detail Order',
            subtitle: _order != null
                ? (_order!.store?.name ?? 'Toko tidak diketahui')
                : 'Memuat...',
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off,
                                  size: 64, color: Colors.grey.shade400),
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
                      )
                    : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar:
          (_order != null && _order!.isEditable) ? _buildActions() : null,
    );
  }

  Widget _buildContent() {
    final o = _order!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.md + 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _statusColor(o.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(o.status),
                      color: _statusColor(o.status)),
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
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(status: o.status),
                    ],
                  ),
                ),
                if (o.isPaid)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      o.paymentMethod == 'CASH'
                          ? 'LUNAS · CASH'
                          : 'LUNAS · TRANSFER',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D32),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Pengiriman
          _card(
            'Pengiriman',
            Icons.local_shipping_rounded,
            const Color(0xFF1976D2),
            [
              Row(
                children: [
                  Expanded(
                    child: _qtyStat(
                        'Total', o.totalQuantity, const Color(0xFF1976D2)),
                  ),
                  Expanded(
                    child: _qtyStat(
                        'Terkirim', o.shippedQuantity, const Color(0xFF2E7D32)),
                  ),
                  Expanded(
                    child:
                        _qtyStat('Sisa', o.remaining, const Color(0xFFE65100)),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: AppSizes.sm),
              _infoRow('Total Uang', Formatters.currency(o.totalAmount)),
              _infoRow('Harga Satuan', Formatters.currency(o.price)),
              if (o.note != null && o.note!.isNotEmpty)
                _infoRow('Catatan', o.note!),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Pembayaran
          _card(
            'Pembayaran',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF7B1FA2),
            [
              _infoRow('Status', Formatters.paymentStatus(o.paymentStatus)),
              if (o.paymentMethod != null)
                _infoRow(
                  'Metode',
                  o.paymentMethod == 'CASH' ? 'Cash' : 'Transfer',
                ),
              if (o.paymentProofAt != null)
                _infoRow(
                  'Waktu Bayar',
                  DateFormat('dd MMM yyyy • HH:mm', 'id_ID')
                      .format(o.paymentProofAt!),
                ),
              if (o.hasPaymentProof)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bukti Pembayaran',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProofImage(o.paymentProof!),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Bukti Kirim
          _card(
            'Bukti Pengiriman',
            Icons.photo_camera_rounded,
            const Color(0xFF2E7D32),
            [
              if (o.deliveryProofAt != null)
                _infoRow(
                  'Waktu',
                  DateFormat('dd MMM yyyy • HH:mm', 'id_ID')
                      .format(o.deliveryProofAt!),
                ),
              if (o.hasDeliveryProof)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.sm),
                  child: _buildProofImage(o.deliveryProof!),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Belum ada foto bukti pengiriman',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Produk
          if (o.items.isNotEmpty)
            _card(
              'Produk',
              Icons.shopping_bag_rounded,
              const Color(0xFFD32F2F),
              o.items
                  .map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 18,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                it.productName ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            Text(
                              '${it.quantity} pcs',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  Widget _card(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyStat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildProofImage(String data) {
    try {
      Uint8List? bytes;
      if (data.startsWith('data:image')) {
        bytes = base64Decode(data.split(',').last);
      } else if (data.length > 200) {
        bytes = base64Decode(data);
      }
      if (bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      }
    } catch (_) {}
    return Image.network(
      data,
      errorBuilder: (_, __, ___) => const Text('Gambar tidak bisa dimuat'),
    );
  }

  Widget _buildActions() {
    final o = _order!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Baris 1: Pembayaran & Bukti Kirim
              if (!o.isPaid)
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.account_balance_wallet,
                        label: 'Bayar',
                        color: const Color(0xFF2E7D32),
                        onTap: _saving ? null : _choosePaymentMethod,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.camera_alt,
                        label: 'Bukti Kirim',
                        color: const Color(0xFF7B1FA2),
                        outlined: true,
                        onTap: _saving ? null : _captureDeliveryProof,
                      ),
                    ),
                  ],
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.camera_alt,
                        label: o.hasDeliveryProof
                            ? 'Ganti Bukti Kirim'
                            : 'Bukti Kirim',
                        color: const Color(0xFF7B1FA2),
                        outlined: true,
                        onTap: _saving ? null : _captureDeliveryProof,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSizes.sm),

              // Baris 2: Update Kirim & Selesaikan
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.edit,
                      label: 'Update Kirim',
                      color: const Color(0xFF1976D2),
                      outlined: true,
                      onTap: _saving ? null : _editDelivery,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.done_all,
                      label: 'Selesaikan',
                      color: const Color(0xFFFF7043),
                      onTap: _saving ? null : _completeOrder,
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'DELIVERED':
        return const Color(0xFF1976D2);
      case 'COMPLETED':
        return const Color(0xFF2E7D32);
      case 'CANCELLED':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF616161);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'DELIVERED':
        return Icons.local_shipping_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
