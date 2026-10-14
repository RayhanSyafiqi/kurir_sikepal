import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../../models/store_model.dart';

class StoreSummaryCard extends StatelessWidget {
  final Store store;
  final Order? todayOrder; // ← order hari ini (bisa null)
  final VoidCallback? onTap;

  const StoreSummaryCard({
    super.key,
    required this.store,
    this.todayOrder,
    this.onTap,
  });

  bool get _hasOrderToday => todayOrder != null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============ HEADER ============
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (store.name ?? 'Tanpa Nama').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _deliveryStatusBadge(),
                ],
              ),
              const SizedBox(height: 8),

              // ============ GRADE + KATEGORI ============
              Row(
                children: [
                  if (store.grade != null)
                    _badge(
                      'Grade ${store.grade}',
                      const Color(0xFF1976D2),
                    ),
                  if (store.grade != null && store.category != null)
                    const SizedBox(width: 6),
                  if (store.category != null)
                    _badge(
                      Formatters.category(store.category),
                      const Color(0xFFF57C00),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // ============ PIC ============
              if (store.picName != null && store.picName!.isNotEmpty)
                _infoRow(
                  Icons.person_outline,
                  store.picName!,
                  store.picPhone,
                ),

              // ============ ALAMAT ============
              if (store.address != null && store.address!.isNotEmpty)
                _infoRow(
                  Icons.location_on_outlined,
                  store.address!,
                  store.city,
                ),

              // ============ HARGA PRODUK TOKO INI ============
              _infoRow(
                Icons.local_offer_outlined,
                'Harga: ${Formatters.price(store.price)}/pcs',
                Formatters.paymentMethod(store.paymentMethod),
              ),

              // ============ PRODUK DIKIRIM HARI INI ============
              const SizedBox(height: 4),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 10),

              if (_hasOrderToday) _produkSection() else _emptyProdukSection(),

              // ============ FOOTER ============
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _hasOrderToday
                        ? Icons.local_shipping_rounded
                        : Icons.alt_route_rounded,
                    size: 14,
                    color: const Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hasOrderToday
                        ? 'Lihat Pengiriman Hari Ini'
                        : 'Lihat Detail Toko',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFF57C00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ SECTION PRODUK ============
  Widget _produkSection() {
    final items = todayOrder!.items.where((i) => i.quantity > 0).toList();
    final order = todayOrder!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header produk
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 14,
              color: Color(0xFFF57C00),
            ),
            const SizedBox(width: 6),
            const Text(
              'PRODUK DIKIRIM',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF57C00),
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${order.totalQuantity} pcs',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Chips produk
        if (items.isEmpty)
          const Text(
            'Belum ada produk',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Color(0xFF9CA3AF),
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((item) => _productChip(
                      item.productName ?? '-',
                      item.quantity,
                    ))
                .toList(),
          ),

        // Total uang
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.payments_outlined,
              size: 13,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            Text(
              Formatters.currency(order.totalAmount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyProdukSection() {
    return Row(
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 14,
          color: Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 6),
        Text(
          'Belum ada produk untuk dikirim',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // ============ STATUS BADGE (pojok kanan atas) ============
  Widget _deliveryStatusBadge() {
    // Tidak ada order hari ini
    if (!_hasOrderToday) {
      return _badgePill(
        'BELUM KIRIM',
        const Color(0xFFD32F2F),
        Icons.schedule,
      );
    }

    final status = todayOrder!.status;

    // Sudah selesai
    if (status == 'COMPLETED') {
      return _badgePill(
        'SUDAH KIRIM',
        const Color(0xFF2E7D32),
        Icons.check_circle,
      );
    }

    // Dibatalkan
    if (status == 'CANCELLED') {
      return _badgePill(
        'DIBATALKAN',
        const Color(0xFF616161),
        Icons.cancel,
      );
    }

    // Masih draft
    if (status == 'DRAFT') {
      return _badgePill(
        'DRAFT',
        const Color(0xFF1976D2),
        Icons.edit_note,
      );
    }

    // Default: DELIVERED (perlu dikirim / sudah dikirim hari ini)
    return _badgePill(
      'PERLU DIKIRIM',
      const Color(0xFFF57C00),
      Icons.local_shipping_rounded,
    );
  }

  Widget _badgePill(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============ WIDGETS ============
  Widget _infoRow(IconData icon, String primary, String? secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondary != null && secondary.isNotEmpty)
                  Text(
                    secondary,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _productChip(String name, int qty) {
    final color = _colorForProduct(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$qty',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _shortName(name),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _shortName(String name) {
    final words = name.toUpperCase().split(' ');
    if (words.length >= 2) {
      final second = words[1].length >= 3 ? words[1].substring(0, 3) : words[1];
      return '${words[0]} $second';
    }
    return name.toUpperCase();
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
