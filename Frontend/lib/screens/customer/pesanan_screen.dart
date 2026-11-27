import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';

class PesananScreen extends StatefulWidget {
  // Dipanggil kalau pesanan kosong dan ingin belanja
  final VoidCallback bukaKeranjang;

  const PesananScreen({super.key, required this.bukaKeranjang});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  bool isLoading = true;
  String errorMessage = '';
  String filterDipilih = 'semua';
  List<OrderModel> orders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await ApiService.getMyOrders();

      if (!mounted) return;

      setState(() {
        orders = data;
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

  // Menyaring pesanan sesuai tombol filter
  List<OrderModel> pesananYangTampil() {
    List<OrderModel> hasil = [];

    for (var order in orders) {
      String status = order.orderStatus;

      if (filterDipilih == 'semua') {
        hasil.add(order);
      } else if (filterDipilih == 'diproses') {
        if (status == 'pending' ||
            status == 'confirmed' ||
            status == 'preparing' ||
            status == 'ready' ||
            status == 'on_delivery') {
          hasil.add(order);
        }
      } else if (filterDipilih == 'selesai') {
        if (status == 'completed') {
          hasil.add(order);
        }
      } else if (filterDipilih == 'dibatalkan') {
        if (status == 'cancelled') {
          hasil.add(order);
        }
      }
    }

    return hasil;
  }

  // Membuka detail pesanan untuk mengambil daftar itemnya.
  // Kalau customer menandai pesanan selesai di sana, daftar dimuat ulang.
  Future<void> bukaDetail(OrderModel order) async {
    final selesai = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return DetailPesananScreen(order: order);
        },
      ),
    );

    if (selesai == true && mounted) {
      loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          'Pesanan Saya',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
      ),
      body: BatasLebar(
        child: Column(
          children: [
            buildFilter(),
            Expanded(child: buildIsi()),
          ],
        ),
      ),
    );
  }

  Widget buildFilter() {
    List<Map<String, String>> daftar = [
      {'kunci': 'semua', 'teks': 'Semua'},
      {'kunci': 'diproses', 'teks': 'Diproses'},
      {'kunci': 'selesai', 'teks': 'Selesai'},
      {'kunci': 'dibatalkan', 'teks': 'Dibatalkan'},
    ];

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (var item in daftar)
            GestureDetector(
              onTap: () {
                setState(() {
                  filterDipilih = item['kunci'].toString();
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8, top: 6, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filterDipilih == item['kunci']
                      ? AppStyle.hijauTua
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: filterDipilih == item['kunci']
                        ? AppStyle.hijauTua
                        : AppStyle.garis,
                  ),
                ),
                child: Text(
                  item['teks'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: filterDipilih == item['kunci']
                        ? Colors.white
                        : AppStyle.hijauTua,
                  ),
                ),
              ),
            ),
        ],
      ),
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
                onPressed: loadOrders,
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

    List<OrderModel> daftar = pesananYangTampil();

    if (daftar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 60,
                color: AppStyle.abuTeks,
              ),
              const SizedBox(height: 14),
              Text(
                'Belum ada pesanan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.hijauTua,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pesanan yang kamu buat akan muncul di sini.',
                textAlign: TextAlign.center,
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

    return RefreshIndicator(
      onRefresh: loadOrders,
      color: AppStyle.hijauTua,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [for (var order in daftar) buildKartuPesanan(order)],
      ),
    );
  }

  Widget buildKartuPesanan(OrderModel order) {
    Color warna = warnaStatusPesanan(order.orderStatus);

    return GestureDetector(
      onTap: () {
        bukaDetail(order);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
                    '#${order.orderCode}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppStyle.hijauTua,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: warna.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    teksStatusPesanan(order.orderStatus),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: warna,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatTanggal(order.createdAt),
              style: GoogleFonts.poppins(fontSize: 10, color: AppStyle.abuTeks),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppStyle.garis),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppStyle.abuTeks,
                  ),
                ),
                const Spacer(),
                Text(
                  formatRupiah(order.totalAmount),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppStyle.hijauTua,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppStyle.abuTeks,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Mengubah tanggal dari server (2026-11-20T15:00:00.000Z) menjadi 20 Nov 2026
String formatTanggal(String tanggal) {
  if (tanggal.length < 10) {
    return tanggal;
  }

  String tahun = tanggal.substring(0, 4);
  String bulan = tanggal.substring(5, 7);
  String hari = tanggal.substring(8, 10);

  List<String> namaBulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  int nomorBulan = int.parse(bulan);

  if (nomorBulan < 1 || nomorBulan > 12) {
    return tanggal;
  }

  return '$hari ${namaBulan[nomorBulan - 1]} $tahun';
}

// Halaman detail satu pesanan beserta daftar itemnya
class DetailPesananScreen extends StatefulWidget {
  final OrderModel order;

  const DetailPesananScreen({super.key, required this.order});

  @override
  State<DetailPesananScreen> createState() => _DetailPesananScreenState();
}

class _DetailPesananScreenState extends State<DetailPesananScreen> {
  bool isLoading = true;
  String errorMessage = '';
  OrderModel? detail;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  // Dipakai tombol Pesanan Diterima supaya tidak bisa ditekan dua kali
  bool sedangProses = false;

  // Customer mengonfirmasi pesanannya sudah diterima
  Future<void> tandaiDiterima() async {
    OrderModel pesanan = detail ?? widget.order;

    bool yakin = await konfirmasiPesananDiterima(context, pesanan);

    if (!yakin || !mounted) return;

    setState(() {
      sedangProses = true;
    });

    try {
      await ApiService.selesaikanPesanan(pesanan.id);

      if (!mounted) return;

      // Kembali ke daftar; hasil true membuat daftar dimuat ulang
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    } finally {
      if (mounted) {
        setState(() {
          sedangProses = false;
        });
      }
    }
  }

  Future<void> loadDetail() async {
    try {
      final data = await ApiService.getOrderDetail(widget.order.id);

      if (!mounted) return;

      setState(() {
        detail = data;
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

  @override
  Widget build(BuildContext context) {
    OrderModel pesanan = detail ?? widget.order;

    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          'Detail Pesanan',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppStyle.hijauTua),
            )
          : BatasLebar(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (errorMessage != '')
                    Text(
                      errorMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppStyle.merah,
                      ),
                    ),
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
                          '#${pesanan.orderCode}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppStyle.hijauTua,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatTanggal(pesanan.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppStyle.abuTeks,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Status: ${teksStatusPesanan(pesanan.orderStatus)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: warnaStatusPesanan(pesanan.orderStatus),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppStyle.garis),
                        const SizedBox(height: 10),
                        if (pesanan.items.isEmpty)
                          Text(
                            'Daftar item tidak tersedia.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppStyle.abuTeks,
                            ),
                          ),
                        for (var item in pesanan.items)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} x${item.quantity}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppStyle.hijauTua,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatRupiah(item.subtotal),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppStyle.hijauTua,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppStyle.garis),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppStyle.abuTeks,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatRupiah(pesanan.totalAmount),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppStyle.hijauTua,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pembayaran: ${teksMetodeBayar(pesanan.paymentMethod)}'
                          ' · ${teksStatusBayar(pesanan.paymentStatus)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppStyle.abuTeks,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bolehCustomerSelesaikan(pesanan.orderStatus)) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: sedangProses ? null : tandaiDiterima,
                        style: AppStyle.tombolUtama(),
                        child: sedangProses
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Pesanan Diterima',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// Status pembayaran yang enak dibaca
String teksStatusBayar(String status) {
  if (status == 'paid') return 'Lunas';
  if (status == 'awaiting_verification') return 'Menunggu verifikasi';
  if (status == 'rejected') return 'Ditolak';
  return 'Belum lunas';
}

// Nama metode pembayaran yang enak dibaca
String teksMetodeBayar(String metode) {
  if (metode == 'transfer') return 'Transfer Bank';
  return metode;
}

// Customer boleh menandai selesai sejak pesanan dikonfirmasi admin.
// Pesanan yang masih pending, sudah selesai, atau dibatalkan tidak bisa.
bool bolehCustomerSelesaikan(String status) {
  return status == 'confirmed' ||
      status == 'preparing' ||
      status == 'ready' ||
      status == 'on_delivery';
}

// Konfirmasi sebelum customer menandai pesanannya sudah diterima.
// Status completed final, jadi salah tekan tidak bisa dibatalkan.
Future<bool> konfirmasiPesananDiterima(
  BuildContext context,
  OrderModel order,
) async {
  bool? hasil = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          'Pesanan Sudah Diterima?',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Pesanan #${order.orderCode} akan ditandai selesai. '
          'Status ini final dan tidak bisa diubah lagi.',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: AppStyle.tombolUtama().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
            ),
            child: Text(
              'Ya, Sudah Diterima',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return hasil == true;
}
