import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import '../customer/beranda_screen.dart';
import 'produk_form_screen.dart';

class KelolaProdukScreen extends StatefulWidget {
  const KelolaProdukScreen({super.key});

  @override
  State<KelolaProdukScreen> createState() => _KelolaProdukScreenState();
}

class _KelolaProdukScreenState extends State<KelolaProdukScreen> {
  bool isLoading = true;
  String errorMessage = '';
  String kataCari = '';
  List<ProductModel> products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await ApiService.getProducts();

      if (!mounted) return;

      setState(() {
        products = data;
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

  List<ProductModel> produkYangTampil() {
    List<ProductModel> hasil = [];

    for (var product in products) {
      if (kataCari == '' ||
          product.name.toLowerCase().contains(kataCari.toLowerCase())) {
        hasil.add(product);
      }
    }

    return hasil;
  }

  // Buka form tambah produk (product == null berarti tambah baru)
  void bukaForm(ProductModel? product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ProdukFormScreen(product: product);
        },
      ),
    ).then((_) {
      loadProducts();
    });
  }

  void hapusProduk(ProductModel product) async {
    bool? setuju = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hapus produk?'),
          content: Text(
            'Produk "${product.name}" akan dihapus.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: AppStyle.merah),
              ),
            ),
          ],
        );
      },
    );

    if (setuju != true) {
      return;
    }

    try {
      await ApiService.deleteProduct(product.id);

      if (!mounted) return;

      tampilkanPesan(context, 'Produk berhasil dihapus');
      loadProducts();
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          // Di layar sangat sempit (< 380) kolom cari terjepit tombol:
          // tombol tampil ikon + saja supaya kolom cari tetap lega.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool ringkas = constraints.maxWidth < 380;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          kataCari = value;
                        });
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: AppStyle.kotakIsian(
                        hint: 'Cari produk...',
                        icon: Icons.search_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ringkas
                        ? ElevatedButton(
                            onPressed: () {
                              bukaForm(null);
                            },
                            style: AppStyle.tombolUtama().copyWith(
                              minimumSize: const WidgetStatePropertyAll(
                                Size(52, 52),
                              ),
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.zero,
                              ),
                            ),
                            child: const Icon(Icons.add_rounded, size: 20),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              bukaForm(null);
                            },
                            style: AppStyle.tombolUtama().copyWith(
                              minimumSize: const WidgetStatePropertyAll(
                                Size(0, 52),
                              ),
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Tambah Produk',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(child: buildIsi()),
      ],
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
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppStyle.abuTeks,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadProducts,
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

    List<ProductModel> daftar = produkYangTampil();

    if (daftar.isEmpty) {
      return Center(
        child: Text(
          'Belum ada produk.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
        ),
      );
    }

    // HP (<700): 1 kolom seperti semula. Tablet/desktop: grid 2-3 kolom.
    return LayoutBuilder(
      builder: (context, constraints) {
        final int kolom = kolomGridProduk(constraints.maxWidth);

        if (kolom == 1) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [for (var product in daftar) buildKartuProduk(product)],
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kolom,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 96,
          ),
          itemCount: daftar.length,
          itemBuilder: (context, index) =>
              buildKartuProduk(daftar[index], tanpaMarginLuar: true),
        );
      },
    );
  }

  Widget buildKartuProduk(
    ProductModel product, {
    bool tanpaMarginLuar = false,
  }) {
    return Container(
      margin: tanpaMarginLuar
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: 10),
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
            child: buildGambarProduk(product, 60),
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
                Text(
                  formatRupiah(product.price),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppStyle.abuTeks,
                  ),
                ),
                if (!product.isAvailable)
                  Text(
                    'Tidak tersedia',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppStyle.merah,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              bukaForm(product);
            },
            tooltip: 'Edit',
            icon: const Icon(
              Icons.edit_outlined,
              color: AppStyle.hijauTua,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () {
              hapusProduk(product);
            },
            tooltip: 'Hapus',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppStyle.merah,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
