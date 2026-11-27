import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/alamat_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';

// Mode pilih dipakai dari Checkout: tap alamat mengembalikan alamat terpilih.
class AlamatScreen extends StatefulWidget {
  final bool modePilih;

  const AlamatScreen({super.key, this.modePilih = false});

  @override
  State<AlamatScreen> createState() => _AlamatScreenState();
}

class _AlamatScreenState extends State<AlamatScreen> {
  List<AlamatModel> daftar = [];
  bool sedangMuat = true;
  String pesanError = '';

  @override
  void initState() {
    super.initState();
    loadDaftar();
  }

  // Alamat dibaca dari database. Alamat utama sudah di urutan pertama.
  Future<void> loadDaftar() async {
    setState(() {
      sedangMuat = true;
      pesanError = '';
    });

    try {
      final hasil = await ApiService.getAddresses();

      if (!mounted) return;

      setState(() {
        daftar = hasil;
        sedangMuat = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        pesanError = error.toString().replaceFirst('Exception: ', '');
        sedangMuat = false;
      });
    }
  }

  Future<void> bukaForm([AlamatModel? alamat]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FormAlamatDialog(alamat: alamat),
    );

    if (result == true && mounted) loadDaftar();
  }

  Future<void> hapus(AlamatModel alamat) async {
    final bool? setuju = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Hapus alamat?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppStyle.hijauTua,
            ),
          ),
          content: Text(
            '"${alamat.label}" akan dihapus permanen.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.6,
              color: AppStyle.abuTeks,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyle.merah,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );

    if (setuju != true || !mounted) return;

    try {
      await ApiService.hapusAlamat(alamat.id);

      if (!mounted) return;

      tampilkanPesan(context, 'Alamat dihapus');
      loadDaftar();
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    }
  }

  Future<void> jadikanUtama(AlamatModel alamat) async {
    try {
      await ApiService.setAlamatUtama(alamat.id);

      if (!mounted) return;

      tampilkanPesan(context, 'Alamat utama diatur');
      loadDaftar();
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          widget.modePilih ? 'Pilih Alamat' : 'Alamat Saya',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
      ),
      body: BatasLebar(
        maxWidth: lebarKontenAdaptif(context),
        child: buildIsi(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => bukaForm(),
        backgroundColor: AppStyle.hijauTua,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget buildIsi() {
    if (sedangMuat) {
      return const Center(
        child: CircularProgressIndicator(color: AppStyle.hijauTua),
      );
    }

    if (pesanError != '') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pesanError,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppStyle.abuTeks,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadDaftar,
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

    if (daftar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 60,
                color: AppStyle.abuTeks,
              ),
              const SizedBox(height: 14),
              Text(
                'Belum ada alamat',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.hijauTua,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tekan tombol + untuk menambah alamat pengiriman.',
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
      onRefresh: loadDaftar,
      color: AppStyle.hijauTua,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [for (var alamat in daftar) buildKartu(alamat)],
      ),
    );
  }

  Widget buildKartu(AlamatModel alamat) {
    final utama = alamat.utama;

    return GestureDetector(
      onTap: widget.modePilih ? () => Navigator.pop(context, alamat) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: utama ? AppStyle.hijauTua : AppStyle.garis),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppStyle.hijauTua,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alamat.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppStyle.hijauTua,
                    ),
                  ),
                ),
                if (utama)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppStyle.hijauMuda,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Utama',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppStyle.hijauTua,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alamat.alamat,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.5,
                color: AppStyle.abuTeks,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => bukaForm(alamat),
                  child: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
                if (!utama)
                  TextButton(
                    onPressed: () => jadikanUtama(alamat),
                    child: const Text(
                      'Jadikan utama',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => hapus(alamat),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppStyle.merah,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FormAlamatDialog extends StatefulWidget {
  final AlamatModel? alamat;

  const FormAlamatDialog({super.key, this.alamat});

  @override
  State<FormAlamatDialog> createState() => _FormAlamatDialogState();
}

class _FormAlamatDialogState extends State<FormAlamatDialog> {
  final labelController = TextEditingController();
  final alamatController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.alamat != null) {
      labelController.text = widget.alamat!.label;
      alamatController.text = widget.alamat!.alamat;
    } else {
      labelController.text = 'Rumah';
    }
  }

  @override
  void dispose() {
    labelController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  Future<void> simpan() async {
    if (labelController.text.trim() == '') {
      tampilkanPesan(context, 'Label wajib diisi');
      return;
    }
    if (alamatController.text.trim() == '') {
      tampilkanPesan(context, 'Alamat wajib diisi');
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService.simpanAlamat(
        addressId: widget.alamat == null ? 0 : widget.alamat!.id,
        label: labelController.text.trim(),
        address: alamatController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.alamat == null ? 'Tambah alamat' : 'Edit alamat',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppStyle.hijauTua,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              style: const TextStyle(fontSize: 13),
              decoration: AppStyle.kotakIsian(
                hint: 'Label, mis. Rumah / Kantor',
                icon: Icons.label_outline_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alamatController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: AppStyle.kotakIsian(
                hint: 'Alamat lengkap',
                icon: Icons.location_on_outlined,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : simpan,
          style: AppStyle.tombolUtama().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(100, 42)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
