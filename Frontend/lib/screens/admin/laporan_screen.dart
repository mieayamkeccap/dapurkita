
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
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

      if (!mounted) return;

      setState(() {
        totalPesanan = ambilAngka(ringkasan['total_orders']);
        totalPendapatan = ambilAngka(ringkasan['total_revenue']);
        produkTerlaris = terlaris;
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
  int ambilAngka(dynamic nilai) {
    if (nilai == null) {
      return 0;
    }

    try {
      // Bisa berupa angka biasa (29000) atau teks desimal dari MySQL
      // DECIMAL ("29000.00"), jadi dibaca sebagai double dulu.
      return double.parse(nilai.toString()).toInt();
    } catch (error) {
      return 0;
    }
  }

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
