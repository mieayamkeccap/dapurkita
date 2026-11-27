import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/keranjang_store.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import '../auth/login_screen.dart';
import 'produk_detail_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  bool isLoading = true;
  String errorMessage = '';
  String userName = '';

  String kataCari = '';
  int kategoriDipilih = 0;

  List<CategoryModel> categories = [];
  List<ProductModel> products = [];

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadData();
  }

  Future<void> loadUserData() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userName = preferences.getString('name') ?? '';
    });
  }

  // Memuat kategori dan produk sekaligus
  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final dataKategori = await ApiService.getCategories();
      final dataProduk = await ApiService.getProducts();

      if (!mounted) return;

      setState(() {
        categories = dataKategori;
        products = dataProduk;
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

  // Menyaring produk sesuai kolom cari dan kategori yang dipilih
  List<ProductModel> produkYangTampil() {
    List<ProductModel> hasil = [];

    for (var product in products) {
      bool cocokCari = true;
      bool cocokKategori = true;

      if (kataCari != '') {
        String nama = product.name.toLowerCase();

        if (!nama.contains(kataCari.toLowerCase())) {
          cocokCari = false;
        }
      }

      if (kategoriDipilih != 0 && product.categoryId != kategoriDipilih) {
        cocokKategori = false;
      }

      if (cocokCari && cocokKategori) {
        hasil.add(product);
      }
    }

    return hasil;
  }

  // Menambah produk ke keranjang langsung dari beranda
  void tambahKeKeranjang(ProductModel product) {
    if (!product.isAvailable) {
      tampilkanPesan(context, 'Produk ini sedang tidak tersedia');
      return;
    }

    setState(() {
      KeranjangStore.tambahItem(product, 1);
    });

    tampilkanPesan(context, '${product.name} masuk keranjang');
  }

  void bukaDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ProdukDetailScreen(product: product);
        },
      ),
    ).then((_) {
      // Supaya badge keranjang ikut diperbarui
      if (mounted) {
        setState(() {});
      }
    });
  }

  void keluar() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('token');
    await preferences.remove('role');
    await preferences.remove('name');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const LoginScreen();
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      body: SafeArea(
        child: BatasLebar(
          maxWidth: lebarKontenAdaptif(context),
          child: RefreshIndicator(
            onRefresh: loadData,
            color: AppStyle.hijauTua,
            child: buildIsi(),
          ),
        ),
      ),
    );
  }

  Widget buildIsi() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppStyle.hijauTua),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        buildHeader(),
        if (errorMessage != '') buildError(),
        buildBanner(),
        buildJudulBagian('Kategori', ''),
        buildDaftarKategori(),
        buildJudulBagian('Menu Favorit', '${products.length} produk'),
        buildDaftarProduk(),
        const SizedBox(height: 20),
      ],
    );
  }

  // Bagian atas hijau tua berisi sapaan dan kolom cari
  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: AppStyle.hijauTua,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName == '' ? 'Halo, Pelanggan!' : 'Halo, $userName!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pesan makanan favoritmu sekarang!',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: keluar,
                tooltip: 'Keluar',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (value) {
              setState(() {
                kataCari = value;
              });
            },
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari makanan...',
              hintStyle: const TextStyle(
                color: Color(0xFFA1AAA3),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppStyle.abuTeks,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppStyle.hijauTua,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diskon 30%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Untuk semua menu!\nYuk, pesan sekarang.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppStyle.oranye,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pesan Sekarang',
                    style: GoogleFonts.poppins(
                      color: AppStyle.hijauTua,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_cafe_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildJudulBagian(String judul, String keterangan) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              judul,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppStyle.hijauTua,
              ),
            ),
          ),
          Text(
            keterangan,
            style: GoogleFonts.poppins(fontSize: 11, color: AppStyle.abuTeks),
          ),
        ],
      ),
    );
  }

  Widget buildDaftarKategori() {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Belum ada kategori.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
        ),
      );
    }

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          buildKartuKategori(0, 'Semua'),
          for (var kategori in categories)
            buildKartuKategori(kategori.id, kategori.name),
        ],
      ),
    );
  }

  Widget buildKartuKategori(int id, String nama) {
    bool dipilih = kategoriDipilih == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          kategoriDipilih = id;
        });
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: dipilih ? AppStyle.hijauTua : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dipilih ? AppStyle.hijauTua : AppStyle.garis,
                ),
              ),
              child: Icon(
                ikonKategori(nama),
                color: dipilih ? Colors.white : AppStyle.hijauTua,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: dipilih ? FontWeight.w700 : FontWeight.w500,
                color: dipilih ? AppStyle.hijauTua : AppStyle.abuTeks,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ikon kategori berdasarkan namanya
  IconData ikonKategori(String nama) {
    String n = nama.toLowerCase();

    if (n.contains('minum') || n.contains('teh') || n.contains('kopi')) {
      return Icons.local_drink_rounded;
    }

    if (n.contains('mie') || n.contains('bakso')) {
      return Icons.ramen_dining_rounded;
    }

    if (n.contains('snack') || n.contains('cemilan')) {
      return Icons.cookie_rounded;
    }

    if (n.contains('nasi') || n.contains('ayam')) {
      return Icons.rice_bowl_rounded;
    }

    return Icons.restaurant_rounded;
  }

  Widget buildDaftarProduk() {
    List<ProductModel> daftar = produkYangTampil();

    if (daftar.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Menu tidak ditemukan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
        ),
      );
    }

    // HP (<700): 1 kolom seperti semula. Tablet/desktop: grid 2-3 kolom
    // supaya konten tidak ramping terjepit di tengah layar lebar.
    return LayoutBuilder(
      builder: (context, constraints) {
        final int kolom = kolomGridProduk(constraints.maxWidth);

        if (kolom == 1) {
          return Column(
            children: [for (var product in daftar) buildKartuProduk(product)],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: kolom,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 104,
            ),
            itemCount: daftar.length,
            itemBuilder: (context, index) =>
                buildKartuProduk(daftar[index], tanpaMarginLuar: true),
          ),
        );
      },
    );
  }

  Widget buildKartuProduk(
    ProductModel product, {
    bool tanpaMarginLuar = false,
  }) {
    return GestureDetector(
      onTap: () {
        bukaDetail(product);
      },
      child: Container(
        margin: tanpaMarginLuar
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
              child: buildGambarProduk(product, 78),
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
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppStyle.abuTeks,
                      ),
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
            GestureDetector(
              onTap: () {
                tambahKeKeranjang(product);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppStyle.hijauTua,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.garis),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AppStyle.abuTeks),
          const SizedBox(height: 10),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: loadData,
            style: AppStyle.tombolUtama().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(140, 42)),
            ),
            child: const Text('Coba lagi', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// Gambar produk dari internet dengan rasio tetap 4:3 supaya tidak gepeng.
// Lebar = ukuran, tinggi dihitung dari rasio. Pakai URL resolusi besar
// (w=1200) supaya tidak pecah di daftar maupun di detail.
// Isi [lebar] kalau mau gambar selebar layar (mis. halaman detail);
// kalau kosong, tetap pakai [ukuran] untuk thumbnail di daftar.
Widget buildGambarProduk(ProductModel product, double ukuran, {double? lebar}) {
  final double lebarPakai = lebar ?? ukuran;
  final double tinggi = lebarPakai * 3 / 4;
  if (product.imageUrl == '') {
    return buildGambarCadangan(lebarPakai, tinggi);
  }
  return SizedBox(
    width: lebarPakai,
    height: tinggi,
    child: Image.network(
      product.imageUrl,
      width: lebarPakai,
      height: tinggi,
      fit: BoxFit.cover,
      // Minta resolusi secukupnya (2x) supaya thumbnail tajam di desktop
      // tanpa mengunduh gambar raksasa.
      cacheWidth: (lebarPakai * 2).toInt(),
      frameBuilder: (context, child, frame, syncCall) {
        if (frame == null) return buildGambarCadangan(lebarPakai, tinggi);
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        return buildGambarCadangan(lebarPakai, tinggi);
      },
    ),
  );
}

Widget buildGambarCadangan(double lebar, [double? tinggi]) {
  final double h = tinggi ?? lebar;
  return Container(
    width: lebar,
    height: h,
    color: AppStyle.hijauMuda,
    child: Icon(
      Icons.restaurant_menu_rounded,
      color: AppStyle.hijauTua,
      size: lebar / 3,
    ),
  );
}
