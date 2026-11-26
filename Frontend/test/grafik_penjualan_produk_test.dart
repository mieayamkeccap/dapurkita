import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dapurkita/screens/admin/laporan_screen.dart';

// Data tiruan berbentuk sama dengan jawaban GET /api/dashboard/product-sales.
List<Map<String, dynamic>> dataUji() {
  List<Map<String, dynamic>> hari(int senin, int kamis) {
    return [
      {'tanggal': '2026-11-23', 'hari': 'Senin', 'jumlah': senin},
      {'tanggal': '2026-11-24', 'hari': 'Selasa', 'jumlah': 0},
      {'tanggal': '2026-11-25', 'hari': 'Rabu', 'jumlah': 0},
      {'tanggal': '2026-11-26', 'hari': 'Kamis', 'jumlah': kamis},
    ];
  }

  return [
    {
      'category_id': 2,
      'category_name': 'Nasi',
      'products': [
        {
          'product_id': 13,
          'product_name': 'ayam balado',
          'total': 5,
          'harian': hari(4, 1),
        },
        {
          'product_id': 15,
          'product_name': 'Ayam Geprek',
          'total': 0,
          'harian': hari(0, 0),
        },
      ],
    },
  ];
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Grafik menampilkan kategori dan produknya', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: KartuPenjualanProduk(dataUji()),
          ),
        ),
      ),
    );

    expect(find.text('Penjualan per Produk'), findsOneWidget);
    expect(find.text('Nasi'), findsOneWidget);
    expect(find.text('ayam balado'), findsOneWidget);
    expect(find.text('Ayam Geprek'), findsOneWidget);

    // Produk yang belum pernah terjual tetap muncul dengan angka nol
    expect(find.text('0 terjual'), findsOneWidget);
    expect(find.text('5 terjual'), findsOneWidget);
  });

  test('Batang nol tetap terlihat dan batang tertinggi penuh', () {
    expect(tinggiBatang(0, 4), 4);
    expect(tinggiBatang(4, 4), 100);
    expect(tinggiBatang(2, 4), 50);

    // Pembagi nol tidak boleh bikin error
    expect(tinggiBatang(0, 0), 4);
  });

  test('Singkatan hari dipakai di sumbu grafik', () {
    expect(singkatHari('Senin'), 'Sen');
    expect(singkatHari('Kamis'), 'Kam');
    expect(singkatHari('Minggu'), 'Min');
    expect(singkatHari('Entah'), 'Entah');
  });
}
