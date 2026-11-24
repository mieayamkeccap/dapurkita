
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/alamat_store.dart';
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
  List<Alamat> daftar = [];
  String idUtama = '';

  @override
  void initState() {
    super.initState();
    loadDaftar();
  }

  Future<void> loadDaftar() async {
    final semua = await AlamatStore.ambilSemua();
    final utama = await AlamatStore.ambilUtama();
    if (!mounted) return;
    setState(() {
      daftar = semua;
      idUtama = utama?.id ?? '';
    });
  }

  Future<void> bukaForm([Alamat? alamat]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FormAlamatDialog(alamat: alamat),
    );
    if (result == true && mounted) loadDaftar();
  }

  Future<void> hapus(Alamat alamat) async {
    await AlamatStore.hapus(alamat.id);
    if (!mounted) return;
    tampilkanPesan(context, 'Alamat dihapus');
    loadDaftar();
  }

  Future<void> jadikanUtama(Alamat alamat) async {
    await AlamatStore.setUtama(alamat.id);
    if (!mounted) return;
    tampilkanPesan(context, 'Alamat utama diatur');
    loadDaftar();
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
      body: BatasLebar(child: buildIsi()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => bukaForm(),
        backgroundColor: AppStyle.hijauTua,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget buildIsi() {
    if (daftar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 60, color: AppStyle.abuTeks),
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
                style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
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

  Widget buildKartu(Alamat alamat) {
    final utama = alamat.id == idUtama;
    return GestureDetector(
      onTap: widget.modePilih
          ? () => Navigator.pop(context, alamat)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: utama ? AppStyle.hijauTua : AppStyle.garis,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppStyle.hijauTua, size: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              style: GoogleFonts.poppins(fontSize: 12, height: 1.5, color: AppStyle.abuTeks),
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
                    child: const Text('Jadikan utama', style: TextStyle(fontSize: 12)),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => hapus(alamat),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppStyle.merah, size: 20),
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
  final Alamat? alamat;

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
    if (widget.alamat == null) {
      await AlamatStore.tambah(labelController.text.trim(), alamatController.text.trim());
    } else {
      await AlamatStore.ubah(widget.alamat!.id, labelController.text.trim(), alamatController.text.trim());
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.alamat == null ? 'Tambah alamat' : 'Edit alamat',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppStyle.hijauTua),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              style: const TextStyle(fontSize: 13),
              decoration: AppStyle.kotakIsian(hint: 'Label, mis. Rumah / Kantor', icon: Icons.label_outline_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alamatController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: AppStyle.kotakIsian(hint: 'Alamat lengkap', icon: Icons.location_on_outlined),
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
          child: const Text('Simpan', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
