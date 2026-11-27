import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/order_item_model.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_style.dart';
import '../customer/pesanan_screen.dart';

class KelolaPesananScreen extends StatefulWidget {
  const KelolaPesananScreen({super.key});

  @override
  State<KelolaPesananScreen> createState() => _KelolaPesananScreenState();
}

class _KelolaPesananScreenState extends State<KelolaPesananScreen> {
  bool isLoading = true;
  String errorMessage = '';
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
      final data = await ApiService.getAllOrders();

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

  // Status berikutnya yang boleh dipilih, sesuai aturan di backend
  Future<void> ubahStatus(OrderModel order) async {
    List<String> pilihan = statusBerikutnyaPesanan(order);

    if (pilihan.isEmpty) {
      tampilkanPesan(context, 'Status pesanan ini sudah final');
      return;
    }

    String? status = await pilihStatusPesanan(context, order, pilihan);

    if (status == null || !mounted) return;

    // Status selesai harus dikonfirmasi dulu
    if (status == 'completed') {
      bool yakin = await konfirmasiPesananSelesai(context, order);

      if (!yakin || !mounted) return;
    }

    await simpanStatus(order.id, status);
  }

  Future<void> simpanStatus(int orderId, String status) async {
    try {
      await ApiService.updateOrderStatus(orderId, status);

      if (!mounted) return;

      tampilkanPesan(context, 'Status berhasil diubah');
      loadOrders();
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    }
  }

  // Admin memverifikasi pembayaran transfer
  void verifikasiPembayaran(OrderModel order, String status) async {
    try {
      await ApiService.verifyPayment(order.id, status);

      if (!mounted) return;

      tampilkanPesan(
        context,
        status == 'paid' ? 'Pembayaran lunas' : 'Pembayaran ditolak',
      );
      loadOrders();
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    if (orders.isEmpty) {
      return Center(
        child: Text(
          'Belum ada pesanan.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadOrders,
      color: AppStyle.hijauTua,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [for (var order in orders) buildKartuPesanan(order)],
      ),
    );
  }

  Widget buildKartuPesanan(OrderModel order) {
    Color warna = warnaStatusPesanan(order.orderStatus);
    bool perluVerifikasi =
        order.paymentMethod == 'transfer' &&
        order.paymentStatus == 'awaiting_verification';

    return Container(
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
            '${order.customerName} · ${formatTanggal(order.createdAt)}',
            style: GoogleFonts.poppins(fontSize: 10, color: AppStyle.abuTeks),
          ),
          const SizedBox(height: 8),
          // Isi pesanan ditampilkan di kartu supaya admin tahu apa yang
          // harus disiapkan saat memutuskan status berikutnya.
          DaftarItemPesanan(order.items),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                order.deliveryMethod == 'delivery'
                    ? Icons.delivery_dining_rounded
                    : Icons.storefront_rounded,
                color: AppStyle.abuTeks,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                order.deliveryMethod == 'delivery'
                    ? 'Diantar'
                    : 'Ambil di tempat',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppStyle.abuTeks,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatRupiah(order.totalAmount),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                ),
              ),
              const Spacer(),
              Text(
                teksMetodeBayar(order.paymentMethod),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppStyle.abuTeks,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ubahStatus(order);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppStyle.hijauTua,
                    side: const BorderSide(color: AppStyle.hijauTua),
                    minimumSize: const Size(0, 40),
                  ),
                  // FittedBox: dua tombol berdampingan di HP 320 sempit,
                  // label mengecil sendiri daripada meluber.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Ubah Status',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (perluVerifikasi) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      verifikasiPembayaran(order, 'paid');
                    },
                    style: AppStyle.tombolUtama().copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
                    ),
                    // FittedBox: alasan sama seperti tombol di sebelahnya.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Verifikasi Bayar',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Dialog pilihan status. Mengembalikan status yang dipilih, atau null kalau dibatalkan.
Future<String?> pilihStatusPesanan(
  BuildContext context,
  OrderModel order,
  List<String> pilihan,
) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          'Ubah status #${order.orderCode}',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var status in pilihan)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  teksStatusPesanan(status),
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(dialogContext, status);
                },
              ),
          ],
        ),
      );
    },
  );
}

// Status berikutnya yang boleh dipilih, sesuai aturan di backend.
// Dibuat top-level supaya bisa diuji tanpa membuka layar.
List<String> statusBerikutnyaPesanan(OrderModel order) {
  String status = order.orderStatus;

  if (status == 'pending') return ['confirmed', 'cancelled'];
  if (status == 'confirmed') return ['preparing', 'cancelled'];
  if (status == 'preparing') return ['ready'];
  if (status == 'ready') {
    // Pickup langsung selesai; delivery harus lewat status pengantaran dulu
    if (order.deliveryMethod == 'delivery') return ['on_delivery'];
    return ['completed'];
  }
  if (status == 'on_delivery') return ['completed'];
  return [];
}

// Konfirmasi sebelum menandai pesanan selesai.
// Status completed final, jadi salah tekan tidak bisa dibatalkan.
Future<bool> konfirmasiPesananSelesai(
  BuildContext context,
  OrderModel order,
) async {
  bool? hasil = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          'Pesanan Sudah Selesai?',
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
              'Ya, Selesaikan',
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

// Isi pesanan: nama produk, jumlahnya, dan subtotal per baris.
class DaftarItemPesanan extends StatelessWidget {
  final List<OrderItemModel> items;

  const DaftarItemPesanan(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Daftar item tidak tersedia.',
        style: GoogleFonts.poppins(fontSize: 10, color: AppStyle.abuTeks),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyle.hijauMuda,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} x${item.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppStyle.hijauTua,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatRupiah(item.subtotal),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppStyle.hijauTua,
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
