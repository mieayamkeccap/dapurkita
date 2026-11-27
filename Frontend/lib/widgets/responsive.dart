import 'package:flutter/material.dart';

/// Helper responsif supaya aplikasi yang didesain selebar HP
/// (sekitar 360-420px) tidak melar di Chrome desktop.
///
/// Di layar HP konten tetap penuh seperti semula.
/// Di layar lebar konten berhenti di lebar maksimum dan di tengah,
/// jadi tidak ada area kosong / geser di kanan.

const double lebarMaksCustomer = 480;
const double lebarMaksAdmin = 1100;
const double tinggiMaksFotoDetail = 360;

String kategoriLayar(BuildContext context) {
  final lebar = MediaQuery.of(context).size.width;
  if (lebar < 600) return 'sempit';
  if (lebar < 1024) return 'sedang';
  return 'lebar';
}

bool layarSempit(BuildContext context) =>
    MediaQuery.of(context).size.width < 600;

/// Lebar konten adaptif supaya halaman ber-list tidak terkunci 480 di desktop.
/// HP (<600) tetap 480 seperti sekarang, tablet (<1024) 720, desktop 1100.
double lebarKontenAdaptif(BuildContext context) {
  final lebar = MediaQuery.of(context).size.width;
  if (lebar < 600) return lebarMaksCustomer;
  if (lebar < 1024) return 720;
  return lebarMaksAdmin;
}

/// Jumlah kolom grid produk/menu: HP 1, tablet 2, desktop 3.
/// Dipakai Beranda, Kelola Produk, Favorit, Keranjang.
int kolomGridProduk(double lebar) {
  if (lebar < 700) return 1;
  if (lebar < 1100) return 2;
  return 3;
}

/// True kalau layar cukup lebar untuk dua kolom berdampingan
/// (Checkout form + ringkasan, Detail foto + info).
bool pakaiDuaKolom(double lebar) => lebar >= 900;

/// Membungkus konten supaya berhenti di [maxWidth] dan di tengah
/// saat layar lebih lebar. Tinggi tetap penuh layar supaya
/// ListView / Column+Expanded tetap jalan seperti biasa.
class BatasLebar extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const BatasLebar({
    super.key,
    required this.child,
    this.maxWidth = lebarMaksCustomer,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(
              width: double.infinity,
              height: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : null,
              child: Padding(padding: padding, child: child),
            ),
          ),
        );
      },
    );
  }
}
