import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/product_model.dart';
import '../../models/route_model.dart';
import '../../models/store_model.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/route_service.dart';
import '../../services/store_service.dart';

class CreateOrderSheet extends StatefulWidget {
  final Store? initialStore;

  const CreateOrderSheet({super.key, this.initialStore});

  static Future<bool?> show(BuildContext context, {Store? store}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => CreateOrderSheet(initialStore: store),
    );
  }

  @override
  State<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<CreateOrderSheet> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Store> _stores = [];
  List<AppRoute> _routes = [];
  List<Product> _products = [];

  Store? _selectedStore;
  AppRoute? _selectedRoute;
  DateTime _selectedDate =
      DateTime.now().add(const Duration(days: 1)); // ← besok
  final _note = TextEditingController();
  final Map<String, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _selectedStore = widget.initialStore;
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now, // tidak bisa pilih tanggal lampau
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih Tanggal Order',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

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
        date: _selectedDate, // ← kirim tanggal yang dipilih
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order berhasil dibuat'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      );
    } catch (e) {
      _snack('Gagal: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
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

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dragHandle(),
              _header(),
              Flexible(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _error != null
                        ? _errorView()
                        : _form(),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.sm,
        AppSizes.md,
        AppSizes.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buat Order Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Isi toko, jalur, dan produk',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _load,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        0,
        AppSizes.lg,
        AppSizes.lg,
      ),
      children: [
        // ============ TANGGAL ORDER ============
        _sectionLabel('Tanggal Order'),
        _datePicker(),
        const SizedBox(height: AppSizes.md),

        // ============ TOKO ============
        _sectionLabel('Toko'),
        _storeDropdown(),
        const SizedBox(height: AppSizes.md),

        // ============ JALUR ============
        _sectionLabel('Jalur'),
        _routeDropdown(),
        const SizedBox(height: AppSizes.md),

        // ============ PRODUK ============
        Row(
          children: [
            _sectionLabel('Produk'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$_totalQty pcs',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ..._products.map(_productRow),
        const SizedBox(height: AppSizes.md),

        // ============ CATATAN ============
        _sectionLabel('Catatan (opsional)'),
        TextField(
          controller: _note,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Contoh: titip ke satpam',
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: Color(0xFFFFC107),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF374151),
          ),
        ),
      );

  // ============ DATE PICKER ============
  Widget _datePicker() {
    final isTomorrow = _isSameDay(
      _selectedDate,
      DateTime.now().add(const Duration(days: 1)),
    );
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Color(0xFFF57C00),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                          .format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isTomorrow)
                          _dateBadge('BESOK', const Color(0xFF2E7D32))
                        else if (isToday)
                          _dateBadge('HARI INI', const Color(0xFFF57C00))
                        else
                          _dateBadge(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            const Color(0xFF1976D2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============ STORE DROPDOWN ============
  Widget _storeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<Store>(
        initialValue: _selectedStore,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Pilih Toko',
          hintStyle: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.xs,
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF6B7280),
        ),
        items: _stores
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.name ?? '-',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedStore = v),
      ),
    );
  }

  // ============ ROUTE DROPDOWN ============
  Widget _routeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<AppRoute>(
        initialValue: _selectedRoute,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Pilih Jalur',
          hintStyle: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.xs,
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF6B7280),
        ),
        items: _routes
            .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(
                    r.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedRoute = v),
      ),
    );
  }

  // ============ PRODUCT ROW ============
  Widget _productRow(Product p) {
    final qty = _quantities[p.id] ?? 0;
    final hasQty = qty > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: hasQty ? const Color(0xFFFFC107) : Colors.grey.shade200,
          width: hasQty ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              p.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasQty ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline),
            color: qty <= 0 ? Colors.grey.shade300 : const Color(0xFFD32F2F),
            onPressed: qty <= 0
                ? null
                : () => setState(() => _quantities[p.id] = qty - 1),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color:
                    hasQty ? const Color(0xFFE65100) : const Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF2E7D32),
            onPressed: () => setState(() => _quantities[p.id] = qty + 1),
          ),
        ],
      ),
    );
  }

  // ============ FOOTER ============
  Widget _footer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TOTAL ITEM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_totalQty pcs',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(
                  _submitting ? 'Menyimpan...' : 'Simpan Order',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
