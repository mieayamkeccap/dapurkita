import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dapurkita/models/order_item_model.dart';
import 'package:dapurkita/screens/admin/kelola_pesanan_screen.dart';

void main() {
  setUpAll(() {
    // Supaya font tidak diunduh dari internet saat tes
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Daftar item pesanan menampilkan nama, jumlah, dan subtotal', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DaftarItemPesanan([
            OrderItemModel(
              productId: 13,
              productName: 'ayam balado',
              quantity: 1,
              price: 24000,
              subtotal: 24000,
            ),
            OrderItemModel(
              productId: 14,
              productName: 'ayam bakar',
              quantity: 2,
              price: 25000,
              subtotal: 50000,
            ),
          ]),
        ),
      ),
    );

    expect(find.text('ayam balado x1'), findsOneWidget);
    expect(find.text('Rp 24.000'), findsOneWidget);
    expect(find.text('ayam bakar x2'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsOneWidget);
  });

  testWidgets('Daftar item kosong memberi pesan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DaftarItemPesanan([])),
      ),
    );

    expect(find.text('Daftar item tidak tersedia.'), findsOneWidget);
  });
}
