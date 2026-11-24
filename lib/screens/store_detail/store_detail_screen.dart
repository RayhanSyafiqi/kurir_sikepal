import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../widgets/yellow_header.dart';
import 'tabs/today_tab.dart';
import 'tabs/transaksi_tab.dart';
import 'tabs/produk_tab.dart';
import 'tabs/retur_tab.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;
  final String mode; // ✅ 'DELIVERY' atau 'TRANSACTION'

  const StoreDetailScreen({
    super.key,
    required this.store,
    this.mode = 'DELIVERY', // Default
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
    // Hanya butuh 2 tab
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDelivery = widget.mode == 'DELIVERY';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          YellowHeader(
            title: widget.store.name ?? 'Detail Toko',
            subtitle: widget.store.city ?? widget.store.address ?? '',
          ),
          Container(
            color: const Color(0xFFFFB300),
            child: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
              tabs: isDelivery
                  ? const [
                      Tab(text: 'HARI INI'),
                      Tab(text: 'PRODUK'),
                    ]
                  : const [
                      Tab(text: 'TRANSAKSI'),
                      Tab(text: 'RETUR'),
                    ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: isDelivery
                  ? [
                      TodayTab(storeId: widget.store.id),
                      ProdukTab(storeId: widget.store.id),
                    ]
                  : [
                      TransaksiTab(storeId: widget.store.id),
                      ReturTab(storeId: widget.store.id),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
