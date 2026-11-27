import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/category_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_style.dart';

class KelolaKategoriScreen extends StatefulWidget {
  const KelolaKategoriScreen({super.key});

  @override
  State<KelolaKategoriScreen> createState() => _KelolaKategoriScreenState();
}

class _KelolaKategoriScreenState extends State<KelolaKategoriScreen> {
  bool isLoading = true;
  String errorMessage = '';
  List<CategoryModel> categories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await ApiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = data;
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

  // Menampilkan dialog untuk tambah / edit kategori
  void bukaDialogKategori(CategoryModel? kategori) {
    showDialog(
      context: context,
      builder: (context) {
        return DialogKategori(
          kategori: kategori,
          setelahSimpan: loadCategories,
        );
      },
    );
  }

  void hapusKategori(CategoryModel kategori) async {
    bool? setuju = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hapus kategori?'),
          content: Text(
            'Kategori "${kategori.name}" akan dihapus.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: AppStyle.merah),
              ),
            ),
          ],
        );
      },
    );

    if (setuju != true) {
      return;
    }

    try {
      await ApiService.deleteCategory(kategori.id);

      if (!mounted) return;

      tampilkanPesan(context, 'Kategori berhasil dihapus');
      loadCategories();
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                bukaDialogKategori(null);
              },
              style: AppStyle.tombolUtama().copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Tambah Kategori',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: buildIsi()),
      ],
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
        child: Text(
          errorMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'Belum ada kategori.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppStyle.abuTeks),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [for (var kategori in categories) buildKartuKategori(kategori)],
    );
  }

  Widget buildKartuKategori(CategoryModel kategori) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.garis),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppStyle.hijauMuda,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.category_outlined,
              color: AppStyle.hijauTua,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kategori.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.hijauTua,
                  ),
                ),
                if (kategori.description != '')
                  Text(
                    kategori.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppStyle.abuTeks,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              bukaDialogKategori(kategori);
            },
            icon: const Icon(
              Icons.edit_outlined,
              color: AppStyle.hijauTua,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () {
              hapusKategori(kategori);
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
}

// Dialog untuk tambah / edit kategori.
// Dibuat sebagai widget sendiri supaya kodenya lebih mudah dibaca.
class DialogKategori extends StatefulWidget {
  final CategoryModel? kategori;
  final VoidCallback setelahSimpan;

  const DialogKategori({super.key, this.kategori, required this.setelahSimpan});

  @override
  State<DialogKategori> createState() => _DialogKategoriState();
}

class _DialogKategoriState extends State<DialogKategori> {
  final namaController = TextEditingController();
  final deskripsiController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.kategori != null) {
      namaController.text = widget.kategori!.name;
      deskripsiController.text = widget.kategori!.description;
    }
  }

  Future<void> simpan() async {
    String nama = namaController.text.trim();

    if (nama == '') {
      tampilkanPesan(context, 'Nama kategori wajib diisi');
      return;
    }

    int idKategori = 0;

    if (widget.kategori != null) {
      idKategori = widget.kategori!.id;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.simpanKategori(
        categoryId: idKategori,
        name: nama,
        description: deskripsiController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);
      tampilkanPesan(context, 'Kategori berhasil disimpan');
      widget.setelahSimpan();
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
    deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.kategori == null ? 'Tambah Kategori' : 'Edit Kategori',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: namaController,
            style: const TextStyle(fontSize: 13),
            decoration: AppStyle.kotakIsian(hint: 'Nama kategori'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: deskripsiController,
            style: const TextStyle(fontSize: 13),
            decoration: AppStyle.kotakIsian(hint: 'Deskripsi (boleh kosong)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : simpan,
          style: AppStyle.tombolUtama().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(90, 42)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
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
