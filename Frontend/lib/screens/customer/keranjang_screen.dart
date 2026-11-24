
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/keranjang_store.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import 'beranda_screen.dart';
import 'checkout_screen.dart';

class KeranjangScreen extends StatefulWidget {
  // Dipakai untuk pindah ke tab Pesanan setelah checkout
  final VoidCallback bukaPesanan;

  const KeranjangScreen({super.key, required this.bukaPesanan});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  void tambah(int productId) {
    for (var item in KeranjangStore.items) {
      if (item.product.id == productId) {
        setState(() {
          item.quantity = item.quantity + 1;
        });
        return;
      }
    }
  }

  void kurangi(int productId) {
    setState(() {
      KeranjangStore.kurangiItem(productId);
    });
  }

  void hapus(int productId) {
    setState(() {
      KeranjangStore.hapusItem(productId);
    });
  }

  void kosongkan() {
    setState(() {
      KeranjangStore.kosongkan();
    });
  }

  void bukaCheckout() {
    if (KeranjangStore.items.isEmpty) {
      tampilkanPesan(context, 'Keranjang masih kosong');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CheckoutScreen(
            setelahPesan: () {
              widget.bukaPesanan();
            },
          );
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          'Keranjang',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
        actions: [
          if (KeranjangStore.items.isNotEmpty)
            IconButton(
              onPressed: kosongkan,
              tooltip: 'Kosongkan',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppStyle.hijauTua,
              ),
            ),
        ],
      ),
      body: BatasLebar(
        child: KeranjangStore.items.isEmpty ? buildKosong() : buildIsi(),
      ),
    );
  }

  Widget buildKosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: AppStyle.abuTeks,
            ),
            const SizedBox(height: 14),
            Text(
              'Keranjang masih kosong',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppStyle.hijauTua,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Yuk pilih menu favoritmu di Beranda.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppStyle.abuTeks,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIsi() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (var item in KeranjangStore.items)
                buildKartuItem(
                  item.product.id,
                  item.product.name,
                  item.product.price,
                  item.quantity,
                ),
            ],
          ),
        ),
        buildRingkasan(),
      ],
    );
  }

  Widget buildKartuItem(
    int productId,
    String nama,
    int harga,
    int jumlah,
  ) {
    // Cari produknya untuk ditampilkan gambarnya
    var item = KeranjangStore.items.firstWhere(
      (item) => item.product.id == productId,
    );

    return Container(
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
            child: buildGambarProduk(item.product, 66),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.hijauTua,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(harga),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppStyle.abuTeks,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    buildTombolJumlah(
                      Icons.remove_rounded,
                      () {
                        kurangi(productId);
                      },
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$jumlah',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppStyle.hijauTua,
                        ),
                      ),
                    ),
                    buildTombolJumlah(
                      Icons.add_rounded,
                      () {
                        tambah(productId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              hapus(productId);
            },
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

  Widget buildTombolJumlah(IconData ikon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppStyle.hijauMuda,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(ikon, color: AppStyle.hijauTua, size: 16),
      ),
    );
  }

  Widget buildRingkasan() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppStyle.garis)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Total Belanja',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppStyle.abuTeks,
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(KeranjangStore.totalBelanja()),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: bukaCheckout,
              style: AppStyle.tombolUtama(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Checkout',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
