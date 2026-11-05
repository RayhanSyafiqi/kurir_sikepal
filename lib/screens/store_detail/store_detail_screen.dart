import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../widgets/yellow_header.dart';
import 'tabs/today_tab.dart';
import 'tabs/transaksi_tab.dart';
import 'tabs/produk_tab.dart';
import 'tabs/retur_tab.dart'; // ✅ Import ReturTab

class StoreDetailScreen extends StatefulWidget {
  final Store store;
  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    // ✅ Ubah length menjadi 4 karena ada tab baru
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
          // TabBar kuning
          Container(
            color: const Color(0xFFFFB300),
            child: TabBar(
              controller: _tab,
              // ✅ Gunakan isScrollable jika layar HP terlalu sempit untuk 4 tab
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
                Tab(text: 'RETUR'), // ✅ Tab Baru
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                TodayTab(storeId: widget.store.id),
                TransaksiTab(storeId: widget.store.id),
                ProdukTab(storeId: widget.store.id),
                ReturTab(storeId: widget.store.id), // ✅ Panggil ReturTab
              ],
            ),
          ),
        ],
      ),
    );
  }
}
