
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product_model.dart';
import '../../services/favorit_store.dart';
import '../../services/keranjang_store.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import 'beranda_screen.dart';
import 'keranjang_screen.dart';

class ProdukDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProdukDetailScreen({super.key, required this.product});

  @override
  State<ProdukDetailScreen> createState() => _ProdukDetailScreenState();
}

class _ProdukDetailScreenState extends State<ProdukDetailScreen> {
  int jumlah = 1;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    loadFavorite();
  }

  Future<void> loadFavorite() async {
    final favorit = await FavoritStore.adalah(widget.product.id);
    if (!mounted) return;
    setState(() => isFavorite = favorit);
  }

  Future<void> toggleFavorite() async {
    final baru = await FavoritStore.toggle(widget.product.id);
    if (!mounted) return;
    setState(() => isFavorite = baru);
    tampilkanPesan(
      context,
      baru ? 'Ditambah ke favorit' : 'Dihapus dari favorit',
    );
  }

  void kurangiJumlah() {
    if (jumlah > 1) {
      setState(() {
        jumlah = jumlah - 1;
      });
    }
  }

  void tambahJumlah() {
    setState(() {
      jumlah = jumlah + 1;
    });
  }

  void tambahKeKeranjang() {
    if (!widget.product.isAvailable) {
      tampilkanPesan(context, 'Produk ini sedang tidak tersedia');
      return;
    }

    KeranjangStore.tambahItem(widget.product, jumlah);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return KeranjangScreen(
            bukaPesanan: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      body: SafeArea(
        bottom: false,
        child: BatasLebar(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  buildGambarAtas(),
                  buildInfoProduk(),
                  buildDetailProduk(),
                  buildPilihanJumlah(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            buildTombolBawah(),
          ],
        ),
        ),
      ),
    );
  }

  Widget buildGambarAtas() {
    // Lebar dibatasi maks customer (480) dan tinggi maks 360 supaya di
    // Chrome desktop 1920px foto tidak jadi 1440px tingginya.
    final double lebarLayar =
        MediaQuery.of(context).size.width.clamp(0, lebarMaksCustomer).toDouble();
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: buildGambarProduk(
            widget.product,
            lebarLayar,
            lebar: lebarLayar,
          ),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: buildTombolBulat(
            Icons.arrow_back_rounded,
            () {
              Navigator.pop(context);
            },
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: buildTombolBulat(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            toggleFavorite,
            ikonWarna: isFavorite ? AppStyle.merah : AppStyle.hijauTua,
          ),
        ),
      ],
    );
  }

  Widget buildTombolBulat(IconData ikon, VoidCallback onTap, {Color ikonWarna = AppStyle.hijauTua}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(ikon, color: ikonWarna, size: 20),
      ),
    );
  }

  // Kartu ini naik menimpa gambar. Container tidak menerima margin negatif,
  // jadi posisinya digeser dengan Transform.translate.
  Widget buildInfoProduk() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: buildKartuInfo(),
    );
  }

  Widget buildKartuInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppStyle.hijauTua,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                formatRupiah(widget.product.price),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.star_rounded,
                color: AppStyle.oranye,
                size: 16,
              ),
              const SizedBox(width: 2),
              Text(
                '4.8 (1.2k ulasan)',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppStyle.abuTeks,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.product.description == ''
                ? 'Menu favorit dari DapurKita.'
                : widget.product.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.6,
              color: AppStyle.abuTeks,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDetailProduk() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyle.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Produk',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppStyle.hijauTua,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              buildInfoKecil(Icons.people_alt_outlined, 'Porsi', '1 Orang'),
              buildInfoKecil(Icons.access_time_rounded, 'Waktu', '± 15 Menit'),
              buildInfoKecil(
                Icons.inventory_2_outlined,
                'Tersedia',
                widget.product.isAvailable ? 'Tersedia' : 'Habis',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfoKecil(IconData ikon, String judul, String isi) {
    return Expanded(
      child: Column(
        children: [
          Icon(ikon, color: AppStyle.hijauTua, size: 20),
          const SizedBox(height: 6),
          Text(
            judul,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppStyle.abuTeks,
            ),
          ),
          Text(
            isi,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppStyle.hijauTua,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPilihanJumlah() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyle.garis),
      ),
      child: Row(
        children: [
          Text(
            'Jumlah',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppStyle.hijauTua,
            ),
          ),
          const Spacer(),
          buildTombolJumlah(Icons.remove_rounded, kurangiJumlah),
          SizedBox(
            width: 40,
            child: Text(
              '$jumlah',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppStyle.hijauTua,
              ),
            ),
          ),
          buildTombolJumlah(Icons.add_rounded, tambahJumlah),
        ],
      ),
    );
  }

  Widget buildTombolJumlah(IconData ikon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppStyle.hijauMuda,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(ikon, color: AppStyle.hijauTua, size: 18),
      ),
    );
  }

  Widget buildTombolBawah() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppStyle.garis)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: tambahKeKeranjang,
          style: AppStyle.tombolUtama(),
          icon: const Icon(Icons.shopping_cart_outlined, size: 18),
          label: Text(
            'Tambah ke Keranjang · ${formatRupiah(widget.product.price * jumlah)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
