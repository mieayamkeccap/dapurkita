import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/alamat_model.dart';
import '../../services/api_service.dart';
import '../../services/keranjang_store.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import 'alamat_screen.dart';
import 'beranda_screen.dart';

class CheckoutScreen extends StatefulWidget {
  // Dipanggil setelah pesanan berhasil dibuat
  final VoidCallback setelahPesan;

  const CheckoutScreen({super.key, required this.setelahPesan});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final namaController = TextEditingController();
  final teleponController = TextEditingController();
  final catatanController = TextEditingController();

  bool isLoading = false;
  String metodeAmbil = 'delivery';
  AlamatModel? alamatDipilih;

  // Ongkir untuk pengantaran (sesuai referensi: 25.000 + 5.000 = 30.000)
  static const int ongkir = 5000;

  @override
  void initState() {
    super.initState();
    isiDataAwal();
  }

  // Isi nama, telepon, dan alamat utama dari yang tersimpan.
  // Nama/telepon memakai salinan sesi supaya form langsung terisi;
  // alamat diambil dari database (alamat utama ada di urutan pertama).
  Future<void> isiDataAwal() async {
    final preferences = await SharedPreferences.getInstance();

    String nama = preferences.getString('name') ?? '';
    String telepon = preferences.getString('phone') ?? '';
    AlamatModel? alamat;

    try {
      final daftar = await ApiService.getAddresses();

      if (daftar.isNotEmpty) {
        alamat = daftar.first;
      }
    } catch (error) {
      // Alamat gagal dimuat: biarkan kosong, pengguna bisa memilih manual
      // lewat halaman Pilih Alamat.
    }

    if (!mounted) return;

    setState(() {
      namaController.text = nama;
      teleponController.text = telepon;
      alamatDipilih = alamat;
    });
  }

  Future<void> pilihAlamat() async {
    final hasil = await Navigator.push<AlamatModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AlamatScreen(modePilih: true),
      ),
    );
    if (hasil != null && mounted) {
      setState(() {
        alamatDipilih = hasil;
      });
    }
  }

  void pilihMetodeAmbil(String metode) {
    setState(() {
      metodeAmbil = metode;
    });
  }

  int hitungOngkir() {
    return metodeAmbil == 'delivery' ? ongkir : 0;
  }

  int totalPembayaran() {
    return KeranjangStore.totalBelanja() + hitungOngkir();
  }

  // Mengirim pesanan ke backend
  Future<void> pesanSekarang() async {
    if (KeranjangStore.items.isEmpty) {
      tampilkanPesan(context, 'Keranjang masih kosong');
      return;
    }

    if (namaController.text.trim() == '') {
      tampilkanPesan(context, 'Nama penerima wajib diisi');
      return;
    }

    if (teleponController.text.trim() == '') {
      tampilkanPesan(context, 'Nomor telepon wajib diisi');
      return;
    }

    if (metodeAmbil == 'delivery' && alamatDipilih == null) {
      tampilkanPesan(context, 'Alamat pengiriman wajib diisi');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String alamatKirim = '';
      if (metodeAmbil == 'delivery' && alamatDipilih != null) {
        alamatKirim = '${alamatDipilih!.label}: ${alamatDipilih!.alamat}';
      }

      final result = await ApiService.saveOrder(
        KeranjangStore.dataUntukPesanan(),
        metodeAmbil,
        namaController.text.trim(),
        teleponController.text.trim(),
        alamatKirim,
        catatanController.text.trim(),
      );

      if (!mounted) return;

      KeranjangStore.kosongkan();

      tampilkanPesan(context, result['message'].toString());

      // Kembali ke halaman utama, lalu buka tab Pesanan
      Navigator.pop(context);
      widget.setelahPesan();
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    teleponController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          'Checkout',
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  buildKartuAlamat(),
                  const SizedBox(height: 14),
                  buildKartuMetodeAmbil(),
                  const SizedBox(height: 14),
                  buildKartuPembayaran(),
                  const SizedBox(height: 14),
                  buildKartuPenerima(),
                  const SizedBox(height: 14),
                  buildKartuRingkasan(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            buildTombolBawah(),
          ],
        ),
      ),
    );
  }

  Widget buildJudulKartu(String judul) {
    return Text(
      judul,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppStyle.hijauTua,
      ),
    );
  }

  Widget buildKartu(Widget isi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.garis),
      ),
      child: isi,
    );
  }

  // Alamat seperti referensi: ikon pin + teks alamat + panah kanan
  Widget buildKartuAlamat() {
    final adaAlamat = alamatDipilih != null;

    return buildKartu(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildJudulKartu('Alamat Pengiriman'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: pilihAlamat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppStyle.hijauMuda.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppStyle.garis),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppStyle.hijauTua,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      adaAlamat
                          ? '${alamatDipilih!.alamat} (${alamatDipilih!.label})'
                          : 'Pilih alamat pengiriman',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.5,
                        color: adaAlamat ? AppStyle.hijauTua : AppStyle.abuTeks,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppStyle.abuTeks,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildKartuMetodeAmbil() {
    return buildKartu(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildJudulKartu('Cara Mengambil'),
          const SizedBox(height: 6),
          buildPilihan(
            Icons.directions_bike_rounded,
            'Diantar ke alamat',
            metodeAmbil == 'delivery',
            () => pilihMetodeAmbil('delivery'),
          ),
          buildPilihan(
            Icons.storefront_rounded,
            'Ambil sendiri di DapurKita',
            metodeAmbil == 'pickup',
            () => pilihMetodeAmbil('pickup'),
          ),
        ],
      ),
    );
  }

  Widget buildKartuPembayaran() {
    return buildKartu(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildJudulKartu('Metode Pembayaran'),
          const SizedBox(height: 6),
          buildPilihan(
            Icons.account_balance_rounded,
            'Transfer Bank',
            true,
            () {},
          ),
          const SizedBox(height: 8),
          Text(
            'Pembayaran dicatat lunas saat pesanan dibuat.',
            style: GoogleFonts.poppins(fontSize: 11, color: AppStyle.abuTeks),
          ),
        ],
      ),
    );
  }

  Widget buildKartuPenerima() {
    return buildKartu(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildJudulKartu('Data Penerima'),
          const SizedBox(height: 10),
          TextField(
            controller: namaController,
            style: const TextStyle(fontSize: 13),
            decoration: AppStyle.kotakIsian(
              hint: 'Nama penerima',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: teleponController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 13),
            decoration: AppStyle.kotakIsian(
              hint: 'Nomor telepon',
              icon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: catatanController,
            style: const TextStyle(fontSize: 13),
            decoration: AppStyle.kotakIsian(
              hint: 'Catatan (boleh kosong)',
              icon: Icons.edit_note_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPilihan(
    IconData ikon,
    String teks,
    bool dipilih,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: dipilih ? AppStyle.hijauMuda : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dipilih ? AppStyle.hijauTua : AppStyle.garis,
          ),
        ),
        child: Row(
          children: [
            Icon(ikon, color: AppStyle.hijauTua, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                teks,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: dipilih ? FontWeight.w600 : FontWeight.w500,
                  color: AppStyle.hijauTua,
                ),
              ),
            ),
            Icon(
              dipilih
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: dipilih ? AppStyle.hijauTua : AppStyle.abuTeks,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Ringkasan seperti referensi: thumbnail, nama, x jumlah, harga
  Widget buildKartuRingkasan() {
    List<Widget> daftarItem = [];

    for (var item in KeranjangStore.items) {
      daftarItem.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: buildGambarProduk(item.product, 48),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppStyle.hijauTua,
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppStyle.abuTeks,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatRupiah(item.subtotal()),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.hijauTua,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return buildKartu(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildJudulKartu('Ringkasan Pesanan'),
          ...daftarItem,
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppStyle.garis),
          const SizedBox(height: 12),
          buildBarisHarga(
            'Subtotal',
            formatRupiah(KeranjangStore.totalBelanja()),
          ),
          if (hitungOngkir() > 0) ...[
            const SizedBox(height: 8),
            buildBarisHarga('Ongkir', formatRupiah(hitungOngkir())),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppStyle.garis),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Text(
                'Total Pembayaran',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                ),
              ),
              const Spacer(),
              // Total mengecil sendiri kalau nominalnya panjang di HP 320.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatRupiah(totalPembayaran()),
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppStyle.hijauTua,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBarisHarga(String label, String nilai) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
        ),
        const Spacer(),
        Text(
          nilai,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppStyle.hijauTua,
          ),
        ),
      ],
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
        child: ElevatedButton(
          onPressed: isLoading ? null : pesanSekarang,
          style: AppStyle.tombolUtama(),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Pesan Sekarang · ${formatRupiah(totalPembayaran())}',
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
