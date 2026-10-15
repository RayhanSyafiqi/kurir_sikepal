import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/product_model.dart';
import '../../services/extra_order_service.dart';
import '../../services/product_service.dart';

class ExtraOrderSheet extends StatefulWidget {
  /// Nama-nama toko yang sedang order hari ini (untuk saran)
  final List<String> todayStoreNames;

  const ExtraOrderSheet({super.key, this.todayStoreNames = const []});

  static Future<bool?> show(
    BuildContext context, {
    List<String> todayStoreNames = const [],
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => ExtraOrderSheet(todayStoreNames: todayStoreNames),
    );
  }

  @override
  State<ExtraOrderSheet> createState() => _ExtraOrderSheetState();
}

class _ExtraOrderSheetState extends State<ExtraOrderSheet> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Product> _products = [];

  // Form
  final _storeName = TextEditingController();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final Map<String, int> _quantities = {}; // productId -> qty
  final Map<String, double> _prices = {}; // productId -> harga

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _storeName.dispose();
    _customerName.dispose();
    _customerPhone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await ProductService.getAll(limit: 200);
      if (!mounted) return;
      setState(() {
        _products = products;
        _quantities.clear();
        _prices.clear();
        for (final p in products) {
          _quantities[p.id] = 0;
          _prices[p.id] = 0;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalQty => _quantities.values.fold(0, (s, q) => s + q);

  double get _totalAmount {
    double total = 0;
    for (final entry in _quantities.entries) {
      final qty = entry.value;
      if (qty > 0) {
        total += qty * (_prices[entry.key] ?? 0);
      }
    }
    return total;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_storeName.text.trim().isEmpty) {
      _snack('Nama toko wajib diisi');
      return;
    }

    final items = _quantities.entries.where((e) => e.value > 0).map((e) {
      final product = _products.firstWhere((p) => p.id == e.key);
      return {
        'productId': product.id,
        'productName': product.name,
        'quantity': e.value,
        'price': _prices[e.key] ?? 0,
      };
    }).toList();

    if (items.isEmpty) {
      _snack('Isi minimal 1 produk dengan qty > 0');
      return;
    }

    setState(() => _submitting = true);
    try {
      // Nama toko disatukan dengan customerName
      final combinedName = _storeName.text.trim();

      await ExtraOrderService.create(
        customerName: combinedName,
        customerPhone: _customerPhone.text.trim().isEmpty
            ? null
            : _customerPhone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        date: _selectedDate,
        items: items,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Extra order berhasil dibuat'),
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
                colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
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
                  'Extra Order',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Order di luar rute reguler',
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
        // Tanggal
        _label('Tanggal'),
        _datePicker(),
        const SizedBox(height: AppSizes.md),

        // Nama Toko (TEXT INPUT + suggestion)
        _label('Nama Toko *'),
        _storeNameField(),
        const SizedBox(height: AppSizes.md),

        // Customer
        _label('Nama Customer (opsional)'),
        _textField(_customerName, 'Nama customer'),
        const SizedBox(height: AppSizes.md),

        _label('No. HP (opsional)'),
        _textField(
          _customerPhone,
          '08123456789',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: AppSizes.md),

        _label('Alamat (opsional)'),
        _textField(_address, 'Alamat pengiriman'),
        const SizedBox(height: AppSizes.md),

        // Produk
        Row(
          children: [
            _label('Produk'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$_totalQty pcs',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ..._products.map(_productRow),
        const SizedBox(height: AppSizes.md),

        _label('Catatan (opsional)'),
        _textField(_note, 'Catatan tambahan', maxLines: 2),
      ],
    );
  }

  Widget _label(String text) => Padding(
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

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
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
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
      ),
    );
  }

  Widget _datePicker() {
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
                color: Color(0xFF7B1FA2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
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

  /// Field nama toko dengan suggestion dari toko yang order hari ini
  Widget _storeNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _storeName,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ketik nama toko...',
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.store_rounded,
              color: Color(0xFF9C27B0),
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
              borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
            ),
          ),
        ),
        // Suggestion dari toko yang sudah order hari ini
        if (widget.todayStoreNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Toko yang order hari ini:',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.todayStoreNames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final name = widget.todayStoreNames[i];
                return ActionChip(
                  label: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                  backgroundColor: const Color(0xFFF3E5F5),
                  side: BorderSide(color: const Color(0xFFCE93D8)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () {
                    _storeName.text = name;
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _productRow(Product p) {
    final qty = _quantities[p.id] ?? 0;
    final priceCtrl = _prices[p.id] ?? 0;
    final hasQty = qty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: hasQty ? const Color(0xFF9C27B0) : Colors.grey.shade200,
          width: hasQty ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
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
                color:
                    qty <= 0 ? Colors.grey.shade300 : const Color(0xFFD32F2F),
                onPressed: qty <= 0
                    ? null
                    : () => setState(() => _quantities[p.id] = qty - 1),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: hasQty
                        ? const Color(0xFF7B1FA2)
                        : const Color(0xFF111827),
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
          // Harga per pcs (muncul kalau qty > 0)
          if (hasQty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  const Text(
                    'Harga/pcs:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: priceCtrl.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onChanged: (v) {
                        final n = double.tryParse(v) ?? 0;
                        setState(() => _prices[p.id] = n);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '= Rp ${(qty * priceCtrl).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

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
                    Text(
                      '$_totalQty pcs',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Rp ${_totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7B1FA2),
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
                  _submitting ? 'Menyimpan...' : 'Simpan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
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
