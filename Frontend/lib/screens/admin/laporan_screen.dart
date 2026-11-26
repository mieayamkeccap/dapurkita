
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../utils/format.dart';
import '../../widgets/app_style.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  bool isLoading = true;
  String errorMessage = '';
  int totalPesanan = 0;
  int totalPendapatan = 0;
  List<Map<String, dynamic>> produkTerlaris = [];
  List<Map<String, dynamic>> penjualanProduk = [];

  @override
  void initState() {
    super.initState();
    loadLaporan();
  }

  Future<void> loadLaporan() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final ringkasan = await ApiService.getDashboardSummary();
      final terlaris = await ApiService.getTopProducts();
      final perProduk = await ApiService.getProductSales();

      if (!mounted) return;

      setState(() {
        totalPesanan = bacaAngkaDesimal(ringkasan['total_orders']);
        totalPendapatan = bacaAngkaDesimal(ringkasan['total_revenue']);
        produkTerlaris = terlaris;
        penjualanProduk = perProduk;
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

  // Data dari server bisa berupa angka atau teks
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppStyle.hijauTua),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        if (errorMessage != '')
          Text(
            errorMessage,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppStyle.merah,
            ),
          ),
        buildKartu('Total Pesanan', '$totalPesanan pesanan', AppStyle.oranye),
        const SizedBox(height: 10),
        buildKartu(
          'Total Pendapatan',
          formatRupiah(totalPendapatan),
          const Color(0xFF2F80ED),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppStyle.garis),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Produk Terlaris',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                ),
              ),
              const SizedBox(height: 8),
              if (produkTerlaris.isEmpty)
                Text(
                  'Belum ada data penjualan.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppStyle.abuTeks,
                  ),
                ),
              for (var produk in produkTerlaris)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          produk['product_name'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppStyle.hijauTua,
                          ),
                        ),
                      ),
                      Text(
                        '${produk['total_sold']} terjual',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppStyle.abuTeks,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        KartuPenjualanProduk(penjualanProduk),
      ],
    );
  }

  Widget buildKartu(String judul, String nilai, Color warna) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.garis),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bar_chart_rounded, color: warna, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              judul,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppStyle.abuTeks,
              ),
            ),
          ),
          Text(
            nilai,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppStyle.hijauTua,
            ),
          ),
        ],
      ),
    );
  }
}

// Tinggi batang 4-100 px. Batang nol tetap 4 px supaya harinya kelihatan
// walaupun tidak ada penjualan.
double tinggiBatang(int jumlah, int maksimal) {
  if (maksimal <= 0) {
    return 4;
  }

  return (jumlah / maksimal * 100).clamp(4, 100).toDouble();
}

// Grafik penjualan per produk, dikelompokkan per kategori.
// Setiap produk punya grafik 7 hari sendiri, termasuk produk yang belum
// pernah terjual (batangnya nol), supaya menu baru langsung terlihat.
// Dibuat top-level supaya bisa dirender sendiri di widget test.
class KartuPenjualanProduk extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const KartuPenjualanProduk(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    // Skala batang dihitung dari seluruh produk, bukan per produk, supaya
    // tinggi batang bisa dibandingkan antar menu.
    int nilaiMaksimal = 0;

    for (var kategori in data) {
      if (kategori['products'] is! List) {
        continue;
      }

      for (var produk in kategori['products']) {
        if (produk['harian'] is! List) {
          continue;
        }

        for (var hari in produk['harian']) {
          int jumlah = bacaAngkaDesimal(hari['jumlah']);

          if (jumlah > nilaiMaksimal) {
            nilaiMaksimal = jumlah;
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Penjualan per Produk',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppStyle.hijauTua,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '7 Hari Terakhir',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppStyle.abuTeks,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Jumlah unit terjual setiap hari, dikelompokkan per kategori.',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppStyle.abuTeks,
            ),
          ),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Belum ada data penjualan.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppStyle.abuTeks,
                ),
              ),
            ),
          for (var kategori in data)
            buildKategori(kategori, nilaiMaksimal),
        ],
      ),
    );
  }

  Widget buildKategori(Map<String, dynamic> kategori, int maksimal) {
    List daftarProduk = kategori['products'] is List
        ? kategori['products']
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppStyle.hijauMuda,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            kategori['category_name'].toString(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppStyle.hijauTua,
            ),
          ),
        ),
        for (var produk in daftarProduk) buildProduk(produk, maksimal),
      ],
    );
  }

  Widget buildProduk(Map<String, dynamic> produk, int maksimal) {
    List harian = produk['harian'] is List ? produk['harian'] : [];
    int total = bacaAngkaDesimal(produk['total']);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  produk['product_name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.hijauTua,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$total terjual',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.abuTeks,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var hari in harian)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${bacaAngkaDesimal(hari['jumlah'])}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppStyle.hijauTua,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 14,
                            height: tinggiBatang(
                              bacaAngkaDesimal(hari['jumlah']),
                              maksimal,
                            ),
                            decoration: BoxDecoration(
                              color: AppStyle.hijau,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            singkatHari(hari['hari'].toString()),
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: AppStyle.abuTeks,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
