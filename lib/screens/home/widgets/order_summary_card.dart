import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';

class OrderSummaryCard extends StatelessWidget {
  final Order order;
  final List<Product> products;
  final String courierName;
  final VoidCallback? onTap;

  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.products,
    required this.courierName,
    this.onTap,
  });

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
              // ============ HEADER: DATE + STATUS ============
              Row(
                children: [
                  Text(
                    _formatDate(order.date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  _statusBadge(order.status),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // ============ STORE NAME ============
              Text(
                (order.store?.name ?? '-').toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                courierName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF57C00),
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                'Sikepal Delivery',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // ============ PRODUCT CHIPS ============
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...products.map((p) {
                      final qty = _qtyForProduct(p.id);
                      return _productChip(p.name, qty);
                    }),
                    _totalChip(order.totalQuantity),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _qtyForProduct(String productId) {
    for (final item in order.items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  // ============ CHIP WIDGETS ============
  Widget _productChip(String name, int qty) {
    final color = _colorForProduct(name);
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            _shortName(name),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$qty',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalChip(int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF57F17),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$qty',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF57F17),
            ),
          ),
        ],
      ),
    );
  }

  // ============ STATUS BADGE ============
  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'DELIVERED':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1976D2);
        label = 'DIKIRIM';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'SELESAI';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        label = 'BATAL';
        break;
      case 'REJECTED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        label = 'REJECTED';
        break;
      case 'DRAFT':
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF616161);
        label = 'DRAFT';
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF616161);
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============ HELPERS ============
  String _formatDate(DateTime d) {
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
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
