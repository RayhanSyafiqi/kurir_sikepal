import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../services/retur_service.dart';
import '../../widgets/yellow_header.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

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
      final list = await ReturService.getList();
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processRetur(Order order) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Proses Retur'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Total qty: ${order.totalQuantity}'),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah retur'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Angka tidak valid';
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
              backgroundColor: const Color(0xFFFF7043),
            ),
            child: const Text('Proses'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ReturService.process(
        orderId: order.id,
        qty: int.parse(ctrl.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retur berhasil diproses')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          YellowHeader(
            title: 'Retur',
            subtitle: '${_orders.length} order bisa diretur',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton.tonal(
              onPressed: _load,
              child: const Text('Coba lagi'),
            ),
          ),
        ],
      );
    }
    if (_orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(
            Icons.assignment_return_outlined,
            size: 72,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Belum ada order yang bisa diretur',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.lg),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
      itemBuilder: (_, i) => _returCard(_orders[i]),
    );
  }

  Widget _returCard(Order o) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (o.store?.name ?? '-').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'DIKIRIM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.red.shade700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.date(o.date),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              _stat('Total', '${o.totalQuantity}'),
              const SizedBox(width: AppSizes.lg),
              _stat('Terkirim', '${o.shippedQuantity}'),
              const SizedBox(width: AppSizes.lg),
              _stat('Sisa', '${o.remaining}'),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _processRetur(o),
                icon: const Icon(Icons.assignment_return, size: 16),
                label: const Text('Retur'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF3E0),
                  foregroundColor: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
