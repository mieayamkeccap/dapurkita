import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../utils/format.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import '../auth/login_screen.dart';
import 'kelola_kategori_screen.dart';
import 'kelola_pesanan_screen.dart';
import 'kelola_produk_screen.dart';
import 'laporan_screen.dart';
import 'pengaturan_screen.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  int menuDipilih = 0;
  String namaAdmin = '';

  bool isLoading = true;
  String errorMessage = '';
  int totalProduk = 0;
  int totalPesanan = 0;
  int totalPelanggan = 0;
  List<Map<String, dynamic>> pesananTerbaru = [];
  List<Map<String, dynamic>> dataHarian = [];

  @override
  void initState() {
    super.initState();
    loadNamaAdmin();
    loadRingkasan();
  }

  Future<void> loadNamaAdmin() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      namaAdmin = preferences.getString('name') ?? 'Admin';
    });
  }

  // Memuat angka statistik dan pesanan terbaru
  Future<void> loadRingkasan() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final ringkasan = await ApiService.getDashboardSummary();
      final produk = await ApiService.getProducts();
      final semuaPesanan = await ApiService.getAllOrders();
      final harian = await ApiService.getDailyOrders();

      if (!mounted) return;

      // Hitung jumlah pelanggan dari daftar pesanan (tanpa dobel)
      List<String> daftarPelanggan = [];

      for (var pesanan in semuaPesanan) {
        String nama = pesanan.customerName;

        if (nama != '' && !daftarPelanggan.contains(nama)) {
          daftarPelanggan.add(nama);
        }
      }

      List<Map<String, dynamic>> terbaru = [];

      for (var i = 0; i < semuaPesanan.length && i < 5; i++) {
        terbaru.add({
          'kode': semuaPesanan[i].orderCode,
          'nama': semuaPesanan[i].customerName,
          'status': semuaPesanan[i].orderStatus,
          'total': semuaPesanan[i].totalAmount,
        });
      }

      setState(() {
        totalProduk = produk.length;
        totalPesanan = ringkasan['total_orders'] == null
            ? semuaPesanan.length
            : int.parse(ringkasan['total_orders'].toString());
        totalPelanggan = daftarPelanggan.length;
        pesananTerbaru = terbaru;
        dataHarian = harian;
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

  void pilihMenu(int index) {
    setState(() {
      menuDipilih = index;
    });
  }

  void keluar() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('token');
    await preferences.remove('role');
    await preferences.remove('name');
    await preferences.remove('email');

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
    // Di layar sempit (HP), sidebar diganti tombol menu
    bool layarSempit = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppStyle.latar,
      drawer: layarSempit ? Drawer(child: buildSidebar()) : null,
      body: Row(
        children: [
          if (!layarSempit) buildSidebar(),
          Expanded(
            child: BatasLebar(
              maxWidth: lebarMaksAdmin,
              child: Column(
                children: [
                  buildTopBar(layarSempit),
                  Expanded(child: buildIsiMenu()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Menu kiri hijau tua
  Widget buildSidebar() {
    return Container(
      width: 230,
      color: AppStyle.hijauTua,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppStyle.hijauTua,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'DapurKita',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            buildItemSidebar(0, Icons.dashboard_rounded, 'Dashboard'),
            buildItemSidebar(1, Icons.inventory_2_outlined, 'Produk'),
            buildItemSidebar(2, Icons.category_outlined, 'Kategori'),
            buildItemSidebar(3, Icons.receipt_long_outlined, 'Pesanan'),
            buildItemSidebar(4, Icons.bar_chart_rounded, 'Laporan'),
            buildItemSidebar(5, Icons.settings_outlined, 'Pengaturan'),
            const Spacer(),
            buildItemSidebar(6, Icons.logout_rounded, 'Logout'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget buildItemSidebar(int index, IconData ikon, String teks) {
    bool dipilih = menuDipilih == index;

    return GestureDetector(
      onTap: () {
        if (index == 6) {
          keluar();
          return;
        }

        pilihMenu(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: dipilih ? Colors.white.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              ikon,
              color: dipilih
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
              size: 19,
            ),
            const SizedBox(width: 10),
            Text(
              teks,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: dipilih ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bar atas berisi judul halaman dan nama admin
  Widget buildTopBar(bool layarSempit) {
    List<String> judulMenu = [
      'Dashboard',
      'Produk',
      'Kategori',
      'Pesanan',
      'Laporan',
      'Pengaturan',
    ];

    String judul = 'Dashboard';

    if (menuDipilih < judulMenu.length) {
      judul = judulMenu[menuDipilih];
    }

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
        color: AppStyle.latar,
        child: Row(
          children: [
            if (layarSempit)
              Builder(
                builder: (context) {
                  return IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: AppStyle.hijauTua,
                    ),
                  );
                },
              ),
            Expanded(
              child: Text(
                judul,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  // Judul 20 kepotong di HP 320 bareng nama admin,
                  // jadi mengecil mengikuti lebar layar.
                  fontSize: layarSempit ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Icon(
              Icons.account_circle_rounded,
              color: AppStyle.hijauTua,
              size: 28,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                namaAdmin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.hijauTua,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIsiMenu() {
    if (menuDipilih == 1) {
      return const KelolaProdukScreen();
    }

    if (menuDipilih == 2) {
      return const KelolaKategoriScreen();
    }

    if (menuDipilih == 3) {
      return const KelolaPesananScreen();
    }

    if (menuDipilih == 4) {
      return const LaporanScreen();
    }

    if (menuDipilih == 5) {
      return const PengaturanScreen();
    }

    return buildIsiDashboard();
  }

  Widget buildIsiDashboard() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppStyle.hijauTua),
      );
    }

    return RefreshIndicator(
      onRefresh: loadRingkasan,
      color: AppStyle.hijauTua,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          if (errorMessage != '')
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppStyle.garis),
              ),
              child: Text(
                errorMessage,
                style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.merah),
              ),
            ),
          buildBarisKartu(),
          const SizedBox(height: 16),
          buildGrafik(),
          const SizedBox(height: 16),
          buildPesananTerbaru(),
        ],
      ),
    );
  }

  Widget buildBarisKartu() {
    // Di HP sempit (lebar < 420) tiap kartu cuma ~90px: pakai gaya ringkas
    // supaya judul tidak kepotong dan angka tetap muat.
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool ringkas = constraints.maxWidth < 420;
        return Row(
          children: [
            Expanded(
              child: buildKartuStatistik(
                Icons.inventory_2_outlined,
                'Total Produk',
                '$totalProduk',
                AppStyle.oranye,
                ringkas: ringkas,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: buildKartuStatistik(
                Icons.shopping_bag_outlined,
                'Total Pesanan',
                '$totalPesanan',
                const Color(0xFF2F80ED),
                ringkas: ringkas,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: buildKartuStatistik(
                Icons.people_alt_outlined,
                'Pelanggan',
                '$totalPelanggan',
                AppStyle.hijau,
                ringkas: ringkas,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildKartuStatistik(
    IconData ikon,
    String judul,
    String angka,
    Color warna, {
    bool ringkas = false,
  }) {
    return Container(
      padding: EdgeInsets.all(ringkas ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ringkas ? 30 : 34,
            height: ringkas ? 30 : 34,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, color: warna, size: ringkas ? 16 : 18),
          ),
          const SizedBox(height: 10),
          Text(
            judul,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: ringkas ? 9 : 10,
              color: AppStyle.abuTeks,
            ),
          ),
          Text(
            angka,
            style: GoogleFonts.poppins(
              fontSize: ringkas ? 17 : 20,
              fontWeight: FontWeight.w700,
              color: AppStyle.hijauTua,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGrafik() {
    // Cari jumlah tertinggi supaya tinggi batang proporsional
    int nilaiMaksimal = 0;

    for (var item in dataHarian) {
      int jumlah = int.tryParse(item['jumlah'].toString()) ?? 0;

      if (jumlah > nilaiMaksimal) {
        nilaiMaksimal = jumlah;
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
                  'Grafik Penjualan',
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
          const SizedBox(height: 16),
          if (dataHarian.isEmpty)
            Text(
              'Belum ada data grafik.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var item in dataHarian)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${int.tryParse(item['jumlah'].toString()) ?? 0}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppStyle.hijauTua,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 18,
                              height: nilaiMaksimal == 0
                                  ? 4
                                  : ((int.tryParse(item['jumlah'].toString()) ??
                                                0) /
                                            nilaiMaksimal *
                                            100)
                                        .clamp(4, 100)
                                        .toDouble(),
                              decoration: BoxDecoration(
                                color: AppStyle.hijau,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(5),
                                  topRight: Radius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              singkatHari(item['hari'].toString()),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
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

  Widget buildPesananTerbaru() {
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
          Text(
            'Pesanan Terbaru',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppStyle.hijauTua,
            ),
          ),
          const SizedBox(height: 8),
          if (pesananTerbaru.isEmpty)
            Text(
              'Belum ada pesanan.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
            ),
          for (var pesanan in pesananTerbaru)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppStyle.hijauMuda,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppStyle.hijauTua,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${pesanan['kode']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppStyle.hijauTua,
                          ),
                        ),
                        Text(
                          pesanan['nama'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppStyle.abuTeks,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: warnaStatusPesanan(
                        pesanan['status'].toString(),
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      teksStatusPesanan(pesanan['status'].toString()),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: warnaStatusPesanan(pesanan['status'].toString()),
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
