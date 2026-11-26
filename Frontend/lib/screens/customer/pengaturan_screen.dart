
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/pengaturan_store.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  final namaController = TextEditingController();
  final teleponController = TextEditingController();

  bool notifikasi = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Nama dan telepon dibaca dari database. Salinan di perangkat ikut
  // diperbarui supaya header dan checkout tetap terisi saat jaringan lambat.
  Future<void> loadData() async {
    final preferences = await SharedPreferences.getInstance();
    final notif = await PengaturanStore.ambilNotifikasi();

    String nama = preferences.getString('name') ?? '';
    String telepon = preferences.getString('phone') ?? '';

    try {
      final profil = await ApiService.getProfil();

      nama = profil['name'] == null ? '' : profil['name'].toString();
      telepon = profil['phone'] == null ? '' : profil['phone'].toString();

      await preferences.setString('name', nama);
      await preferences.setString('phone', telepon);
    } catch (error) {
      // Server tidak bisa dihubungi: tetap tampilkan salinan terakhir
      // supaya form tidak kosong. Gagal menyimpan tetap dilaporkan.
    }

    if (!mounted) return;

    setState(() {
      namaController.text = nama;
      teleponController.text = telepon;
      notifikasi = notif;
    });
  }

  Future<void> simpanProfil() async {
    if (namaController.text.trim() == '') {
      tampilkanPesan(context, 'Nama wajib diisi');
      return;
    }

    setState(() => isLoading = true);

    try {
      final profil = await ApiService.updateProfil(
        namaController.text.trim(),
        teleponController.text.trim(),
      );

      final preferences = await SharedPreferences.getInstance();
      final namaBaru = profil['name'] == null
          ? namaController.text.trim()
          : profil['name'].toString();
      final teleponBaru = profil['phone'] == null
          ? ''
          : profil['phone'].toString();

      await preferences.setString('name', namaBaru);
      await preferences.setString('phone', teleponBaru);

      if (!mounted) return;

      namaController.text = namaBaru;
      teleponController.text = teleponBaru;

      tampilkanPesan(context, 'Profil tersimpan');
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    teleponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          'Pengaturan',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
      ),
      body: BatasLebar(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          buildKartu(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildJudul('Profil Saya'),
                const SizedBox(height: 10),
                TextField(
                  controller: namaController,
                  style: const TextStyle(fontSize: 13),
                  decoration: AppStyle.kotakIsian(hint: 'Nama', icon: Icons.person_outline_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: teleponController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 13),
                  decoration: AppStyle.kotakIsian(hint: 'Nomor telepon', icon: Icons.phone_outlined),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : simpanProfil,
                    style: AppStyle.tombolUtama().copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 46)),
                    ),
                    child: const Text('Simpan Profil', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          buildKartu(
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Notifikasi Pesanan',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppStyle.hijauTua),
                ),
                subtitle: Text(
                  'Terima info status pesanan (disimpan lokal)',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppStyle.abuTeks),
                ),
                value: notifikasi,
                onChanged: (value) async {
                  setState(() => notifikasi = value);
                  await PengaturanStore.simpanNotifikasi(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          buildKartu(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildJudul('Tentang'),
                const SizedBox(height: 8),
                Text(
                  'DapurKita v1.0.0',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppStyle.hijauTua),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nikmatnya Kuliner, Dalam Genggaman',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget buildJudul(String judul) {
    return Text(
      judul,
      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppStyle.hijauTua),
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
}
