
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import '../customer/beranda_screen.dart';

class ProdukFormScreen extends StatefulWidget {
  // Kalau null berarti menambah produk baru
  final ProductModel? product;

  const ProdukFormScreen({super.key, this.product});

  @override
  State<ProdukFormScreen> createState() => _ProdukFormScreenState();
}

class _ProdukFormScreenState extends State<ProdukFormScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isLoading = false;
  bool isLoadingKategori = true;
  bool isAvailable = true;
  int categoryId = 0;
  // XFile dipakai supaya gambar dari galeri bisa dibaca di web, Android,
  // dan desktop sekaligus. Bytes-nya dibaca sekali saat dipilih, lalu
  // dipakai untuk preview dan untuk dikirim ke backend.
  XFile? gambarDipilih;
  Uint8List? bytesGambar;
  List<CategoryModel> categories = [];

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      nameController.text = widget.product!.name;
      priceController.text = widget.product!.price.toString();
      descriptionController.text = widget.product!.description;
      isAvailable = widget.product!.isAvailable;
      categoryId = widget.product!.categoryId;
    }

    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final data = await ApiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = data;

        // Kalau tambah produk baru, pilih kategori pertama
        if (categoryId == 0 && categories.isNotEmpty) {
          categoryId = categories.first.id;
        }

        isLoadingKategori = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingKategori = false;
      });

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    }
  }

  Future<void> pilihGambar() async {
    final picker = ImagePicker();
    final hasil = await picker.pickImage(source: ImageSource.gallery);

    if (hasil == null) {
      return;
    }

    try {
      // Di web, XFile.path bukan path file di disk. Jadi isi fotonya
      // dibaca sebagai bytes supaya bisa dipakai di semua platform.
      final bytes = await hasil.readAsBytes();

      if (!mounted) return;

      if (bytes.isEmpty) {
        tampilkanPesan(context, 'Foto yang dipilih kosong, pilih foto lain');
        return;
      }

      setState(() {
        gambarDipilih = hasil;
        bytesGambar = bytes;
      });
    } catch (error) {
      if (!mounted) return;

      tampilkanPesan(context, 'Gambar tidak bisa dibaca, pilih ulang foto');
    }
  }

  Future<void> simpan() async {
    String name = nameController.text.trim();
    String price = priceController.text.trim();

    if (name == '') {
      tampilkanPesan(context, 'Nama produk wajib diisi');
      return;
    }

    if (price == '') {
      tampilkanPesan(context, 'Harga wajib diisi');
      return;
    }

    int? angkaHarga = int.tryParse(price);

    if (angkaHarga == null || angkaHarga < 0) {
      tampilkanPesan(context, 'Harga harus berupa angka');
      return;
    }

    if (categoryId == 0) {
      tampilkanPesan(context, 'Pilih kategori terlebih dahulu');
      return;
    }

    // Produk baru wajib memakai gambar
    if (widget.product == null && gambarDipilih == null) {
      tampilkanPesan(context, 'Gambar produk wajib dipilih');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      int idProduk = 0;

      if (widget.product != null) {
        idProduk = widget.product!.id;
      }

      await ApiService.simpanProduk(
        productId: idProduk,
        categoryId: categoryId,
        name: name,
        description: descriptionController.text.trim(),
        price: price,
        isAvailable: isAvailable,
        gambarBytes: bytesGambar,
        gambarNama: gambarDipilih?.name,
      );

      if (!mounted) return;

      tampilkanPesan(context, 'Produk berhasil disimpan');
      Navigator.pop(context);
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
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppStyle.hijauTua,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          widget.product == null ? 'Tambah Produk' : 'Edit Produk',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
      ),
      body: BatasLebar(
        maxWidth: lebarMaksAdmin,
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          buildLabel('Gambar Produk'),
          buildPilihanGambar(),
          const SizedBox(height: 16),
          buildLabel('Nama Produk'),
          TextField(
            controller: nameController,
            style: const TextStyle(fontSize: 13),
            decoration: AppStyle.kotakIsian(hint: 'Contoh: Nasi Goreng Spesial'),
          ),
          const SizedBox(height: 16),
          buildLabel('Kategori'),
          buildDropdownKategori(),
          const SizedBox(height: 16),
          buildLabel('Harga'),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            decoration: AppStyle.kotakIsian(hint: 'Contoh: 25000'),
          ),
          const SizedBox(height: 16),
          buildLabel('Deskripsi'),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: AppStyle.kotakIsian(hint: 'Deskripsi produk'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppStyle.garis),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Produk tersedia',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppStyle.hijauTua,
                    ),
                  ),
                ),
                Switch(
                  value: isAvailable,
                  activeThumbColor: AppStyle.hijauTua,
                  onChanged: (value) {
                    setState(() {
                      isAvailable = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : simpan,
              style: AppStyle.tombolUtama(),
              child: isLoading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget buildPilihanGambar() {
    Widget isi;

    if (bytesGambar != null) {
      // Preview dari bytes: jalan di web maupun HP/desktop.
      isi = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytesGambar!,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.product != null) {
      isi = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: buildGambarProduk(widget.product!, 110),
      );
    } else {
      isi = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: AppStyle.abuTeks,
            size: 30,
          ),
          SizedBox(height: 4),
          Text(
            'Pilih gambar',
            style: TextStyle(fontSize: 10, color: AppStyle.abuTeks),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: pilihGambar,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppStyle.garis),
        ),
        child: Center(child: isi),
      ),
    );
  }

  Widget buildDropdownKategori() {
    if (isLoadingKategori) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(color: AppStyle.hijauTua),
      );
    }

    if (categories.isEmpty) {
      return Text(
        'Belum ada kategori. Tambahkan kategori dulu di menu Kategori.',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppStyle.merah,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppStyle.garis),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: categoryId,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppStyle.hijauTua,
          ),
          items: [
            for (var kategori in categories)
              DropdownMenuItem<int>(
                value: kategori.id,
                child: Text(kategori.name),
              ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              categoryId = value;
            });
          },
        ),
      ),
    );
  }
}
