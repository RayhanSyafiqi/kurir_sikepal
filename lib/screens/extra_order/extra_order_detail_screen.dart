import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/utils/image_stamp.dart';
import '../../models/extra_order_model.dart';
import '../../services/extra_order_service.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/yellow_header.dart';

class ExtraOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const ExtraOrderDetailScreen({super.key, required this.orderId});

  @override
  State<ExtraOrderDetailScreen> createState() => _ExtraOrderDetailScreenState();
}

class _ExtraOrderDetailScreenState extends State<ExtraOrderDetailScreen> {
  ExtraOrder? _order;
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
      final o = await ExtraOrderService.getDetail(widget.orderId);
      if (mounted) setState(() => _order = o);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============ BUKTI KIRIM ============
  Future<void> _captureDeliveryProof() async {
    final picked = await ImagePickerHelper.pickImage(context);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final raw = await picked.readAsBytes();
      final stamped = await ImageStamp.addTimestamp(
        raw,
        label: 'BUKTI PENGIRIMAN (EXTRA)',
      );

      if (stamped.length > 2 * 1024 * 1024) {
        _snack('Gambar terlalu besar');
        return;
      }

      final b64 = base64Encode(stamped);
      await ExtraOrderService.updateDelivery(
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
      await ExtraOrderService.updateDelivery(
        _order!.id,
        status: 'COMPLETED',
      );
      await _load();
      _snack('Order diselesaikan');
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============ PEMBAYARAN ============
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

  Future<void> _setPaidCash() async {
    setState(() => _saving = true);
    try {
      await ExtraOrderService.updatePayment(
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

  Future<void> _pickAndUploadProofTransfer() async {
    final picked = await ImagePickerHelper.pickImage(context);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final raw = await picked.readAsBytes();
      final stamped = await ImageStamp.addTimestamp(
        raw,
        label: 'BUKTI TRANSFER (EXTRA)',
      );

      if (stamped.length > 2 * 1024 * 1024) {
        _snack('Gambar terlalu besar');
        return;
      }

      final b64 = base64Encode(stamped);
      await ExtraOrderService.updatePayment(
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
            title: 'Detail Extra Order',
            subtitle: _order != null
                ? (_order!.customerName ?? 'Tanpa Nama')
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
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Color(0xFF7B1FA2),
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

          // Info Customer
          _card(
            'Info Customer',
            Icons.person_rounded,
            const Color(0xFF7B1FA2),
            [
              _infoRow('Nama Toko', o.customerName ?? '-'),
              if (o.customerPhone != null && o.customerPhone!.isNotEmpty)
                _infoRow('No. HP', o.customerPhone!),
              if (o.address != null && o.address!.isNotEmpty)
                _infoRow('Alamat', o.address!),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Pengiriman
          _card(
            'Pengiriman',
            Icons.local_shipping_rounded,
            const Color(0xFF1976D2),
            [
              _infoRow('Total Qty', '${o.totalQuantity} pcs'),
              _infoRow('Total Uang', Formatters.currency(o.totalAmount)),
              _infoRow('Harga Rata-rata', Formatters.currency(o.price)),
              if (o.note != null && o.note!.isNotEmpty)
                _infoRow('Catatan', o.note!),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Pembayaran
          _card(
            'Pembayaran',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF2E7D32),
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
            const Color(0xFFF57C00),
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
              const Color(0xFF7B1FA2),
              o.items
                  .map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 18,
                                color: Color(0xFF7B1FA2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                it.productName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${it.quantity} pcs',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF7B1FA2),
                                  ),
                                ),
                                if (it.price > 0)
                                  Text(
                                    Formatters.currency(it.price * it.quantity),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                              ],
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
            width: 110,
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
                        color: const Color(0xFFF57C00),
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
                        color: const Color(0xFFF57C00),
                        outlined: true,
                        onTap: _saving ? null : _captureDeliveryProof,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.done_all,
                      label: 'Selesaikan',
                      color: const Color(0xFF7B1FA2),
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
}
