import 'package:flutter/material.dart';
// import '../../core/constants/app_sizes.dart';
import '../../models/store_model.dart';
import '../../widgets/yellow_header.dart';
import 'tabs/today_tab.dart';
import 'tabs/transaksi_tab.dart';
import 'tabs/produk_tab.dart';

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
    _tab = TabController(length: 3, vsync: this);
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
