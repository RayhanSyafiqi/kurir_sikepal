import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_stamp.dart';
import '../../core/utils/invoice_generator.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/yellow_header.dart';

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
  Future<void> _captureDeliveryProof() async {
    Map<String, int> tempItemsQty = {
      for (var item in _order!.items) item.id: item.quantity
    };

    final noteCtrl = TextEditingController(text: _order!.note ?? '');
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        title: const Text('Konfirmasi Pengiriman'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ubah jumlah jika ada barang yang tidak diterima. Laporan retur/sisa dapat diisi di menu transaksi.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: AppSizes.md),
                    ..._order!.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.productName ?? '-',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                initialValue: '${item.quantity}',
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n < 0) return 'Invalid';
                                  return null;
                                },
                                onChanged: (v) {
                                  tempItemsQty[item.id] = int.tryParse(v) ?? 0;
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSizes.md),
                    const Text(
                      'Catatan Kurir (Opsional)',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 2 pcs rusak, 1 pcs tidak tersedia',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00)),
            child: const Text('Lanjut Foto'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final actualShipped = tempItemsQty.values.fold(0, (a, b) => a + b);

    ImageSource source = ImageSource.camera;
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      source = ImageSource.gallery;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final raw = await picked.readAsBytes();
      final stamped =
          await ImageStamp.addTimestamp(raw, label: 'BUKTI PENGIRIMAN');

      if (stamped.length > 2 * 1024 * 1024) {
        _snack('Gambar masih terlalu besar.');
        return;
      }

      final b64 = base64Encode(stamped);

      final updatedItems = _order!.items.map((item) {
        return {
          "id": item.id,
          "quantity": tempItemsQty[item.id] ?? item.quantity
        };
      }).toList();

      await OrderService.updateDelivery(
        _order!.id,
        shippedQuantity: actualShipped,
        deliveryProof: b64,
        items: updatedItems,
        note: noteCtrl.text.trim(),
      );
      await _load();
      _snack('Pengiriman dikirim. Menunggu persetujuan Admin.');
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _printInvoice() async {
    if (_order == null) return;
    setState(() => _saving = true);
    try {
      final pdfBytes = await InvoiceGenerator.generate([_order!]);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Invoice_${_order!.id.substring(0, 6)}',
      );
    } catch (e) {
      _snack('Gagal mencetak invoice: $e');
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
      bottomNavigationBar: _order != null ? _buildActions() : null,
    );
  }

  Widget _buildContent() {
    final o = _order!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
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
          _card(
            'Pengiriman',
            Icons.local_shipping_rounded,
            const Color(0xFF1976D2),
            [
              Row(
                children: [
                  Expanded(
                      child: _qtyStat(
                          'Total', o.totalQuantity, const Color(0xFF1976D2))),
                  Expanded(
                      child: _qtyStat('Terkirim', o.shippedQuantity,
                          const Color(0xFF2E7D32))),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: AppSizes.sm),
              if (o.sisaQuantity > 0)
                _infoRow('Sisa (Tidak Terjual)', '${o.sisaQuantity} pcs'),
              if (o.returQuantity > 0)
                _infoRow('Retur (Rusak)', '${o.returQuantity} pcs'),
              _infoRow(
                  'Total Uang',
                  Formatters.currency(
                      o.price * (o.shippedQuantity - o.returQuantity))),
              _infoRow('Harga Satuan', Formatters.currency(o.price)),
              if (o.note != null && o.note!.isNotEmpty)
                _infoRow('Catatan', o.note!),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _card(
            'Pembayaran',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF7B1FA2),
            [
              _infoRow('Status', Formatters.paymentStatus(o.paymentStatus)),
              if (o.paymentMethod != null)
                _infoRow(
                    'Metode', o.paymentMethod == 'CASH' ? 'Cash' : 'Transfer'),
              if (o.paymentProofAt != null)
                _infoRow(
                    'Waktu Bayar',
                    DateFormat('dd MMM yyyy • HH:mm', 'id_ID')
                        .format(o.paymentProofAt!)),
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
                            color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 8),
                      _buildProofImage(o.paymentProof!),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _card(
            'Bukti Pengiriman',
            Icons.photo_camera_rounded,
            const Color(0xFF2E7D32),
            [
              if (o.deliveryProofAt != null)
                _infoRow(
                    'Waktu',
                    DateFormat('dd MMM yyyy • HH:mm', 'id_ID')
                        .format(o.deliveryProofAt!)),
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
                        color: Color(0xFF9CA3AF)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
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
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.restaurant_menu,
                                  size: 18, color: Color(0xFFE65100)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                it.productName ?? '-',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827)),
                              ),
                            ),
                            Text(
                              '${it.quantity} pcs',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE65100)),
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
      String title, IconData icon, Color color, List<Widget> children) {
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
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827)),
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
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827)),
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
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Text(
            '$value',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280)),
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
          child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity),
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

    if (o.status == 'DRAFT') {
      return Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        color: Colors.white,
        child: const Text(
          'Menunggu persetujuan (Approve) dari Admin',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
        ),
      );
    }

    if (o.status == 'DELIVERED') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: _actionButton(
              icon: Icons.camera_alt,
              label: 'Upload Bukti Kirim & Selesaikan',
              color: const Color(0xFFF57C00),
              onTap: _saving ? null : _captureDeliveryProof,
            ),
          ),
        ),
      );
    }

    if (o.status == 'COMPLETED' && !o.isPaid) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: _actionButton(
              icon: Icons.receipt_long,
              label: 'Lihat Invoice',
              color: const Color(0xFF1976D2),
              onTap: _saving ? null : _printInvoice,
              outlined: true,
            ),
          ),
        ),
      );
    }

    if (o.status == 'COMPLETED' && o.isPaid) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: _actionButton(
              icon: Icons.print_rounded,
              label: 'Cetak Invoice',
              color: const Color(0xFF1976D2),
              onTap: _saving ? null : _printInvoice,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.4)),
          minimumSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'DRAFT':
        return const Color(0xFF616161);
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
      case 'DRAFT':
        return Icons.edit_note;
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
