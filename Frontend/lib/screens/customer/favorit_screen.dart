
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/favorit_store.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import 'beranda_screen.dart';
import 'produk_detail_screen.dart';

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  bool isLoading = true;
  String errorMessage = '';
  List<ProductModel> favorites = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final ids = await FavoritStore.ambilIds();
      final products = await ApiService.getProducts();
      if (!mounted) return;
      setState(() {
        favorites = products.where((p) => ids.contains(p.id)).toList();
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void bukaDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdukDetailScreen(product: product),
      ),
    ).then((_) {
      if (mounted) loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          'Favorit',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
      ),
      body: BatasLebar(child: buildIsi()),
    );
  }

  Widget buildIsi() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppStyle.hijauTua),
      );
    }
    if (errorMessage != '') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage,
                style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadFavorites,
                style: AppStyle.tombolUtama().copyWith(
                  minimumSize: const WidgetStatePropertyAll(Size(140, 42)),
                ),
                child: const Text('Coba lagi', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }
    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border_rounded, size: 60, color: AppStyle.abuTeks),
              const SizedBox(height: 14),
              Text(
                'Belum ada menu favorit',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.hijauTua,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tekan ikon hati di detail produk untuk menyimpan favorit.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: loadFavorites,
      color: AppStyle.hijauTua,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [for (var p in favorites) buildKartu(p)],
      ),
    );
  }

  Widget buildKartu(ProductModel product) {
    return GestureDetector(
      onTap: () => bukaDetail(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyle.garis),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: buildGambarProduk(product, 66),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppStyle.hijauTua,
                    ),
                  ),
                  if (product.categoryName != '')
                    Text(
                      product.categoryName,
                      style: GoogleFonts.poppins(fontSize: 10, color: AppStyle.abuTeks),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupiah(product.price),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppStyle.hijauTua,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.favorite_rounded, color: AppStyle.merah, size: 20),
          ],
        ),
      ),
    );
  }
}
