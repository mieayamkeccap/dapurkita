import 'package:flutter/material.dart';

import '../customer/beranda_screen.dart';
import '../customer/keranjang_screen.dart';
import '../customer/pesanan_screen.dart';
import '../customer/profil_screen.dart';
import '../../services/keranjang_store.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';

// Halaman utama customer dengan 4 menu di bawah
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int menuDipilih = 0;

  // Dipakai layar lain supaya bisa pindah tab (misal ke Pesanan setelah checkout)
  void pindahMenu(int index) {
    setState(() {
      menuDipilih = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget isiHalaman = const BerandaScreen();

    if (menuDipilih == 1) {
      isiHalaman = PesananScreen(
        bukaKeranjang: () {
          pindahMenu(2);
        },
      );
    } else if (menuDipilih == 2) {
      isiHalaman = KeranjangScreen(
        bukaPesanan: () {
          pindahMenu(1);
        },
      );
    } else if (menuDipilih == 3) {
      isiHalaman = ProfilScreen(
        bukaPesanan: () {
          pindahMenu(1);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppStyle.latar,
      body: isiHalaman,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppStyle.garis)),
        ),
        // Di layar lebar konten dibatasi 480 dan di tengah, jadi nav ikut
        // dibatasi supaya sejajar dengan isi halaman di atasnya.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: lebarMaksCustomer),
            child: BottomNavigationBar(
              currentIndex: menuDipilih,
              onTap: (index) {
                setState(() {
                  menuDipilih = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppStyle.hijauTua,
              unselectedItemColor: AppStyle.abuTeks,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Beranda',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Pesanan',
                ),
                BottomNavigationBarItem(
                  icon: buildIkonKeranjang(),
                  label: 'Keranjang',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Ikon keranjang dengan angka jumlah barang
  Widget buildIkonKeranjang() {
    int jumlah = KeranjangStore.jumlahBarang();

    if (jumlah == 0) {
      return const Icon(Icons.shopping_cart_outlined);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart_outlined),
        Positioned(
          top: -6,
          right: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppStyle.merah,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$jumlah',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
