import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../widgets/yellow_header.dart';
import 'tabs/today_tab.dart';
import 'tabs/transaksi_tab.dart';
import 'tabs/produk_tab.dart';
import 'tabs/retur_tab.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;
  final bool isWarning; // ✅ Tambahan parameter
  const StoreDetailScreen({
    super.key,
    required this.store,
    this.isWarning = false,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          YellowHeader(
            title: widget.store.name ?? 'Detail Toko',
            subtitle: widget.store.city ?? widget.store.address ?? '',
          ),

          // ✅ Banner peringatan jika warning
          // if (widget.isWarning)
          //   Container(
          //     width: double.infinity,
          //     color: Colors.red.shade50,
          //     padding: const EdgeInsets.all(12),
          //     child: const Row(
          //       children: [
          //         Icon(Icons.warning_amber_rounded, color: Colors.red),
          //         SizedBox(width: 8),
          //         Expanded(
          //           child: Text(
          //             'Toko ini memiliki tagihan yang melewati tenggat. Harap lunasi sebelum membuat order baru.',
          //             style: TextStyle(
          //                 color: Colors.red,
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 12),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),

          Container(
            color: const Color(0xFFFFB300),
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
              tabs: const [
                Tab(text: 'HARI INI'),
                Tab(text: 'TRANSAKSI'),
                Tab(text: 'PRODUK'),
                Tab(text: 'RETUR'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // ✅ Teruskan isWarning ke TodayTab (tempat biasanya ada tombol Buat Order)
                TodayTab(storeId: widget.store.id, isWarning: widget.isWarning),
                TransaksiTab(storeId: widget.store.id),
                ProdukTab(storeId: widget.store.id),
                ReturTab(storeId: widget.store.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
