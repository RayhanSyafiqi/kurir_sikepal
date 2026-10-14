import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/route_model.dart';
import '../../models/store_model.dart';
import '../../models/product_model.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/route_service.dart'; // buat kalau belum
import '../../services/store_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class CreateOrderScreen extends StatefulWidget {
  final Store? initialStore;
  const CreateOrderScreen({super.key, this.initialStore});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Store> _stores = [];
  List<AppRoute> _routes = [];
  List<Product> _products = [];

  Store? _selectedStore;
  AppRoute? _selectedRoute;
  final _note = TextEditingController();
  final Map<String, int> _quantities = {}; // productId -> qty

  @override
  void initState() {
    super.initState();
    _selectedStore = widget.initialStore;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        StoreService.getAll(),
        RouteService.getAll(),
        ProductService.getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _stores = results[0] as List<Store>;
        _routes = results[1] as List<AppRoute>;
        _products = results[2] as List<Product>;
        _quantities.clear();
        for (final p in _products) {
          _quantities[p.id] = 0;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalQty => _quantities.values.fold(0, (sum, q) => sum + q);

  Future<void> _submit() async {
    if (_selectedStore == null) {
      _snack('Pilih toko dulu');
      return;
    }
    if (_selectedRoute == null) {
      _snack('Pilih jalur dulu');
      return;
    }
    final items = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) => {'productId': e.key, 'quantity': e.value})
        .toList();
    if (items.isEmpty) {
      _snack('Isi minimal 1 produk dengan qty > 0');
      return;
    }

    setState(() => _submitting = true);
    try {
      await OrderService.create(
        storeId: _selectedStore!.id,
        routeId: _selectedRoute!.id,
        items: items,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil dibuat')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Order Baru')),
      body: _loading
          ? const LoadingState()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _buildForm(),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: AppButton(
                  label: 'Simpan Order ($_totalQty item)',
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ),
            ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.lg),
      children: [
        // Toko
        _label('Toko'),
        DropdownButtonFormField<Store>(
          initialValue: _selectedStore,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Pilih Toko'),
          items: _stores
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name ?? '-', overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedStore = v),
        ),
        const SizedBox(height: AppSizes.lg),

        // Jalur
        _label('Jalur'),
        DropdownButtonFormField<AppRoute>(
          initialValue: _selectedRoute,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Pilih Jalur'),
          items: _routes
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedRoute = v),
        ),
        const SizedBox(height: AppSizes.lg),

        // Produk
        _label('Produk'),
        ..._products.map(_buildProductRow),
        const SizedBox(height: AppSizes.lg),

        // Catatan
        _label('Catatan (opsional)'),
        AppTextField(
          controller: _note,
          label: 'Catatan',
          hint: 'Contoh: titip ke satpam',
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.sm),
        child: Text(text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
      );

  Widget _buildProductRow(Product p) {
    final qty = _quantities[p.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(child: Text(p.name)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: qty <= 0
                ? null
                : () => setState(() => _quantities[p.id] = qty - 1),
          ),
          SizedBox(
            width: 32,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => setState(() => _quantities[p.id] = qty + 1),
          ),
        ],
      ),
    );
  }
}
